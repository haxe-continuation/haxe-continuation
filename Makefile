all: release.zip

release.zip: \
haxelib.xml \
haxedoc.xml \
LICENSE \
com/dongxiguo/continuation/Continuation.hx
	 zip -u $@ $^

clean:
	$(RM) -r bin release.zip

test: \
bin/TestContinuation.n bin/TestContinuation.swf bin/TestContinuation.js \
bin/Sample.swf bin/Sample.js

bin/TestContinuation.n: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -neko $@ -main tests.TestContinuation

bin/TestContinuation.swf: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -swf $@ -main tests.TestContinuation

bin/TestContinuation.js: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -js $@ -main tests.TestContinuation

bin/Sample.swf: \
com/dongxiguo/continuation/Continuation.hx \
tests/Sample.hx \
| bin
	haxe -swf $@ -main tests.Sample

bin/Sample.js: \
com/dongxiguo/continuation/Continuation.hx \
tests/Sample.hx \
| bin
	haxe -js $@ -main tests.Sample

haxedoc.xml: com/dongxiguo/continuation/Continuation.hx
	haxe -xml $@ $< --dead-code-elimination

bin:
	mkdir $@

.PHONY: all clean test
