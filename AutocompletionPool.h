//
//  AutocompletionStack.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 18/10/2017.
//  Copyright © 2017 Olivier Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutocompletionPool : NSObject

+ (AutocompletionPool *)sharedInstance;

- (void)addString:(NSString *)value;
- (void)removeString:(NSString *)value;

- (NSArray<NSString *> *)suggestionsForMask:(NSString *)mask;

@end
