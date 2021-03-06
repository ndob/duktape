#
#  Makefile for the Duktape development repo
#
#  This Makefile is intended for ONLY internal Duktape development
#  on Linux (or other UNIX-like operating systems), and covers:
#
#    - building the Duktape source distributable
#    - running test cases
#    - building the duktape.org website
#
#  The source distributable has more platform neutral example Makefiles
#  for end user projects (though an end user should really just use their
#  own Makefile).
#
#  YOU SHOULD NOT COMPILE DUKTAPE WITH THIS MAKEFILE IN YOUR PROJECT!
#
#  Duktape command line tools are built by first creating a source dist
#  directory, and then using the sources from the dist directory for
#  compilation.  This is as close as possible to the sources used by an
#  end user, at the risk of accidentally polluting the dist directory.
#
#  When creating actual distributables, always clean first.
#

# Scrape version from the public header; convert from e.g. 10203 -> '1.2.3'
DUK_VERSION=$(shell cat src/duktape.h | grep define | grep DUK_VERSION | tr -s ' ' ' ' | cut -d ' ' -f 3 | tr -d 'L')
DUK_MAJOR=$(shell echo "$(DUK_VERSION) / 10000" | bc)
DUK_MINOR=$(shell echo "$(DUK_VERSION) % 10000 / 100" | bc)
DUK_PATCH=$(shell echo "$(DUK_VERSION) % 100" | bc)
VERSION=$(DUK_MAJOR).$(DUK_MINOR).$(DUK_PATCH)

DISTSRCSEP = dist/src-separate
DISTSRCCOM = dist/src
DISTCMD = dist/examples/cmdline

DUKTAPE_SOURCES_COMBINED =	\
	$(DISTSRCCOM)/duktape.c

DUKTAPE_SOURCES_SEPARATE =	\
	$(DISTSRCSEP)/duk_util_hashbytes.c \
	$(DISTSRCSEP)/duk_util_hashprime.c \
	$(DISTSRCSEP)/duk_util_bitdecoder.c \
	$(DISTSRCSEP)/duk_util_bitencoder.c \
	$(DISTSRCSEP)/duk_util_tinyrandom.c \
	$(DISTSRCSEP)/duk_util_misc.c \
	$(DISTSRCSEP)/duk_alloc_default.c \
	$(DISTSRCSEP)/duk_debug_macros.c \
	$(DISTSRCSEP)/duk_debug_vsnprintf.c \
	$(DISTSRCSEP)/duk_debug_heap.c \
	$(DISTSRCSEP)/duk_debug_hobject.c \
	$(DISTSRCSEP)/duk_debug_fixedbuffer.c \
	$(DISTSRCSEP)/duk_error_macros.c \
	$(DISTSRCSEP)/duk_error_longjmp.c \
	$(DISTSRCSEP)/duk_error_throw.c \
	$(DISTSRCSEP)/duk_error_fatal.c \
	$(DISTSRCSEP)/duk_error_augment.c \
	$(DISTSRCSEP)/duk_error_misc.c \
	$(DISTSRCSEP)/duk_heap_misc.c \
	$(DISTSRCSEP)/duk_heap_memory.c \
	$(DISTSRCSEP)/duk_heap_alloc.c \
	$(DISTSRCSEP)/duk_heap_refcount.c \
	$(DISTSRCSEP)/duk_heap_markandsweep.c \
	$(DISTSRCSEP)/duk_heap_hashstring.c \
	$(DISTSRCSEP)/duk_heap_stringtable.c \
	$(DISTSRCSEP)/duk_heap_stringcache.c \
	$(DISTSRCSEP)/duk_hthread_misc.c \
	$(DISTSRCSEP)/duk_hthread_alloc.c \
	$(DISTSRCSEP)/duk_hthread_builtins.c \
	$(DISTSRCSEP)/duk_hthread_stacks.c \
	$(DISTSRCSEP)/duk_hobject_alloc.c \
	$(DISTSRCSEP)/duk_hobject_class.c \
	$(DISTSRCSEP)/duk_hobject_enum.c \
	$(DISTSRCSEP)/duk_hobject_props.c \
	$(DISTSRCSEP)/duk_hobject_finalizer.c \
	$(DISTSRCSEP)/duk_hobject_pc2line.c \
	$(DISTSRCSEP)/duk_hobject_misc.c \
	$(DISTSRCSEP)/duk_hbuffer_alloc.c \
	$(DISTSRCSEP)/duk_hbuffer_ops.c \
	$(DISTSRCSEP)/duk_unicode_tables.c \
	$(DISTSRCSEP)/duk_unicode_support.c \
	$(DISTSRCSEP)/duk_builtins.c \
	$(DISTSRCSEP)/duk_js_ops.c \
	$(DISTSRCSEP)/duk_js_var.c \
	$(DISTSRCSEP)/duk_numconv.c \
	$(DISTSRCSEP)/duk_api_call.c \
	$(DISTSRCSEP)/duk_api_compile.c \
	$(DISTSRCSEP)/duk_api_codec.c \
	$(DISTSRCSEP)/duk_api_memory.c \
	$(DISTSRCSEP)/duk_api_string.c \
	$(DISTSRCSEP)/duk_api_object.c \
	$(DISTSRCSEP)/duk_api_thread.c \
	$(DISTSRCSEP)/duk_api_buffer.c \
	$(DISTSRCSEP)/duk_api_var.c \
	$(DISTSRCSEP)/duk_api.c \
	$(DISTSRCSEP)/duk_lexer.c \
	$(DISTSRCSEP)/duk_js_call.c \
	$(DISTSRCSEP)/duk_js_executor.c \
	$(DISTSRCSEP)/duk_js_compiler.c \
	$(DISTSRCSEP)/duk_regexp_compiler.c \
	$(DISTSRCSEP)/duk_regexp_executor.c \
	$(DISTSRCSEP)/duk_bi_duk.c \
	$(DISTSRCSEP)/duk_bi_thread.c \
	$(DISTSRCSEP)/duk_bi_thrower.c \
	$(DISTSRCSEP)/duk_bi_array.c \
	$(DISTSRCSEP)/duk_bi_boolean.c \
	$(DISTSRCSEP)/duk_bi_date.c \
	$(DISTSRCSEP)/duk_bi_error.c \
	$(DISTSRCSEP)/duk_bi_function.c \
	$(DISTSRCSEP)/duk_bi_global.c \
	$(DISTSRCSEP)/duk_bi_json.c \
	$(DISTSRCSEP)/duk_bi_math.c \
	$(DISTSRCSEP)/duk_bi_number.c \
	$(DISTSRCSEP)/duk_bi_object.c \
	$(DISTSRCSEP)/duk_bi_regexp.c \
	$(DISTSRCSEP)/duk_bi_string.c \
	$(DISTSRCSEP)/duk_bi_buffer.c \
	$(DISTSRCSEP)/duk_bi_pointer.c \
	$(DISTSRCSEP)/duk_selftest.c

# Use combined sources for testing etc.
DUKTAPE_SOURCES = $(DUKTAPE_SOURCES_COMBINED)
#DUKTAPE_SOURCES = $(DUKTAPE_SOURCES_SEPARATE)

# Duktape command line tool - example of a main() program, used
# for unit testing
DUKTAPE_CMDLINE_SOURCES = \
	$(DISTCMD)/duk_cmdline.c

# Compiler setup for Linux
CC	= gcc
CCOPTS_SHARED = -pedantic -ansi -std=c99 -Wall -fstrict-aliasing
CCOPTS_SHARED += -Wextra  # very picky but catches e.g. signed/unsigned comparisons
CCOPTS_SHARED += -I./dist/src
#CCOPTS_SHARED += -I./dist/src-separate
#CCOPTS_SHARED += -m32                             # force 32-bit compilation on a 64-bit host
#CCOPTS_SHARED += -DDUK_OPT_NO_REFERENCE_COUNTING
#CCOPTS_SHARED += -DDUK_OPT_NO_MARK_AND_SWEEP
#CCOPTS_SHARED += -DDUK_OPT_NO_VOLUNTARY_GC
CCOPTS_SHARED += -DDUK_OPT_SEGFAULT_ON_PANIC       # segfault on panic allows valgrind to show stack trace on panic
CCOPTS_SHARED += -DDUK_OPT_DPRINT_COLORS
#CCOPTS_SHARED += -DDUK_OPT_NO_FILE_IO
#CCOPTS_SHARED += '-DDUK_OPT_PANIC_HANDLER(code,msg)={printf("*** %d:%s\n",(code),(msg));abort();}'
CCOPTS_SHARED += -DDUK_OPT_SELF_TESTS
#CCOPTS_SHARED += -DDUK_OPT_NO_TRACEBACKS
#CCOPTS_SHARED += -DDUK_OPT_NO_PC2LINE
#CCOPTS_SHARED += -DDUK_OPT_NO_VERBOSE_ERRORS
#CCOPTS_SHARED += -DDUK_OPT_GC_TORTURE
#CCOPTS_SHARED += -DDUK_OPT_NO_MS_RESIZE_STRINGTABLE
CCOPTS_SHARED += -DDUK_OPT_DEBUG_BUFSIZE=512
#CCOPTS_SHARED += -DDUK_OPT_NO_REGEXP_SUPPORT
#CCOPTS_SHARED += -DDUK_OPT_NO_OCTAL_SUPPORT
#CCOPTS_SHARED += -DDUK_OPT_NO_SOURCE_NONBMP
#CCOPTS_SHARED += -DDUK_OPT_STRICT_UTF8_SOURCE
#CCOPTS_SHARED += -DDUK_OPT_NO_BROWSER_LIKE
#CCOPTS_SHARED += -DDUK_OPT_NO_SECTION_B
#CCOPTS_SHARED += -DDUK_OPT_NO_FUNC_STMT
#CCOPTS_SHARED += -DDUK_OPT_NO_INTERRUPT_COUNTER
#CCOPTS_SHARED += -DDUK_OPT_NO_JSONX
#CCOPTS_SHARED += -DDUK_OPT_NO_JSONC
#CCOPTS_SHARED += -DDUK_CMDLINE_BAREBONES
CCOPTS_NONDEBUG = $(CCOPTS_SHARED) -Os -fomit-frame-pointer
CCOPTS_NONDEBUG += -g -ggdb
#CCOPTS_NONDEBUG += -DDUK_OPT_ASSERTIONS
CCOPTS_DEBUG = $(CCOPTS_SHARED) -O0 -g -ggdb
CCOPTS_DEBUG += -DDUK_OPT_DEBUG
CCOPTS_DEBUG += -DDUK_OPT_ASSERTIONS
CCLIBS	= -lm
CCLIBS += -lreadline
CCLIBS += -lncurses  # on some systems -lreadline also requires -lncurses (e.g. RHEL)

# Compile 'duk' only by default
.PHONY:	all
all:	checksetup duk

.PHONY: checksetup
checksetup:
	@util/check_setup.sh

.PHONY:	clean
clean:
	-@rm -rf dist/
	-@rm -rf site/
	-@rm -f duk dukd
	-@rm -f libduktape*.so*
	-@rm -f doc/*.html
	-@rm -f src/*.pyc
	-@rm -rf duktape-*  # covers various files and dirs
	-@rm -rf massif.out.* ms_print.tmp.*
	-@rm -rf /tmp/duktape-regfuzz/
	-@rm -f /tmp/duk-test.log /tmp/duk-vgtest.log /tmp/duk-api-test.log
	-@rm -f /tmp/duk-test262.log /tmp/duk-test262-filtered.log
	-@rm -f /tmp/duk-vgtest262.log /tmp/duk-vgtest262-filtered.log
	-@rm -f /tmp/duk-emcc-test* /tmp/duk-emcc-vgtest*
	-@rm -f a.out

cleanall:
	# Don't delete these in 'clean' to avoid re-downloading them over and over
	-@rm -f regfuzz-*.tar.gz
	-@rm -rf UglifyJS
	-@rm -rf underscore
	-@rm -rf test262-d067d2f0ca30
	-@rm -f d067d2f0ca30.tar.bz2
	-@rm -rf emscripten
	-@rm -rf JS-Interpreter

libduktape.so.1.0.0: dist
	-rm -f $(subst .so.1.0.0,.so.1,$@) $(subst .so.1.0.0,.so.1.0.0,$@) $(subst .so.1.0.0,.so,$@)
	$(CC) -o $@ -shared -Wl,-soname,$(subst .so.1.0.0,.so.1,$@) -fPIC $(CCOPTS_NONDEBUG) $(DUKTAPE_SOURCES) $(CCLIBS)
	ln -s $@ $(subst .so.1.0.0,.so.1,$@)
	ln -s $@ $(subst .so.1.0.0,.so,$@)

libduktaped.so.1.0.0: dist
	-rm -f $(subst .so.1.0.0,.so.1,$@) $(subst .so.1.0.0,.so.1.0.0,$@) $(subst .so.1.0.0,.so,$@)
	$(CC) -o $@ -shared -Wl,-soname,$(subst .so.1.0.0,.so.1,$@) -fPIC $(CCOPTS_DEBUG) $(DUKTAPE_SOURCES) $(CCLIBS)
	ln -s $@ $(subst .so.1.0.0,.so.1,$@)
	ln -s $@ $(subst .so.1.0.0,.so,$@)

duk: dist
	$(CC) -o $@ $(CCOPTS_NONDEBUG) $(DUKTAPE_SOURCES) $(DUKTAPE_CMDLINE_SOURCES) $(CCLIBS)

dukd: dist
	$(CC) -o $@ $(CCOPTS_DEBUG) $(DUKTAPE_SOURCES) $(DUKTAPE_CMDLINE_SOURCES) $(CCLIBS)

.PHONY: duksizes
duksizes: duk
	python src/genexesizereport.py duk > /tmp/duk_sizes.html

.PHONY: test
test: qecmatest apitest regfuzztest underscoretest emscriptentest test262test

.PHONY:	ecmatest
ecmatest: npminst duk
	@echo "### ecmatest"
	node runtests/runtests.js --run-duk --cmd-duk=$(shell pwd)/duk --run-nodejs --run-rhino --num-threads 8 --log-file=/tmp/duk-test.log ecmascript-testcases/

.PHONY:	ecmatestd
ecmatestd: npminst dukd
	@echo "### ecmatestd"
	node runtests/runtests.js --run-duk --cmd-duk=$(shell pwd)/dukd --run-nodejs --run-rhino --num-threads 8 --log-file=/tmp/duk-test.log ecmascript-testcases/

.PHONY:	qecmatest
qecmatest: npminst duk
	@echo "### qecmatest"
	node runtests/runtests.js --run-duk --cmd-duk=$(shell pwd)/duk --num-threads 16 --log-file=/tmp/duk-test.log ecmascript-testcases/

.PHONY:	qecmatestd
qecmatestd: npminst dukd
	@echo "### qecmatestd"
	node runtests/runtests.js --run-duk --cmd-duk=$(shell pwd)/dukd --num-threads 16 --log-file=/tmp/duk-test.log ecmascript-testcases/

.PHONY:	vgecmatest
vgecmatest: npminst duk
	@echo "### vgecmatest"
	node runtests/runtests.js --run-duk --cmd-duk=$(shell pwd)/duk --num-threads 1 --test-sleep 30  --log-file=/tmp/duk-vgtest.log --valgrind --verbose ecmascript-testcases/

.PHONY:	apitest
apitest: npminst libduktape.so.1.0.0
	@echo "### apitest"
	node runtests/runtests.js --num-threads 1 --log-file=/tmp/duk-api-test.log api-testcases/

.PHONY: vgapitest
vgapitest: npminst libduktape.so.1.0.0
	@echo "### vgapitest"
	node runtests/runtests.js --valgrind --num-threads 1 --log-file=/tmp/duk-api-test.log api-testcases/

# FIXME: torturetest; torture + valgrind

regfuzz-0.1.tar.gz:
	# SHA1: 774be8e3dda75d095225ba699ac59969d92ac970
	wget https://regfuzz.googlecode.com/files/regfuzz-0.1.tar.gz

.PHONY:	regfuzztest
regfuzztest: regfuzz-0.1.tar.gz duk
	@echo "### regfuzztest"
	# Spidermonkey test is pretty close, just lacks 'arguments'
	# Should run with assertions enabled in 'duk'
	rm -rf /tmp/duktape-regfuzz; mkdir -p /tmp/duktape-regfuzz
	cp regfuzz-0.1.tar.gz duk /tmp/duktape-regfuzz
	tar -C /tmp/duktape-regfuzz -x -v -z -f regfuzz-0.1.tar.gz
	echo "arguments = [ 0xdeadbeef ];" > /tmp/duktape-regfuzz/regfuzz-test.js
	cat /tmp/duktape-regfuzz/regfuzz-0.1/examples/spidermonkey/regexfuzz.js >> /tmp/duktape-regfuzz/regfuzz-test.js
	cd /tmp/duktape-regfuzz; ./duk regfuzz-test.js

.PHONY: vgregfuzztest
vgregfuzztest: regfuzz-0.1.tar.gz duk
	@echo "### vgregfuzztest"
	rm -rf /tmp/duktape-regfuzz; mkdir -p /tmp/duktape-regfuzz
	cp regfuzz-0.1.tar.gz duk /tmp/duktape-regfuzz
	tar -C /tmp/duktape-regfuzz -x -v -z -f regfuzz-0.1.tar.gz
	echo "arguments = [ 0xdeadbeef ];" > /tmp/duktape-regfuzz/regfuzz-test.js
	cat /tmp/duktape-regfuzz/regfuzz-0.1/examples/spidermonkey/regexfuzz.js >> /tmp/duktape-regfuzz/regfuzz-test.js
	cd /tmp/duktape-regfuzz; valgrind ./duk regfuzz-test.js

underscore:
	git clone https://github.com/jashkenas/underscore.git

.PHONY: underscoretest
underscoretest:	underscore duk
	@echo "### underscoretest"
	@echo "Run underscore tests with underscore-test-shim.js"
	-util/underscore_test.sh ./duk underscore/test/arrays.js
	-util/underscore_test.sh ./duk underscore/test/chaining.js
	-util/underscore_test.sh ./duk underscore/test/collections.js
	-util/underscore_test.sh ./duk underscore/test/functions.js
	-util/underscore_test.sh ./duk underscore/test/objects.js
	# speed test disabled, requires JSLitmus
	#-util/underscore_test.sh ./duk underscore/test/speed.js
	-util/underscore_test.sh ./duk underscore/test/utility.js

.PHONY: vgunderscoretest
vgunderscoretest: underscore duk
	@echo "### vgunderscoretest"
	@echo "Run underscore tests with underscore-test-shim.js, under valgrind"
	-util/underscore_test.sh valgrind ./duk underscore/test/arrays.js
	-util/underscore_test.sh valgrind ./duk underscore/test/chaining.js
	-util/underscore_test.sh valgrind ./duk underscore/test/collections.js
	-util/underscore_test.sh valgrind ./duk underscore/test/functions.js
	-util/underscore_test.sh valgrind ./duk underscore/test/objects.js
	# speed test disabled, requires JSLitmus
	#-util/underscore_test.sh valgrind ./duk underscore/test/speed.js
	-util/underscore_test.sh valgrind ./duk underscore/test/utility.js

d067d2f0ca30.tar.bz2:
	wget http://hg.ecmascript.org/tests/test262/archive/d067d2f0ca30.tar.bz2

test262-d067d2f0ca30: d067d2f0ca30.tar.bz2
	tar xvfj d067d2f0ca30.tar.bz2

.PHONY: test262test
test262test: test262-d067d2f0ca30 duk
	@echo "### test262test"
	# http://wiki.ecmascript.org/doku.php?id=test262:command
	-rm -f /tmp/duk-test262.log /tmp/duk-test262-filtered.log
	cd test262-d067d2f0ca30; python tools/packaging/test262.py --command "../duk {{path}}" --summary >/tmp/duk-test262.log
	cat /tmp/duk-test262.log | python util/filter_test262_log.py doc/test262-known-issues.json > /tmp/duk-test262-filtered.log
	cat /tmp/duk-test262-filtered.log

.PHONY: vgtest262test
vgtest262test: test262-d067d2f0ca30 duk
	@echo "### vgtest262test"
	-@rm -f /tmp/duk-vgtest262.log /tmp/duk-vgtest262-filtered.log
	cd test262-d067d2f0ca30; python tools/packaging/test262.py --command "valgrind ../duk {{path}}" --summary >/tmp/duk-vgtest262.log
	cat /tmp/duk-vgtest262.log | python util/filter_test262_log.py doc/test262-known-issues.json > /tmp/duk-vgtest262-filtered.log
	cat /tmp/duk-vgtest262-filtered.log
	
# Unholy helper to write out a testcase, the unholiness is that it reads
# command line arguments and complains about missing targets etc:
# http://stackoverflow.com/questions/6273608/how-to-pass-argument-to-makefile-from-command-line
.PHONY: test262cat
test262cat: test262-d067d2f0ca30
	@echo "NOTE: this Makefile target will print a 'No rule...' error, ignore it" >&2
	@cd test262-d067d2f0ca30; python tools/packaging/test262.py --command "../duk {{path}}" --cat $(filter-out $@,$(MAKECMDGOALS))

emscripten:
	git clone https://github.com/kripken/emscripten.git
	cd emscripten; ./emconfigure

# Reducing the TOTAL_MEMORY and TOTAL_STACK values is useful if you run
# Duktape cmdline with resource limits (i.e. "duk -r test.js").
#EMCCOPTS=-s USE_TYPED_ARRAYS=0 -s TOTAL_MEMORY=2097152 -s TOTAL_STACK=524288
EMCCOPTS=-s USE_TYPED_ARRAYS=0

PHONY: emscriptentest
emscriptentest: emscripten duk
	@echo "### emscriptentest"
	-@rm -f /tmp/duk-emcc-test*
	@echo "NOTE: this emscripten test is incomplete (compiles hello_world.cpp and tries to run it, no checks yet)"
	emscripten/emcc $(EMCCOPTS) emscripten/tests/hello_world.cpp -o /tmp/duk-emcc-test.js
	cat /tmp/duk-emcc-test.js | python util/fix_emscripten.py > /tmp/duk-emcc-test-fixed.js
	@ls -l /tmp/duk-emcc-test*
	./duk /tmp/duk-emcc-test-fixed.js

.PHONY: vgemscriptentest
vgemscriptentest: emscripten duk
	@echo "### vgemscriptentest"
	-@rm -f /tmp/duk-emcc-vgtest*
	@echo "NOTE: this emscripten test is incomplete (compiles hello_world.cpp and tries to run it, no checks yet)"
	emscripten/emcc $(EMCCOPTS) emscripten/tests/hello_world.cpp -o /tmp/duk-emcc-vgtest.js
	cat /tmp/duk-emcc-vgtest.js | python util/fix_emscripten.py > /tmp/duk-emcc-vgtest-fixed.js
	@ls -l /tmp/duk-emcc-vgtest*
	valgrind ./duk /tmp/duk-emcc-vgtest-fixed.js

JS-Interpreter:
	git clone https://github.com/NeilFraser/JS-Interpreter.git

.PHONY: jsinterpretertest
jsinterpretertest: JS-Interpreter duk
	@echo "### jsinterpretertest"
	-@rm -f /tmp/duk-jsint-test*
	echo "window = {};" > /tmp/duk-jsint-test.js
	cat JS-Interpreter/acorn.js JS-Interpreter/interpreter.js >> /tmp/duk-jsint-test.js
	echo "var interp = new Interpreter('1+2+3'); interp.run(); print(interp.value);" >> /tmp/duk-jsint-test.js
	./duk /tmp/duk-jsint-test.js

.PHONY: vgjsinterpretertest
vgjsinterpretertest: JS-Interpreter duk
	@echo "### vgjsinterpretertest"
	-@rm -f /tmp/duk-jsint-vgtest*
	echo "window = {};" > /tmp/duk-jsint-vgtest.js
	cat JS-Interpreter/acorn.js JS-Interpreter/interpreter.js >> /tmp/duk-jsint-vgtest.js
	echo "var interp = new Interpreter('1+2+3'); interp.run(); print(interp.value);" >> /tmp/duk-jsint-vgtest.js
	valgrind ./duk /tmp/duk-jsint-vgtest.js

UglifyJS:
	git clone https://github.com/mishoo/UglifyJS.git

.PHONY:	npminst
npminst:	runtests/node_modules

runtests/node_modules:
	echo "Installing required NodeJS modules for runtests"
	cd runtests; npm install

.PHONY:	doc
doc:	$(patsubst %.txt,%.html,$(wildcard doc/*.txt))

doc/%.html: doc/%.txt
	rst2html $< $@

# Source distributable for end users
dist:	UglifyJS
	sh util/make_dist.sh

.PHONY:	dist-src
dist-src:	dist
	rm -rf duktape-$(VERSION)
	rm -rf duktape-$(VERSION).tar*
	mkdir duktape-$(VERSION)
	cp -r dist/* duktape-$(VERSION)/
	tar cvfj duktape-$(VERSION).tar.bz2 duktape-$(VERSION)/
	tar cvf duktape-$(VERSION).tar duktape-$(VERSION)/
	xz -z -e -9 duktape-$(VERSION).tar
	mkisofs -o duktape-$(VERSION).iso duktape-$(VERSION).tar.bz2

# Website
site:
	rm -rf site
	mkdir site
	cd website/; python buildsite.py ../site/
	-@rm -rf /tmp/site/
	cp -r site /tmp/  # FIXME

.PHONY:	dist-site
dist-site:	site
	rm -rf duktape-site-$(VERSION)
	rm -rf duktape-site-$(VERSION).tar*
	mkdir duktape-site-$(VERSION)
	cp -r site/* duktape-site-$(VERSION)/
	tar cvf duktape-site-$(VERSION).tar duktape-site-$(VERSION)/
	xz -z -e -9 duktape-site-$(VERSION).tar

