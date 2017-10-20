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

#import <Cocoa/Cocoa.h>
#import "SearchController.h"
#import "NodeObjectType.h"

@protocol NodeContentProtocol
@end

typedef NodeObjectType NodeContentType;

@protocol NodeContentAccessProtocol
- (void)setKey:(NSString *)newKey forNode:(NSTreeNode*)node;
- (NSString*)keyForNode:(NSTreeNode *)node;

- (void)setValue:(id)newValue forNode:(NSTreeNode*)node;
- (id)valueForNode:(NSTreeNode*)node;

- (void)setType:(NodeContentType)newType forNode:(NSTreeNode*)node;
- (NodeContentType)typeForNode:(NSTreeNode*)node;

- (NSString *)stringRepresentationForNode:(NSTreeNode *)node;

@end

@interface Document : NSDocument <NodeContentAccessProtocol> {
	NSTreeNode *rootNode; // tree representation of the object returned by the JSON parser
	
	// We allow invalid JSON contents in the text view. If the document was opened with invalid
	// contents, store the parseError so that it is presented when the window is shown
	NSError *parseError;
	NSString *invalidContents;
}

@property (readonly) NSTreeNode *rootNode;
@property (readonly) NSError *parseError;
@property (readonly) NSString *invalidContents;

@property id contents;

- (NSString *)stringRepresentation;
- (void)resetContents;

- (NSTreeNode *)createNewTreeNodeWithKey:(NSString *)key content:(id)content;
- (NSTreeNode *)createNewTreeNodeWithContent:(id)contents;
- (NSTreeNode *)createNewTreeNodeWithKey:(NSString *)key;
- (NSTreeNode *)createNewTreeNode;

//TODO: Make it private. Expose SearchControllerDelegate instead.
- (NSOrderedSet<NSTreeNode *> *)searchForString:(NSString *)keyword options:(SearchOptions)options node:(NSTreeNode *)node;

@end



//@interface Document (NodeContentAccess) <NodeContentAccessProtocol>
//@end

