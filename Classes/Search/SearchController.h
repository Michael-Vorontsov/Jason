//
//  SearchController.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 20/10/2017.
//

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(NSUInteger, SearchOptions) {
    kSearchOptionKey = 0b001,
    kSearchOptionValue = 0b010,
    kSearchOptionsAll = kSearchOptionValue | kSearchOptionKey
};



@protocol SearchControllerDelegate

- (NSOrderedSet *)searchFor:(NSString *)keyword withOptions:(SearchOptions)options;
- (BOOL)showSearchResult:(id)searchResult;

@end

@protocol SearchControllerProtocol

@property (nonatomic, weak) id<NSTextFinderBarContainer> container;
@property (nonatomic, weak) id<SearchControllerDelegate> delegate;

- (void)show;
- (void)hide;

@end

@interface SearchController :  NSViewController <SearchControllerProtocol>

@end
