//
//  TextViewDelegateInterseptor.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
//  Copyright © 2017 Olivier Labs. All rights reserved.
//

#import "TextViewDelegateInterseptor.h"

@interface TextViewDelegateInterseptor()

@property (nonatomic, strong) NSHashTable *delegates;

@end


@implementation TextViewDelegateInterseptor

- (NSHashTable *)delegates {
    if (nil == _delegates) {
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return _delegates;
}

- (void)addDelegate: (id<NSTextViewDelegate>)delegate {
    if (delegate != self) {
        [self.delegates addObject:delegate];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString *str = NSStringFromSelector(aSelector);
    
    for (id<NSTextViewDelegate> each in self.delegates.allObjects) {
        if (YES == [each respondsToSelector: aSelector]) {
            NSLog(@"can responds to: %@", str);
            return YES;
        }
    }
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    BOOL forwarded = NO;
    
    for (id<NSTextViewDelegate> each in self.delegates.allObjects) {
        
        if ([each respondsToSelector: [anInvocation selector]]) {
            NSString *str = NSStringFromSelector([anInvocation selector]);
            
            NSLog(@"responding to: %@", str);
            
            [anInvocation invokeWithTarget:each];
            return;
            forwarded = YES;
        }
    }
    
    if (!forwarded) {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
    
    for (NSObject* each in self.delegates.allObjects) {
        if (YES == [each respondsToSelector: aSelector]) {
            return [each methodSignatureForSelector: aSelector];
        }
    }
    
    return [super methodSignatureForSelector: aSelector];
}

//- (void)currentEditor {
//    NSLog(@"wtf!");
//}

@end
