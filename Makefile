all: release.zip

release.zip: \
haxelib.xml \
haxedoc.xml \
LICENSE \
com/dongxiguo/continuation/Continuation.hx
	 zip -u $@ $^

clean:
	$(RM) -r bin release.zip haxedoc.xml

test: \
bin/TestContinuation.n bin/TestContinuation.swf bin/TestContinuation.js \
bin/Sample.swf bin/Sample.js bin/Sample_cs bin/Sample_java \
bin/TestNode.js

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

bin/TestNode.js: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestNode.hx \
| bin
	haxe -js $@ -main tests.TestNode -lib nodejs

bin/Sample_java: \
com/dongxiguo/continuation/Continuation.hx \
tests/Sample.hx \
| bin
	$(RM) -r $@
	haxe -java $@ -main tests.Sample

bin/Sample_cs: \
com/dongxiguo/continuation/Continuation.hx \
tests/Sample.hx \
| bin
	$(RM) -r $@
	haxe -cs $@ -main tests.Sample

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
	haxe -xml $@ $<

bin:
	mkdir $@

.PHONY: all clean test
