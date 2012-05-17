#import <Foundation/Foundation.h>

@interface Pastie : NSObject

+ (void)pasteWithContent:(NSString *)content private:(BOOL)private completion:(void (^)(BOOL success, NSURL *url))completionBlock;

@end