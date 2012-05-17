all: clean LongTweetIsLong.dylib

LongTweetIsLong.dylib:
	clang -dynamiclib -o LongTweetIsLong.dylib Hook.m Pastie.m -framework AppKit -framework Foundation

launch: LongTweetIsLong.dylib
	sh -c "DYLD_INSERT_LIBRARIES='$(PWD)/LongTweetIsLong.dylib' /Applications/Twitter.app/Contents/MacOS/Twitter"

clean:
	rm -f LongTweetIsLong.dylib