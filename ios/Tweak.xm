#import "twitter-classes.h"
#import "Pastie.h"
#import <substrate.h>
static BOOL blockRemainingCharacters = YES;
%hook TwitterComposition
- (int)remainingCharacters {
	int remaining = %orig;
	if(blockRemainingCharacters && remaining <=0)
        	return 0; // ze goat don de trickery bahoozle
    	else
		return remaining;
}

- (BOOL) isWorthSending {
	BOOL ret = %orig;
	return ret == NO ? [self remainingCharacters] < 0 : YES;
}
%end

%hook TwitterAccount
-(void)sendCompletedComposition:(TwitterComposition*)composition {
	if([[composition textWithAttachment] length] <= 140) {
		%orig;
        	return;
    	}
    	[Pastie pasteWithContent:[composition textWithAttachment]  private:[composition isDirectMessage] completion:^(BOOL success, NSURL *url){
		if(success) {
			NSString *urlString = [NSString stringWithFormat:@"... (cont) %@",[url absoluteString]];
                        NSString *full = [[[composition textWithAttachment] substringWithRange:NSMakeRange(0, 140 - [urlString length] - 1)] stringByAppendingString:urlString];
        
                        [composition setText:full];
                        //for(id attachment in [composition attachments])
                        //      [composition removeAttachment:attachment]; // because twitter's string handling is fucking stupid
                        [composition setAttachment:nil];
                        %orig(composition);
            	} //else {
                	//static Class _TMComposeWindow = nil;
                	//if(!_TMComposeWindow)
                    	//	_TMComposeWindow = objc_getClass("TMComposeWindow");
                	//
                	//for(TMComposeWindow *composeWindow in [_TMComposeWindow composeWindows]) {
                    	//	if([[[composeWindow controller] composition] isEqual:composition]) {
                        //		// find a way to show the window again and have it NOT bitch out on us
                    	//	}
                	//}
        	//}
    	}];
}
%end

%hook TweetieComposeViewController
-(void)_textDidChange{
//	NSLog(@"PSTWEET: changed %d", [[self composition] remainingCharacters]);
	%orig;
	if([[self composition] remainingCharacters] <= 0){
		[(UILabel *)MSHookIvar<UILabel *>((id)self, "remainingCharactersLabel") setText:@"Pastie!"];	
	}

}
%end
