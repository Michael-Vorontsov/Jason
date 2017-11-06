//
//  SearchController.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 20/10/2017.
//

#import "SearchController.h"
#import "AppDelegate.h"
#import "DocumentWC.h"
#import "Document.h"

@interface SearchController ()

@property (nonatomic, copy) NSString *lastSearchQuerry;
@property (weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) NSPointerArray *lastResults;
@property (nonatomic, readwrite) NSInteger lastSelectedIndex;
@property (nonatomic, readwrite) SearchOptions options;
@property (weak) IBOutlet NSView *backgroundView;
@property (weak) IBOutlet NSTextField *resultsLabel;

@end

@implementation SearchController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.options = kSearchOptionsAll;
    [self.backgroundView makeBackingLayer];
    self.backgroundView.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

- (void)viewDidAppear {
    [super viewDidAppear];

    self.resultsLabel.stringValue = @"";
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName: NSFindPboard];
    NSString *lastSearchString = [[pasteboard readObjectsForClasses:@[[NSString class]] options:nil] lastObject];
    if (nil != lastSearchString) {
        self.searchField.stringValue = lastSearchString;
    }
    [self.searchField becomeFirstResponder];
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
    self.resultsLabel.stringValue = @"";
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *string = nil;
                switch (results.count) {
                    case 0:
                        string = [NSString stringWithFormat: NSLocalizedString(@"Not found", nil)];
                        break;
                    case 1:
                        string = [NSString stringWithFormat: NSLocalizedString(@"Found", nil)];
                        break;
                    default:
                        string = [NSString stringWithFormat: NSLocalizedString(@"#1 from %lu", nil), results.count];
                        break;
                }
                self.resultsLabel.stringValue = string;
            });
            if (results.count < 1) {
                return;
            }
            for (id each in results) {
                [self.lastResults addPointer: (__bridge void * _Nullable)(each)];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
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
    self.resultsLabel.stringValue = [NSString stringWithFormat: NSLocalizedString(@"#%lu from %lu", nil), self.lastSelectedIndex + 1, results.count];

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
    self.resultsLabel.stringValue = [NSString stringWithFormat: NSLocalizedString(@"#%lu from %lu", nil), self.lastSelectedIndex + 1, results.count];
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
