//
//  TextViewDelegateInterseptor.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
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
    for (id<NSTextViewDelegate> each in self.delegates.allObjects) {
        if (YES == [each respondsToSelector: aSelector]) {
            return YES;
        }
    }
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    BOOL forwarded = NO;
    
    for (id<NSTextViewDelegate> each in self.delegates.allObjects) {
        
        if ([each respondsToSelector: [anInvocation selector]]) {
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

@end
