/*
 *  Helpers for creating and querying pc2line debug data, which
 *  converts a bytecode program counter to a source line number.
 *
 *  The run-time pc2line data is bit-packed, and documented in:
 *
 *    doc/function-objects.txt
 */

#include "duk_internal.h"

/* Generate pc2line data for an instruction sequence, leaving a buffer on stack top. */
void duk_hobject_pc2line_pack(duk_hthread *thr, duk_compiler_instr *instrs, duk_uint_fast32_t length) {
	duk_context *ctx = (duk_context *) thr;
	duk_hbuffer_dynamic *h_buf;
	duk_bitencoder_ctx be_ctx_alloc;
	duk_bitencoder_ctx *be_ctx = &be_ctx_alloc;
	duk_uint32_t *hdr;
	duk_size_t new_size;
	duk_uint_fast32_t num_header_entries;
	duk_uint_fast32_t curr_offset;
	duk_int_fast32_t curr_line, next_line, diff_line;
	duk_uint_fast32_t curr_pc;
	duk_uint_fast32_t hdr_index;

	DUK_ASSERT(length <= DUK_COMPILER_MAX_BYTECODE_LENGTH);

	/* FIXME: add proper spare handling to dynamic buffer, to minimize
	 * reallocs; currently there is no spare at all.
	 */

	num_header_entries = (length + DUK_PC2LINE_SKIP - 1) / DUK_PC2LINE_SKIP;
	curr_offset = (duk_uint_fast32_t) (sizeof(duk_uint32_t) + num_header_entries * sizeof(duk_uint32_t) * 2);

	duk_push_dynamic_buffer(ctx, (size_t) curr_offset);
	h_buf = (duk_hbuffer_dynamic *) duk_get_hbuffer(ctx, -1);
	DUK_ASSERT(h_buf != NULL);
	DUK_ASSERT(DUK_HBUFFER_HAS_DYNAMIC(h_buf));

	hdr = (duk_uint32_t *) DUK_HBUFFER_DYNAMIC_GET_CURR_DATA_PTR(h_buf);
	DUK_ASSERT(hdr != NULL);
	hdr[0] = (duk_uint32_t) length;  /* valid pc range is [0, length[ */

	curr_pc = 0U;
	while (curr_pc < length) {
		new_size = (duk_size_t) (curr_offset + DUK_PC2LINE_MAX_DIFF_LENGTH);
		duk_hbuffer_resize(thr, h_buf, new_size, new_size);

		hdr = (duk_uint32_t *) DUK_HBUFFER_DYNAMIC_GET_CURR_DATA_PTR(h_buf);
		DUK_ASSERT(hdr != NULL);
		DUK_ASSERT(curr_pc < length);
		hdr_index = 1 + (curr_pc / DUK_PC2LINE_SKIP) * 2;
		curr_line = (duk_int_fast32_t) instrs[curr_pc].line;
		hdr[hdr_index + 0] = (duk_uint32_t) curr_line;
		hdr[hdr_index + 1] = (duk_uint32_t) curr_offset;

#if 0
		DUK_DDDPRINT("hdr[%d]: pc=%d line=%d offset=%d",
		             (int) (curr_pc / DUK_PC2LINE_SKIP),
		             (int) curr_pc,
		             (int) hdr[hdr_index + 0],
		             (int) hdr[hdr_index + 1]);
#endif

		DUK_MEMSET(be_ctx, 0, sizeof(*be_ctx));
		be_ctx->data = ((duk_uint8_t *) hdr) + curr_offset;
		be_ctx->length = (duk_size_t) DUK_PC2LINE_MAX_DIFF_LENGTH;

		for (;;) {
			curr_pc++;
			if ( ((curr_pc % DUK_PC2LINE_SKIP) == 0) ||  /* end of diff run */
			     (curr_pc >= length) ) {                 /* end of bytecode */
				break;
			}
			DUK_ASSERT(curr_pc < length);
			next_line = (duk_int32_t) instrs[curr_pc].line;
			diff_line = next_line - curr_line;

#if 0
			DUK_DDDPRINT("curr_line=%d, next_line=%d -> diff_line=%d",
			             (int) curr_line, (int) next_line, (int) diff_line);
#endif

			if (diff_line == 0) {
				/* 0 */
				duk_be_encode(be_ctx, 0, 1);
			} else if (diff_line >= 1 && diff_line <= 4) {
				/* 1 0 <2 bits> */
				duk_be_encode(be_ctx, (0x02 << 2) + (diff_line - 1), 4);
			} else if (diff_line >= -0x80 && diff_line <= 0x7f) {
				/* 1 1 0 <8 bits> */
				DUK_ASSERT(diff_line + 0x80 >= 0 && diff_line + 0x80 <= 0xff);
				duk_be_encode(be_ctx, (0x06 << 8) + (diff_line + 0x80), 11);
			} else {
				/* 1 1 1 <32 bits>
				 * Encode in two parts to avoid bitencode 24-bit limitation
				 */
				duk_be_encode(be_ctx, (0x07 << 16) + ((next_line >> 16) & 0xffffU), 19);
				duk_be_encode(be_ctx, next_line & 0xffffU, 16);
			}

			curr_line = next_line;
		}

		duk_be_finish(be_ctx);
		DUK_ASSERT(!be_ctx->truncated);

		/* be_ctx->offset == length of encoded bitstream */
		curr_offset += (duk_uint_fast32_t) be_ctx->offset;
	}

	/* compact */
	new_size = (duk_size_t) curr_offset;
	duk_hbuffer_resize(thr, h_buf, new_size, new_size);

	duk_to_fixed_buffer(ctx, -1);

	DUK_DDDPRINT("final pc2line data: pc_limit=%d, length=%d, %lf bits/opcode --> %!ixT",
	             (int) length, (int) new_size, (double) new_size * 8.0 / (double) length,
	             duk_get_tval(ctx, -1));
}

/* PC is unsigned.  If caller does PC arithmetic and gets a negative result,
 * it will map to a large PC which is out of bounds and causes a zero to be
 * returned.
 */
duk_uint_fast32_t duk_hobject_pc2line_query(duk_hbuffer_fixed *buf, duk_uint_fast32_t pc) {
	duk_bitdecoder_ctx bd_ctx_alloc;
	duk_bitdecoder_ctx *bd_ctx = &bd_ctx_alloc;
	duk_uint32_t *hdr;
	duk_uint_fast32_t start_offset;
	duk_uint_fast32_t pc_limit;
	duk_uint_fast32_t hdr_index;
	duk_uint_fast32_t pc_base;
	duk_uint_fast32_t n;
	duk_uint_fast32_t curr_line;

	DUK_ASSERT(buf != NULL);
	DUK_ASSERT(!DUK_HBUFFER_HAS_DYNAMIC(buf));

	hdr_index = pc / DUK_PC2LINE_SKIP;
	pc_base = hdr_index * DUK_PC2LINE_SKIP;
	n = pc - pc_base;

	if (DUK_HBUFFER_GET_SIZE(buf) <= sizeof(duk_uint32_t)) {
		DUK_DDPRINT("pc2line lookup failed: buffer is smaller than minimal header");
		goto error;
	}

	hdr = (duk_uint32_t *) DUK_HBUFFER_FIXED_GET_DATA_PTR(buf);
	pc_limit = hdr[0];
	if (pc >= pc_limit) {
		/* Note: pc is unsigned and cannot be negative */
		DUK_DDPRINT("pc2line lookup failed: pc out of bounds (pc=%d, limit=%d)",
		            (int) pc, (int) pc_limit);
		goto error;
	}

	curr_line = hdr[1 + hdr_index * 2];
	start_offset = hdr[1 + hdr_index * 2 + 1];
	if ((duk_size_t) start_offset > DUK_HBUFFER_GET_SIZE(buf)) {
		DUK_DDPRINT("pc2line lookup failed: start_offset out of bounds (start_offset=%d, buffer_size=%d)",
		            (int) start_offset, (int) DUK_HBUFFER_GET_SIZE(buf));
		goto error;
	}

	DUK_MEMSET(bd_ctx, 0, sizeof(*bd_ctx));
	bd_ctx->data = ((duk_uint8_t *) hdr) + start_offset;
	bd_ctx->length = (duk_size_t) (DUK_HBUFFER_GET_SIZE(buf) - start_offset);

#if 0
	DUK_DDDPRINT("pc2line lookup: pc=%d -> hdr_index=%d, pc_base=%d, n=%d, start_offset=%d",
	             (int) pc, (int) hdr_index, (int) pc_base, (int) n, (int) start_offset);
#endif

	while (n > 0) {
#if 0
		DUK_DDDPRINT("lookup: n=%d, curr_line=%d", (int) n, (int) curr_line);
#endif

		if (duk_bd_decode_flag(bd_ctx)) {
			if (duk_bd_decode_flag(bd_ctx)) {
				if (duk_bd_decode_flag(bd_ctx)) {
					/* 1 1 1 <32 bits> */
					duk_uint_fast32_t t;
					t = duk_bd_decode(bd_ctx, 16);  /* workaround: max nbits = 24 now */
					t = (t << 16) + duk_bd_decode(bd_ctx, 16);
					curr_line = t;
				} else {
					/* 1 1 0 <8 bits> */
					duk_uint_fast32_t t;
					t = duk_bd_decode(bd_ctx, 8);
					curr_line = curr_line + t - 0x80;
				}
			} else {
				/* 1 0 <2 bits> */
				duk_uint_fast32_t t;
				t = duk_bd_decode(bd_ctx, 2);
				curr_line = curr_line + t + 1;
			}
		} else {
			/* 0: no change */
		}

		n--;
	}

	DUK_DDDPRINT("pc2line lookup result: pc %d -> line %d", (int) pc, (int) curr_line);
	return curr_line;

 error:
	DUK_DPRINT("pc2line conversion failed for pc=%d", (int) pc);
	return 0;
}

