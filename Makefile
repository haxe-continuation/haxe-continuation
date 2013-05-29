all release.zip: \
haxelib.json \
haxelib.xml \
haxedoc.xml \
LICENSE \
$(wildcard com/dongxiguo/continuation/*.hx com/dongxiguo/continuation/*/*.hx)

haxelib.json: haxelib.xml
	haxelib convertxml haxelib.xml

release.zip:
	 zip -u $@ $^


clean:
	$(RM) -r bin release.zip haxedoc.xml haxelib.json

test: \
bin/TestContinuation.n bin/TestContinuation.swf bin/TestContinuation.js \
bin/TestForkJoin_java bin/TestForkJoin_cs bin/TestForkJoin.swf bin/TestForkJoin.js \
bin/Sample.swf bin/Sample.js bin/Sample_cs bin/Sample_java \
bin/TestNode.js

bin/TestForkJoin_cs: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkJoin.hx \
| bin
	haxe -cs $@ -main tests.TestForkJoin

bin/TestForkJoin_java: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkJoin.hx \
| bin
	haxe -java $@ -main tests.TestForkJoin

bin/TestForkJoin.swf: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkJoin.hx \
| bin
	haxe -swf $@ -main tests.TestForkJoin

bin/TestForkJoin.js: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkJoin.hx \
| bin
	haxe -js $@ -main tests.TestForkJoin

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


haxedoc.xml: \
$(wildcard com/dongxiguo/continuation/*.hx com/dongxiguo/continuation/*/*.hx)
	haxe -xml $@ $^

bin:
	mkdir $@

.PHONY: all clean test
