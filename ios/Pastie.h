#import <Foundation/Foundation.h>

@interface Pastie : NSObject {
	int x;
}

+(void)pasteWithContent:(NSString *)content private:(BOOL)priv completion:(void (^)(BOOL success, NSURL *url))completionBlock;

@end

