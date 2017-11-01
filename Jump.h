//
//  Jump.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 01/11/2017.
//

#import <Foundation/Foundation.h>

@class NSDocument;
@class NSTreeNode;

@interface Jump : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, weak, readonly) NSDocument *document;
@property (nonatomic, weak, readonly) NSTreeNode *treeNode;

- (instancetype)initWithName:(NSString *)aName document:(NSDocument *)aDocument node:(NSTreeNode *)node;

@end
