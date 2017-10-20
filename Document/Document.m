/*
 Copyright (c) 2010, Olivier Labs. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER AND CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Document.h"
#import "DocumentWC.h"
#import "JSON.h"
#import "NodeObject.h"
#import "OrderedDictionary.h"
#import "SearchController.h"
#import "AutocompletionPool.h"

@interface Document ()
- (void)readChildrenOf:(NSTreeNode *)parentNode;
- (void)writeChildrenOf:(NSTreeNode *)parentNode toObject:(id)object;
@property (nonatomic, strong) NSMutableDictionary *finderIndex;

- (NSOrderedSet<NSTreeNode *> *)searchForString:(NSString *)keyword options:(SearchOptions)options node:(NSTreeNode *)node;

@end

@implementation Document

@synthesize rootNode;
@synthesize parseError;
@synthesize invalidContents;

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self) [self resetContents];
	return self;
}

- (void)makeWindowControllers {
	[self addWindowController:[DocumentWC new]];
}

#pragma mark -
#pragma mark Tree/object/string representation

- (void)resetContents {
	self.contents = [MutableOrderedDictionary new];
}

- (void)setContents:(id)contents {
	NodeObject *data = [[NodeObject alloc] initWithValue:contents];
	rootNode = [[NSTreeNode alloc] initWithRepresentedObject:data];
	[self readChildrenOf:rootNode];
}

- (NSTreeNode *)createNewTreeNodeWithKey:(NSString *)key content:(id)contents {
    key = (nil != key) ? key : @"<null>";
    NodeObject *data = [[NodeObject alloc] initWithKey: key value: contents];
    [[AutocompletionPool sharedInstance] addString: key];
    NSTreeNode *node = [[NSTreeNode alloc] initWithRepresentedObject:data];
    [self readChildrenOf: node];
    return node;
}

- (NSTreeNode *)createNewTreeNodeWithContent:(id)contents {
    return [self createNewTreeNodeWithKey:nil content:contents];
}

- (NSTreeNode *)createNewTreeNodeWithKey:(NSString *)key {
    return [self createNewTreeNodeWithKey:key  content:nil];
}


- (NSTreeNode *)createNewTreeNode {
    return [self createNewTreeNodeWithKey:nil content:nil];
}



- (id)contents {
    return [self contentForNode:self.rootNode];
}

- (id)contentForNode: (NSTreeNode *)node {
    NodeObject *rootObject = [node representedObject];
    
    id contents = rootObject.value;
    [self writeChildrenOf:node toObject:contents];
    if (nil != node.parentNode) {
        NSString *key = (nil != rootObject.key) ? rootObject.key : @"Item";
        contents = [OrderedDictionary dictionaryWithDictionary:@{key : contents }];
    }

    return contents;
}

- (void)readChildrenOf:(NSTreeNode *)parentNode {
	id parentObject = [[parentNode representedObject] value];
	NSMutableArray *children = [parentNode mutableChildNodes];

	if ([parentObject isKindOfClass:[NSMutableArray class]]) {
		NSMutableArray *parentArray = parentObject;
		for (id childContents in parentArray) {
			// Add a node for the child...
			NodeObject *childObject = [[NodeObject alloc] initWithValue:childContents];
			NSTreeNode *childNode = [[NSTreeNode alloc] initWithRepresentedObject:childObject];
			[children addObject:childNode];
			
			// ...and recursively add its children
			[self readChildrenOf:childNode];
		}
		
		// We don't need the children in the original array because NSTreeNode::childNodes already keeps those
		[parentArray removeAllObjects];
	}
	else if ([parentObject isKindOfClass:[MutableOrderedDictionary class]]) {
		MutableOrderedDictionary *parentDict = parentObject;
        for (NSString *key in [parentDict allKeys]) {
			// Add a node for the child...
			NodeObject *childObject = [[NodeObject alloc] initWithKey:key value:[parentDict objectForKey:key]];

			NSTreeNode *childNode = [[NSTreeNode alloc] initWithRepresentedObject:childObject];
			[children addObject:childNode];
			
			// ...and recursively add its children
			[self readChildrenOf:childNode];
		}

		// We don't need the children in the original dictionary because NSTreeNode::childNodes already keeps those
		[parentDict removeAllObjects];
	}
}

- (NSString *)stringRepresentation {
    return [self stringRepresentationForNode:self.rootNode];
}

- (NSString *)stringRepresentationForNode:(NSTreeNode *)node {
    SBJsonWriter *parser = [SBJsonWriter new];
    parser.humanReadable = YES;
    parser.sortKeys = NO;
    NodeObject *nodeObject = node.representedObject;
    NSString *contentString = [parser stringWithObject:[self contentForNode:node]];
    if (nil == contentString) {
        contentString = [NSString stringWithFormat: @"%@", nodeObject.value];
    }
    return contentString;
}

- (void)writeChildrenOf:(NSTreeNode *)parentNode toObject:(id)object {
	NodeObject *parentObject = [parentNode representedObject];
	
    switch ([self typeForNode: parentNode]) {
        case kNodeObjectTypeArray: {
            parentObject.value = [NSMutableArray new];
            NSMutableArray *array = object;
            for (NSTreeNode *childNode in [parentNode childNodes]) {
                // Add the child object...
                NodeObject *childObject = [childNode representedObject];
                [array addObject:childObject.value];
                
                // ...and recursively add its children
                [self writeChildrenOf:childNode toObject:childObject.value];
            }
            break;
        }
        
        case kNodeObjectTypeDictionary: {
            parentObject.value = [MutableOrderedDictionary new];
            MutableOrderedDictionary *dict = object;
            for (NSTreeNode *childNode in [parentNode childNodes]) {
                // Add the child object...
                NodeObject *childObject = [childNode representedObject];
                [dict setObject:childObject.value forKey:childObject.key];
                
                // ...and recursively add its children
                [self writeChildrenOf:childNode toObject:childObject.value];
            }
            break;
        }

        default:
        break;
    }
}

- (NSOrderedSet<NSTreeNode *> *)searchForString:(NSString *)keyword options:(SearchOptions)options node:(NSTreeNode *)node {
    node = (nil != node) ? node : self.rootNode;
    NSMutableOrderedSet *results = [NSMutableOrderedSet new];
    NodeObject *nodeObject = node.representedObject;
    if ((0 != (options & kSearchOptionKey)) && [nodeObject.key.capitalizedString containsString: keyword.capitalizedString]) {
        [results addObject: node];
    }
    if ((0 != (options & kSearchOptionValue)) && ([nodeObject.value isKindOfClass:[NSString class]] || [nodeObject.value isKindOfClass:[NSNumber class]]) && [[nodeObject.value description] containsString: keyword]) {
        [results addObject: node];
    }
    for (NSTreeNode* each in node.childNodes) {
        NSOrderedSet *subsearchResult = [self searchForString:keyword options:options node:each];
        [results unionOrderedSet: subsearchResult];
    }
    return results;
}

- (NSString *)keyForNode:(NSTreeNode *)node {
    NodeObject *content = node.representedObject;
    return content.key;
}

- (void)setKey:(NSString *)newKey forNode:(NSTreeNode *)node {
    NodeObject *content = node.representedObject;
    NSString *oldKey = content.key;
    if (newKey == oldKey || [newKey isEqualToString: oldKey]) {
        return;
    }

    [AutocompletionPool.sharedInstance removeString:oldKey];
    [AutocompletionPool.sharedInstance addString:newKey];
    
    [self.undoManager registerUndoWithTarget:self handler:^(id  _Nonnull target) {
        [target setKey:oldKey forNode:node];
    }];

    content.key = newKey;
}

- (void)setValue:(id<NodeContentProtocol>)newValue forNode:(NSTreeNode *)node {
    NodeObject *content = node.representedObject;
    id oldValue = content.value;
    if (oldValue == newValue) {
        return;
    }
    [self.undoManager registerUndoWithTarget:self handler:^(id  _Nonnull target) {
        [target setValue:oldValue forNode:node];
    }];

    content.value = newValue;
}

- (id<NodeContentProtocol>)valueForNode:(NSTreeNode *)node {
    NodeObject *content = node.representedObject;
    return content.value;
}

- (void)setType:(NodeObjectType)newType forNode:(NSTreeNode*)node {
        NodeObject *content = node.representedObject;
        id oldValue = content.value;
    
        id newValue = nil;
        
        // Possible conversions:
        //
        // String -> Number, Boolean
        // Boolean -> String, Number (boolean must be tested before number)
        // Number -> String, Boolean
        
        // From string to...
        if ([oldValue isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)oldValue;
            
            if (newType == kNodeObjectTypeNumber) { // from string to number
                newValue = [[NSDecimalNumber alloc] initWithString:stringValue];
                if ([newValue isEqual:[NSDecimalNumber notANumber]]) newValue = nil;
            }
            else if (newType == kNodeObjectTypeBool) { // from string to boolean
                newValue = [NSNumber numberWithBool:[stringValue boolValue]];
            }
        }
        // From boolean to...
        else if ([[oldValue className] containsString: @"Boolean"]) {
            BOOL boolValue = [(NSNumber *)oldValue boolValue];
            
            if (newType == kNodeObjectTypeString) { // from boolean to string
                newValue = [NSString stringWithString:boolValue ?
                            NSLocalizedString(@"true", @"") :
                            NSLocalizedString(@"false", @"")];
            }
            else if (newType == kNodeObjectTypeNumber) { // from boolean to number
                newValue = [NSNumber numberWithInt:boolValue ? 1 : 0];
            }
        }
        // From number to...
        else if ([oldValue isKindOfClass: [NSNumber class]]) {
            NSDecimalNumber *numberValue = (NSDecimalNumber *)oldValue;
            
            if (newType == kNodeObjectTypeString) { // from number to string
                newValue = [NSString stringWithFormat:@"%@", numberValue];
            }
            else if (newType == kNodeObjectTypeBool) { // from number to boolean
                newValue = [NSNumber numberWithBool:[numberValue boolValue]];
            }
        }
        
        // If no conversion could be applied, instantiate a default value
        // that's not based on the old value
        if (!newValue) {
            switch (newType) {
                case kNodeObjectTypeDictionary: newValue = [MutableOrderedDictionary new]; break;
                case kNodeObjectTypeArray: newValue = [NSMutableArray new]; break;
                case kNodeObjectTypeString: newValue = @""; break;
                case kNodeObjectTypeNumber: newValue = [NSDecimalNumber numberWithInt:0]; break;
                case kNodeObjectTypeBool: newValue = (id)kCFBooleanFalse; break;
                default: newValue = [NSNull null]; break;
            }
        }
        
    [self setValue:newValue forNode:node];
}

- (NodeObjectType)typeForNode:(NSTreeNode*)node {
    id value = [self valueForNode: node];
    if ([value isKindOfClass:[NSDictionary class]]) return kNodeObjectTypeDictionary;
    else if ([value isKindOfClass:[NSArray class]]) return kNodeObjectTypeArray;
    else if ([value isKindOfClass:[NSString class]]) return kNodeObjectTypeString;
    else if ([[value className] containsString:@"Boolean"]) return kNodeObjectTypeBool;
    else if ([value isKindOfClass:[NSNumber class]]) return kNodeObjectTypeNumber;
    
    return kNodeObjectTypeNull;
}

- (void)deleteNode:(NSTreeNode *)currentNode fromParent:(NSTreeNode *)parentNode {
    
    if (! parentNode) { // removing the root object
        [self resetContents];
    }
    else {
        NSIndexPath *path = [currentNode indexPath];
        NSUInteger position = [path indexAtPosition:[path length] - 1];
        NSTreeNode *nodeToRemove = [[parentNode childNodes] objectAtIndex:position];
        
        [self.undoManager registerUndoWithTarget:self handler:^(id  _Nonnull target) {
            [target insertNode:nodeToRemove toParentNode:parentNode atIndex:position];
        }];
        
        [[parentNode mutableChildNodes] removeObjectAtIndex:position];
    }
}

- (void)insertNode:(NSTreeNode *)newNode toParentNode:(NSTreeNode *)parentNode atIndex:(NSUInteger)row {
    
    [self.undoManager registerUndoWithTarget:self handler:^(id  _Nonnull target) {
        [target deleteNode:newNode fromParent:parentNode];
    }];
    
    if (row < parentNode.childNodes.count) {
        [[parentNode mutableChildNodes] insertObject:newNode atIndex:row];
    } else {
        [[parentNode mutableChildNodes] addObject:newNode];
    }
}


#pragma mark -
#pragma mark Read and write

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSError *error = nil;
	NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	SBJsonParser *parser = [SBJsonParser new];
    id parsedContents = [parser objectWithString:strData error:&error];
	parseError = error;
	// If there was a parse error, keep the (invalid) string in stringContents...
	if (parseError) invalidContents = strData;
	// ...otherwise, we have a valid object to use as contents
	else self.contents = parsedContents;
	
	return YES;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	NSError *error = nil;
	NSString *string = [self stringRepresentation];
	[string writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		if (outError) *outError = error;
		return NO;
	}

	return YES;
}

- (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
	return YES;
}

@end
