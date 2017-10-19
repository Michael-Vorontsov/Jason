//
//  TextViewDelegateInterseptor.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
//  Copyright © 2017 Olivier Labs. All rights reserved.
//

#import "TextViewDelegateInterseptor.h"

@interface TextViewDelegateInterseptor()

@property (nonatomic, strong) NSPointerArray *delegates;

@end


@implementation TextViewDelegateInterseptor

- (NSPointerArray *)delegates {
    if (nil == _delegates) {
        _delegates = [NSPointerArray weakObjectsPointerArray];
    }
    return _delegates;
}

- (void)addDelegate: (id<NSTextViewDelegate>)delegate {
    if (delegate != self) {
        [self.delegates addPointer: (__bridge void * _Nullable)(delegate)];
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
            // If delegate method consider returning object - it means only on delegate should be called.
            if ([[anInvocation methodSignature] methodReturnLength] > 0) {
                return;
            }
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
