//
//  Jump.m
//  Jason
//
//  Created by Mykhailo Vorontsov on 01/11/2017.
//

#import "Jump.h"
#import <Cocoa/Cocoa.h>

@implementation Jump

- (instancetype)initWithName:(NSString *)aName document:(NSDocument *)aDocument node:(NSTreeNode *)node {
    self = [super init];
    if (nil != self) {
        _name = aName;
        _document = aDocument;
        _treeNode = node;
    }
    return self;
}

@end
