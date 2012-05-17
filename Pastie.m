#import "Pastie.h"

#define kBoundaryString @"__10a7432849cf4656a59f0193a8e38cb5"

@implementation Pastie

+ (void)pasteWithContent:(NSString *)content
                 private:(BOOL)private
              completion:(void (^)(BOOL success, NSURL *url))completionBlock {
    NSString *formFormat = @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n";
    NSMutableData *formData = [NSMutableData data];
    NSDictionary *formInfo;
    for(NSString *name in [(formInfo = @{
        @"paste[body]" : content,
        @"paste[authorization]" : @"burger",
        @"paste[restricted]" : private ? @"1" : @"0",
        @"paste[parser_id]" : @"6"
                           }) allKeys]) {
        [formData appendData:[[NSString stringWithFormat:formFormat, kBoundaryString, name, [formInfo objectForKey:name]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [formData appendData:[[NSString stringWithFormat:@"--%@--\r\n", kBoundaryString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://pastie.org/pastes"]];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kBoundaryString] forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:formData];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [queue release];
        if(error)
            completionBlock(NO, nil);
        else {
            completionBlock(YES, [response URL]);
        }
    }];
}

@end