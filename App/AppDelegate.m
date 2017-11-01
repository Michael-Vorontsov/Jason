/*
 Copyright (c) 2010, Olivier Labs. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER AND CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"
#import "OpenURLWC.h"
#import "PreferencesWC.h"
#import "SBJsonParser.h"
#import "Document.h"
#import "SearchController.h"
#import "Navigator.h"

@implementation AppDelegate

- (IBAction)openFromURL:(id)sender {
	if (! openURLWC) openURLWC = [OpenURLWC new];
	[openURLWC showWindow:self];
}

- (IBAction)showPreferencesPanel:(id)sender {
	if (! preferencesWC) preferencesWC = [PreferencesWC new];
	[preferencesWC showWindow:self];
}

- (IBAction)searchFor:(id)sender {
    
    NSString *string = nil;
    if ( [sender isKindOfClass:[NSString class]]) {
        string = sender;
    }
    
    if (string.length > 3) {
        NSOrderedSet *results = [self searchFor:string withOptions:kSearchOptionKey];
        if (results.count > 0) {
            [self showSearchResult: results.firstObject];
        }
    }
}

- (NSOrderedSet *)searchFor:(NSString *)keyword withOptions:(SearchOptions)options {
    NSMutableOrderedSet *results = [NSMutableOrderedSet new];
    for (NSWindow *window in [[NSApplication sharedApplication] windows]) {
        NSWindowController *controller = [window windowController];
        if ([controller respondsToSelector:@selector(searchFor:withOptions:)]) {
            [results unionOrderedSet: [(id<SearchControllerDelegate>)controller searchFor:keyword withOptions:options]];
        }
    }
    return results;
}

- (BOOL)showSearchResult:(id)searchResult {
    for (NSWindow *window in [[NSApplication sharedApplication] windows]) {
        NSWindowController *controller = [window windowController];
        if ([controller respondsToSelector:@selector(showSearchResult:)]) {
            if ([(id<SearchControllerDelegate>)controller showSearchResult: searchResult]) {
                
                Document *document = [(NSWindowController *)controller document];
                NSString *name = [document keyForNode:(NSTreeNode *) searchResult];
                [self.navigator addNewJump:name document:document node:searchResult];
                
                [window makeKeyWindow];
                return YES;
            }
        }
    }
    return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notificiation {
    NSApplication *app = [NSApplication sharedApplication];
    NSResponder *nextReponder = [app nextResponder];
    [self.navigator setNextResponder: nextReponder];
    [app setNextResponder: self.navigator];
}

- (Navigator *)navigator {
    if (nil == _navigator) {
        _navigator = [Navigator new];
    }
    return _navigator;
}

@end
