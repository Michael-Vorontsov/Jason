//
//  AutocompletionStack.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
//

#import "AutocompletionPool.h"


@interface AutocompletionPool()

@property (nonatomic, strong) NSMutableSet<NSString *> *allStrings;

@end

@implementation AutocompletionPool

+ (AutocompletionPool *)sharedInstance {
    
    static dispatch_once_t onceToken;
    static AutocompletionPool* sInstance;

    dispatch_once(&onceToken, ^{
        sInstance = [AutocompletionPool new];
    });
    
    return sInstance;
}

- (NSMutableSet<NSString *> *)allStrings {
    if (nil == _allStrings) {
        _allStrings = [NSMutableSet<NSString *> new];
    }
    return _allStrings;
}

- (void)addString:(NSString *)value {
    if (value != nil) {
        [self.allStrings addObject:value];
    }
}
- (void)removeString:(NSString *)value {
    if (value != nil) {
        [self.allStrings removeObject: value];
    }
}

- (NSArray<NSString*> *)suggestionsForMask:(NSString *)mask {
    NSArray *filteredStrings = nil;
    if (mask.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", mask];
        filteredStrings = [self.allStrings.allObjects filteredArrayUsingPredicate:predicate];
    }
    else {
        filteredStrings = self.allStrings.allObjects;
    }
    NSArray<NSString*> *orderedStrings = [filteredStrings sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return orderedStrings;
}

@end
