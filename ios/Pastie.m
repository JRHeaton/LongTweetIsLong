#import "Pastie.h"

#define kBoundaryString @"__10a7432849cf4656a59f0193a8e38cb5"

@implementation Pastie

+ (void)pasteWithContent:(NSString *)content
                 private:(BOOL)priv
              completion:(void (^)(BOOL success, NSURL *url))completionBlock {
    NSString *formFormat = @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n";
    NSMutableData *formData = [NSMutableData data];
    NSMutableDictionary *formInfo = [NSMutableDictionary dictionary];
    [formInfo setObject:content forKey:@"paste[body]" ];
    [formInfo setObject:@"burger" forKey:@"paste[authorization]" ];
    [formInfo setObject:priv ? @"1" : @"0" forKey:@"paste[restricted]" ];
    [formInfo setObject:@"6" forKey:@"paste[parser_id]" ];
    for(NSString *name in [formInfo allKeys]) {
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

