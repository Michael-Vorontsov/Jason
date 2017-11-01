//
//  Navigator.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 01/11/2017.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Navigator : NSResponder

- (void)addNewJump:(NSString *)name document:(NSDocument *)document node:(NSTreeNode *)node;

- (IBAction)jumpTo:(id)sender;
- (IBAction)jumpNext:(id)sender;
- (IBAction)jumpPrev:(id)sender;

@end
