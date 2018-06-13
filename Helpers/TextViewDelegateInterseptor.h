//
//  TextViewDelegateInterseptor.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface TextViewDelegateInterseptor: NSObject <NSTextViewDelegate>

- (void)addDelegate: (id<NSTextViewDelegate>)delegate;

@end
