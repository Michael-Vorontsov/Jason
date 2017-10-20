//
//  NodeObjectType.h
//  Jason
//
//  Created by Mykhailo Vorontsov on 20/10/2017.
//  Copyright © 2017 Olivier Labs. All rights reserved.
//

#ifndef NodeObjectType_h
#define NodeObjectType_h

typedef NS_OPTIONS(NSInteger, NodeObjectType) {
    kNodeObjectTypeDictionary = 1<<0,
    kNodeObjectTypeArray = 1<<1,
    kNodeObjectTypeString = 1<<2,
    kNodeObjectTypeNumber = 1<<3,
    kNodeObjectTypeBool = 1<<4,
    kNodeObjectTypeNull = 1<<5,

    kNodeObjectTypeCollection = kNodeObjectTypeDictionary | kNodeObjectTypeArray,
    kNodeObjectTypeLeaf = kNodeObjectTypeNull | kNodeObjectTypeString | kNodeObjectTypeNumber | kNodeObjectTypeBool
};

#endif /* NodeObjectType_h */
