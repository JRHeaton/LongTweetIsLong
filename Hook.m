/*
 * LongTweetIsLong
 * Send >140 character tweets via Twitter for Mac by posting to Pastie(pastie.org)
 *
 * THIS IS FREE SOFTWARE. WE LOVE YOU <3
 *
 * John Heaton & Dan Zimmerman
 * jheaton.dev@gmail.com
 */

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "Pastie.h"

@class TMButton;
@class TwitterAccount;
@class TMComposeWindow;
@class TwitterComposition;
@class TMComposeWindowController;

@interface NSObject (TwitterHookLazyPie)

- (TwitterComposition *)composition;
- (TMComposeWindowController *)controller;
- (long long)remainingCharacters;
- (NSTextField *)counterView;
- (NSColor *)normalCounterColor;
- (TwitterComposition *)document;
- (NSString *)textWithAttachments;
- (void)removeAttachment:(id)attachment;
- (NSArray *)attachments;
- (BOOL)isDirectMessage;
- (NSArray *)composeWindows;

@property (readwrite, copy) NSString *text;

@end

static BOOL buttonGrown = NO;
static BOOL blockRemainingCharacters = NO;

BOOL _newCanPost(TMComposeWindow *self, SEL _cmd) {
    return [[[self controller] composition] remainingCharacters] < 140;
}

IMP _origClickedPost = NULL;
void _newClickedPost(TMComposeWindow *self, SEL _cmd, TMButton *sender) {
        blockRemainingCharacters = YES;
        _origClickedPost(self, _cmd, sender);
        blockRemainingCharacters = NO;
}

IMP _origSendCompletedComposition = NULL;
void _newSendCompletedComposition(TwitterAccount *self, SEL _cmd, TwitterComposition *composition) {
    /* original
     
     BOOL isDM = [self isDirectMessage];
     ABMainThreadProxy *proxy = [self mainThreadProxy];
     
     sub_10002c20a(proxy, @selector(didSendCompletedComposition:info:), composition);
     if(isDM) {
        // we dont' care
     } else {
        [apiInst updateWithComposition:composition];
     }
     
     */
    if([[composition textWithAttachments] length] <= 140) {
        _origSendCompletedComposition(self, _cmd, composition);
        return;
    }
    
    [Pastie pasteWithContent:[composition textWithAttachments] private:[composition isDirectMessage] completion:^(BOOL success, NSURL *url) {
            if(success) {
                NSString *urlString = [NSString stringWithFormat:@"... (cont) %@",[url absoluteString]];
                NSString *full = [[[composition textWithAttachments] substringWithRange:NSMakeRange(0, 140 - [urlString length] - 1)] stringByAppendingString:urlString];

                [composition setText:full];
                for(id attachment in [composition attachments])
                    [composition removeAttachment:attachment]; // because twitter's string handling is fucking stupid
                
                _origSendCompletedComposition(self, _cmd, composition);
            } else {
                static Class _TMComposeWindow = nil;
                if(!_TMComposeWindow)
                    _TMComposeWindow = objc_getClass("TMComposeWindow");
                
                for(TMComposeWindow *composeWindow in [_TMComposeWindow composeWindows]) {
                    if([[[composeWindow controller] composition] isEqual:composition]) {
                        // find a way to show the window again and have it NOT bitch out on us
                    }
                }
            }
    }];
}

IMP _origIsWorthSending = NULL;
BOOL _newIsWorthSending(TwitterComposition *self, SEL _cmd) {
    return _origIsWorthSending(self, _cmd) == NO ? [self remainingCharacters] < 0 : YES;
}

void _newSetRemainingCharacterCount(TMComposeWindow *self, SEL _cmd, long long remaining) {
    TMButton *postButton;
        
    if(remaining >= 0) {
        [[self counterView] setStringValue:[NSString stringWithFormat:@"%lli", remaining]];
        if(buttonGrown) {
            postButton = [self valueForKey:@"postButton"];
            
            NSRect postButtonFrame = [postButton frame];
            postButtonFrame.size.width -= 60;
            postButtonFrame.origin.x += 60;
                        
            buttonGrown = NO;
            
            [postButton setFrame:postButtonFrame];
            [postButton setTitle:[self isDirectMessage] ? @"Send" : @"Tweet"];
            [[self counterView] setHidden:NO];
        }
    } else if(!buttonGrown) {
        postButton = [self valueForKey:@"postButton"];
        NSRect postButtonFrame = [postButton frame];
        postButtonFrame.size.width += 60;
        postButtonFrame.origin.x -= 60;
        
        [postButton setFrame:postButtonFrame];
        [postButton setTitle:@"Send with Pastie"];
        [[self counterView] setHidden:YES];
    
        buttonGrown = YES;
    }
}

IMP _origClose = NULL;
void _newClose(TMComposeWindow *self, SEL _cmd) {
    buttonGrown = NO;
    _origClose(self, _cmd);
}

IMP _origRemainingCharacters = NULL;
long long _newRemainingCharacters(TwitterComposition *self, SEL _cmd) {
    if(blockRemainingCharacters)
        return 140; // ze goat don de trickery bahoozle
    else
        return (long long)_origRemainingCharacters(self, _cmd);
}

IMP _origSetTitle = NULL;
void _newSetTitle(TMButton *self, SEL _cmd) {
    if(!buttonGrown)
        _origSetTitle(self, _cmd);
}

void objc_methodHook(Class c, SEL sel, IMP newImp, IMP *origImp) {
    Method m = class_getInstanceMethod(c, sel);
    IMP orig = method_setImplementation(m, newImp);
    if(origImp)
        *origImp = orig;
}

__attribute__((constructor))
static void initWitchcraft() {
    @autoreleasepool {
        Class _TMComposeWindow = objc_getClass("TMComposeWindow");
        Class _TwitterComposition = objc_getClass("TwitterComposition");
        Class _TwitterAccount = objc_getClass("TwitterAccount");
        Class _TMButton = objc_getClass("TMButton");
        
        objc_methodHook(_TMComposeWindow, @selector(canPost), (IMP)_newCanPost, NULL);
        objc_methodHook(_TMComposeWindow, @selector(clickedPost:), (IMP)_newClickedPost, &_origClickedPost);
        objc_methodHook(_TMComposeWindow, @selector(setRemainingCharacterCount:), (IMP)_newSetRemainingCharacterCount, NULL);
        objc_methodHook(_TMComposeWindow, @selector(close), (IMP)_newClose, &_origClose);
        objc_methodHook(_TwitterAccount, @selector(sendCompletedComposition:), (IMP)_newSendCompletedComposition, &_origSendCompletedComposition);
        objc_methodHook(_TMButton, @selector(setTitle:), (IMP)_newSetTitle, &_origSetTitle);
        objc_methodHook(_TwitterComposition, @selector(isWorthSending), (IMP)_newIsWorthSending, &_origIsWorthSending);
        objc_methodHook(_TwitterComposition, @selector(remainingCharacters), (IMP)_newRemainingCharacters, &_origRemainingCharacters);
    }
}