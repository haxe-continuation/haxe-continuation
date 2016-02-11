all release.zip: \
haxelib.json \
haxelib.xml \
LICENSE \
$(wildcard com/dongxiguo/continuation/*.hx com/dongxiguo/continuation/*/*.hx)

haxelib.json: haxelib.xml
	haxelib convertxml haxelib.xml

release.zip:
	 zip -u $@ $^


clean:
	$(RM) -r bin release.zip haxedoc.xml haxelib.json

test: \
bin/TestContinuation.n bin/TestContinuation.swf bin/TestContinuation.js bin/TestContinuation_cpp \
bin/TestForkMeta_java bin/TestForkMeta_cs bin/TestForkMeta.swf bin/TestForkMeta.js \
bin/Sample.swf bin/Sample.js bin/Sample_cs bin/Sample_java bin/Sample_cpp \
bin/TestNode.js
	neko bin/TestContinuation.n
	node bin/TestContinuation.js
	bin/TestContinuation_cpp/TestContinuation
	java -jar bin/TestForkMeta_java/TestForkMeta.jar
	mono bin/TestForkMeta_cs/bin/TestForkMeta.exe
	node bin/TestForkMeta.js
	node bin/Sample.js
	mono bin/Sample_cs/bin/Sample.exe
	java -jar bin/Sample_java/Sample.jar 
	bin/Sample_cpp/Sample
	node bin/TestNode.js



bin/TestForkMeta_cs: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkMeta.hx \
| bin
	haxe -cs $@ -main tests.TestForkMeta

bin/TestForkMeta_java: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkMeta.hx \
| bin
	haxe -java $@ -main tests.TestForkMeta

bin/TestForkMeta.swf: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkMeta.hx \
| bin
	haxe -swf $@ -main tests.TestForkMeta

bin/TestForkMeta.js: \
com/dongxiguo/continuation/Continuation.hx \
com/dongxiguo/continuation/utils/ForkJoin.hx \
tests/TestForkMeta.hx \
| bin
	haxe -js $@ -main tests.TestForkMeta

bin/TestContinuation_cpp: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -cpp $@ -main tests.TestContinuation

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

bin/Sample_cpp: \
com/dongxiguo/continuation/Continuation.hx \
tests/Sample.hx \
| bin
	$(RM) -r $@
	haxe -cpp $@ -main tests.Sample

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

dox: cross-platform.xml
	haxelib run dox \
	--input-path $< \
	--output-path $@ \
	--include '^com(\.dongxiguo(\.continuation(\..*)?)?)?$$'
	touch $@

cross-platform.xml: \
$(wildcard com/dongxiguo/continuation/*.hx com/dongxiguo/continuation/*/*.hx)
	haxe -D doc-gen -xml $@ $^

bin:
	mkdir $@

.PHONY: all clean test
