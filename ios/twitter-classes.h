/**
yup
**/
@class TwitterCompositionAttachment, TwitterAccount, TwitterComposition, NSURL, TwitterAutocompleteController, ABNavButton, TIComposeAttachmentsView, TweetieComposeAttachmentsViewController;
@interface TweetieComposeViewController: NSObject {
@private
	TwitterAccount *account;
	TwitterComposition *composition;
	ABNavButton *sendButton;
	TIComposeAttachmentsView* attachmentsView;
        TweetieComposeAttachmentsViewController* attachmentsViewController;
        TwitterAutocompleteController* autocompleteController;
	UILabel* remainingCharactersLabel;
}
@property(retain, nonatomic) TwitterComposition* composition;
@property(retain, nonatomic) TwitterAccount* account;
-(void)send:(id)send;
-(void)_checkLengthAndSend;
-(void)_send;
-(void)_checkCurrentText;
-(void)_textDidChange;
@end

@interface TwitterComposition : NSObject {
	TwitterCompositionAttachment* attachment;
}
@property(copy, nonatomic) NSString* text;
@property(retain, nonatomic) TwitterCompositionAttachment* attachment;
-(int)remainingCharacters;
-(BOOL)isWorthSending;
-(BOOL)isDirectMessage;
-(NSString *)textWithAttachment;
@end

@interface TwitterAccount : NSObject
-(void)sendCompletedComposition:(TwitterComposition *)composition;
@end

@interface ABNavButton : NSObject
-(void)setTitle:(NSString *)string;
@end
