//
//  Navigator.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 01/11/2017.
//

#import "Navigator.h"
#import "Jump.h"
#import "SearchController.h"

typedef NS_ENUM(NSInteger, NavigationMenuTags) {
    kNavigationMenuTagForward = 1,
    kNavigationMenuTagBackward = 2,
    kNavigationMenuTagJumpsMenu = 3,
    kNavigationMenuTagNavigationMenu = 42
};

@interface Navigator()

@property (nonatomic, strong) NSMutableArray<Jump*>* storedJumps;
@property (nonatomic) NSUInteger jumpIndex;

@end

@implementation Navigator

- (NSArray<Jump*>*) storedJumps {
    if (nil == _storedJumps) {
        _storedJumps = [NSMutableArray<Jump*> new];
    }
    return _storedJumps;
}

- (void)addNewJump:(NSString *)name document:(NSDocument *)document node:(NSTreeNode *)node {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

        // Remove all jumps after last.
        if (self.storedJumps.count > self.jumpIndex + 1) {
            if (0 == self.jumpIndex) {
                self.storedJumps = nil;
            } else {
                [self.storedJumps removeObjectsInRange:NSMakeRange(self.jumpIndex  + 1, self.storedJumps.count - self.jumpIndex - 1)];
            }
        }

        Jump *lastJump = self.storedJumps.lastObject;
        // If last jump equal to one to add - skip
        if ([lastJump.name isEqualToString:name] && (lastJump.document == document) && (lastJump.treeNode == node)) {
            return;
        }

        // Cancel adding new node if last jump was to parent of current jump
        if (nil != node.parentNode && [self.storedJumps.lastObject treeNode] == node.parentNode) {
            return;
        }

        Jump* jump = [[Jump alloc] initWithName:name document:document node:node];
        self.jumpIndex = self.storedJumps.count;
        [[self storedJumps] addObject:jump];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invalidateUI];
        });
    });

}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if (@selector(jumpTo:) == item.action ) {
        item.state = (item.tag == (NSInteger)self.jumpIndex) ? NSControlStateValueOn : NSControlStateValueOff;
        return YES;
    }
    
    switch (item.tag) {
        case kNavigationMenuTagForward:
            return ((self.storedJumps.count > 0) && ((NSUInteger)self.jumpIndex + 1 < self.storedJumps.count));
        case kNavigationMenuTagBackward:
            return (self.storedJumps.count > 0 && self.jumpIndex > 0);
        default:
            return YES;
    }
}

- (void)invalidateUI {
    NSMenu *rootMenu = [NSApp mainMenu];
    NSMenu *navigationMenu = [[rootMenu itemWithTag:kNavigationMenuTagNavigationMenu] submenu];
    
    NSMenu *recentJumpsMenu = [[navigationMenu itemWithTag:kNavigationMenuTagJumpsMenu] submenu];
    [recentJumpsMenu removeAllItems];
    NSInteger index = 0;
    for (Jump *each in self.storedJumps) {
        if (nil != each.treeNode) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:each.name action:@selector(jumpTo:) keyEquivalent:@""];
            item.tag = index;
            [recentJumpsMenu insertItem:item atIndex:index];
            index++;
        } else {
            [self.storedJumps removeObject: each];
        }
    }
    [navigationMenu update];
}

- (IBAction)jumpTo:(id)sender {
    NSInteger tag = [sender tag];
    [self jumpToIndex: tag];
}

- (void)jumpToIndex:(NSInteger)anIndex {
    NSInteger elementsCount = self.storedJumps.count;
    if (anIndex >= elementsCount) {
        anIndex = 0;
    } else if(anIndex < 0) {
        anIndex = elementsCount;
    }

    if (anIndex >= elementsCount) {
        return;
    }
    Jump *jump = self.storedJumps[anIndex];
    if (nil == jump.treeNode) {
        return;
    }
    
    [jump.document showWindows];
    id<SearchControllerDelegate> controller = [[jump.document windowControllers] firstObject];
    if ([controller showSearchResult: jump.treeNode]) {
        self.jumpIndex = anIndex;
//        [self invalidateUI];
    }
}

- (IBAction)jumpNext:(id)sender {
    [self jumpToIndex: self.jumpIndex + 1];
}

- (IBAction)jumpPrev:(id)sender {
    [self jumpToIndex: self.jumpIndex - 1];
}


@end
