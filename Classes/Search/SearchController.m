//
//  SearchController.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 20/10/2017.
//  Copyright © 2017 Olivier Labs. All rights reserved.
//

#import "SearchController.h"
#import "AppDelegate.h"
#import "DocumentWC.h"
#import "Document.h"

@interface SearchController ()

@property (nonatomic, copy) NSString *lastSearchQuerry;
//@property (nonatomic, weak) id<NSTextFinderBarContainer> container;
//@property (nonatomic, weak) id<SearchControllerDelegate> delegate;
@property (weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) NSPointerArray *lastResults;
@property (nonatomic, readwrite) NSInteger lastSelectedIndex;
@property (nonatomic, readwrite) SearchOptions options;
@property (weak) IBOutlet NSView *backgroundView;
@property (weak) IBOutlet NSTextField *resultsLabel;
@property (nonatomic, strong) NSPasteboard* pasteboard;

@end


@implementation SearchController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.options = kSearchOptionsAll;
    [self.backgroundView makeBackingLayer];
    self.backgroundView.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

- (NSPasteboard *)pasteboard {
    if (nil == _pasteboard) {
        _pasteboard = [NSPasteboard pasteboardWithName: NSFindPboard];
    }
    return _pasteboard;
}

- (void)viewDidAppear {
    [super viewDidAppear];

    NSString *lastSearchString = [[self.pasteboard readObjectsForClasses:@[[NSString class]] options:nil] lastObject];
    self.searchField.stringValue = lastSearchString;
    [self.pasteboard addObserver:self forKeyPath:@"changeCount" options:NSKeyValueObservingOptionNew context:nil];

    [self.searchField becomeFirstResponder];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [self.pasteboard removeObserver:self forKeyPath:@"changeCount"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    NSString *lastSearchString = [[self.pasteboard readObjectsForClasses:@[[NSString class]] options:nil] lastObject];
    self.searchField.stringValue = lastSearchString;
}


- (NSPointerArray *)lastResults {
    if (nil == _lastResults) {
        _lastResults = [NSPointerArray weakObjectsPointerArray];
    }
    return  _lastResults;
}

- (IBAction)changeSearchOption:(NSButton *)sender {
    self.options = [sender tag];
    self.lastSearchQuerry = nil;
}

- (IBAction)search:(NSSearchField *)sender {
    NSString *querry = self.searchField.stringValue;
    if (querry.length < 1) {
        return;
    }
    if (querry != self.lastSearchQuerry) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.lastResults = nil;
            self.lastSearchQuerry = querry;
            self.lastSelectedIndex = 0;
            NSOrderedSet *results = [self.delegate searchFor:querry withOptions:self.options];
            if (results.count < 1) {
                return;
            }
            for (id each in results) {
                [self.lastResults addPointer: (__bridge void * _Nullable)(each)];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultsLabel.stringValue = [NSString stringWithFormat: NSLocalizedString(@"Found %lu", nil), results.count];
                [self.delegate showSearchResult: results.firstObject];;
            });
        });
    }
    else {
        [self next: sender];
    }
}

- (IBAction)next:(id)sender {
    NSArray *results = self.lastResults.allObjects;
    if (results.count < 1 || self.lastSearchQuerry != self.searchField.stringValue) {
        [self search: nil];
        return;
    }
    self.lastSelectedIndex++;
    if (self.lastSelectedIndex >= (NSInteger)results.count) {
        self.lastSelectedIndex = 0;
    }
    [self.delegate showSearchResult: results[self.lastSelectedIndex]];
}

- (IBAction)prev:(id)sender {
    NSArray *results = self.lastResults.allObjects;
    if (results.count < 1 || self.lastSearchQuerry != self.searchField.stringValue) {
        [self search: nil];
        return;
    }
    self.lastSelectedIndex--;
    if (self.lastSelectedIndex < 0) {
        self.lastSelectedIndex = results.count - 1;
    }
    [self.delegate showSearchResult:  results[self.lastSelectedIndex]];
}

- (void)show {
    self.container.findBarView = self.view;
    self.container.findBarVisible = YES;
}

- (IBAction)close:(id)sender {
    [self hide];
}

- (void)hide {
    self.container.findBarVisible = NO;
}

@synthesize delegate;

@synthesize container;

@end
