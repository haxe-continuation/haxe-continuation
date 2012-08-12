all: release.zip

release.zip: haxelib.xml LICENSE com/dongxiguo/continuation/Continuation.hx
	 zip -u $@ $^

clean:
	$(RM) -r bin release.zip

test: bin/TestContinuation.n bin/TestContinuation.swf bin/TestContinuation.js

bin/TestContinuation.n: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -cp . -neko $@ -main tests.TestContinuation --dead-code-elimination

bin/TestContinuation.swf: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -cp . -swf $@ -main tests.TestContinuation --dead-code-elimination

bin/TestContinuation.js: \
com/dongxiguo/continuation/Continuation.hx \
tests/TestContinuation.hx \
| bin
	haxe -cp . -js $@ -main tests.TestContinuation --dead-code-elimination

bin:
	mkdir $@

.PHONY: all clean test
