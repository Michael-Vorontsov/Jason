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

#import "OutlineViewVC.h"
#import "OutlineView.h"
#import "OutlineViewDelegate.h"
//#import "NodeObject.h"
#import "Document.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"
#import "AutocompletionPool.h"
#import "TextViewDelegateInterseptor.h"
#import "SearchController.h"


@interface OutlineViewVC ()
- (void)refreshView;
- (void)changeTypeTo:(NSUInteger)newType forIndexSet:(NSIndexSet *)indexSet;

@property (nonatomic, strong) NSMutableSet *subscriptions;
@property (nonatomic, strong) NSArray *dragItems;
//@property (nonatomic, weak) id<NSTextViewDelegate> textEditorDelegate;
@property (nonatomic, strong) TextViewDelegateInterseptor *textEditorDelegateInterseptor;

@property (nonatomic, strong) NSOrderedSet *searchResults;
@property (nonatomic, readwrite) NSInteger selectedSearchIndex;
@property (nonatomic, readonly) Document *document;

@end


@implementation OutlineViewVC

static NSNumberFormatter *numberFormatter = nil;

@synthesize outlineScrollView;
@synthesize outlineView;
@synthesize keyColumn;
@synthesize typeColumn;
@synthesize valueColumn;

+ (void)initialize {
	numberFormatter = [NSNumberFormatter new];
	[numberFormatter setMaximumFractionDigits:100];
}

- (id)init {
	return [super initWithNibName:@"OutlineView" bundle:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (Document *)document {
    return self.representedObject;
}

- (void)viewDidLoad {
    
    // Prepare cells for the value column
    buttonCell = [NSButtonCell new];
    [buttonCell setTitle:@""];
    [buttonCell setControlSize:NSSmallControlSize];
    [buttonCell setButtonType:NSSwitchButton];
    
    numberCell = [[valueColumn dataCell] copy];
    [numberCell setFormatter:numberFormatter];
    [numberCell setEditable:YES];
    
    disabledKeyCell = [[keyColumn dataCell] copy];
    [disabledKeyCell setEnabled:NO];
    [disabledKeyCell setEditable:NO];
    //[(NSTextFieldCell *)disabledKeyCell setTextColor:[NSColor darkGrayColor]];
    
    disabledTypeCell = [[typeColumn dataCell] copy];
    [disabledTypeCell setEnabled:NO];
    [disabledTypeCell setEditable:NO];
    
    disabledValueCell = [[valueColumn dataCell] copy];
    [disabledValueCell setEnabled:NO];
    [disabledValueCell setEditable:NO];
    
    [outlineView sizeLastColumnToFit];

    NSNotificationCenter * _Nonnull notificationCenter = [NSNotificationCenter defaultCenter];
    
    [self.subscriptions addObject:
     [notificationCenter
      addObserverForName:NSUndoManagerDidUndoChangeNotification
      object:nil
      queue:[NSOperationQueue mainQueue]
      usingBlock:^(NSNotification * _Nonnull note) {
        [outlineView reloadData];
      }]
    ];

    [self.subscriptions addObject:
     [notificationCenter
      addObserverForName:NSUndoManagerDidRedoChangeNotification
      object:nil
      queue:[NSOperationQueue mainQueue]
      usingBlock:^(NSNotification * _Nonnull note) {
          [outlineView reloadData];
      }]
     ];
    
    [self.outlineView registerForDraggedTypes:@[NSStringPboardType, NSFilenamesPboardType, NSURLPboardType]];
    [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];

    [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];
	[self refreshView];
}

- (void)refreshView {
	[outlineView reloadData];
	[outlineView expandItem:[outlineView itemAtRow:0] expandChildren:YES];	
}

#pragma mark -
#pragma mark Outline view delegate

- (NSCell *)outlineView:(NSOutlineView *)theOutlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSTreeNode *currentNode = item;
//    NodeObject *currentObject = [currentNode representedObject];

	NSCell *cell = nil;
	
	// Boolean values use a checkbox cell
    if (tableColumn == valueColumn && [self.document typeForNode: currentNode] == kNodeObjectTypeBool) {
		cell = buttonCell;
	}
	// Number values need a number formatter
	else if (tableColumn == valueColumn && [self.document typeForNode: currentNode] == kNodeObjectTypeNumber) {
		cell = numberCell;
	}	
	// Default cell
	else {
		if ([self outlineView:theOutlineView shouldEditTableColumn:tableColumn item:item]) {
			cell = [tableColumn dataCellForRow:[outlineView rowForItem:item]];	
		}
		else {
			if (tableColumn == keyColumn) cell = disabledKeyCell;
			else if (tableColumn == typeColumn) cell = disabledTypeCell;
			else if (tableColumn == valueColumn) cell = disabledValueCell;
		}
	}
	
	return cell;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSUInteger flags = [[NSApp currentEvent] modifierFlags];
    if (0 == (flags & NSAlternateKeyMask)) {
        return;
    }
    NSUInteger index = self.outlineView.selectedRow;
    NSTreeNode *selectedNode = [self.outlineView itemAtRow:index];
    if ([self.document typeForNode:selectedNode] == kNodeObjectTypeString) {
        NSString *value = [self.document valueForNode: selectedNode];
        if (value.length > 3) {
            [[NSApplication sharedApplication] sendAction:NSSelectorFromString(@"searchFor:") to:nil from: value];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)theView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	BOOL shouldEdit = NO;
	NSTreeNode *currentNode = item;
	
	if (tableColumn == keyColumn) {
		NSTreeNode *parentNode = [currentNode parentNode];
//        NodeObject *parentObject = [parentNode representedObject];
        shouldEdit = (! editValueColumnOnly) && [self.document typeForNode:parentNode] == kNodeObjectTypeDictionary;
	}
	else if (tableColumn == typeColumn) {
		shouldEdit = ! editValueColumnOnly;	
	}
	else if (tableColumn == valueColumn) {
        NodeObjectType type = [self.document typeForNode: currentNode];
		shouldEdit = (type == kNodeObjectTypeString ||
					  type == kNodeObjectTypeNumber ||
					  type == kNodeObjectTypeBool);
	}
	
    NSTextView* textEditor = (NSTextView *)[self.outlineView currentEditor];
    if (shouldEdit && textEditor.delegate != self.textEditorDelegateInterseptor) {
        if (nil == self.textEditorDelegateInterseptor) {
            self.textEditorDelegateInterseptor = [TextViewDelegateInterseptor new];
        }
        [self.textEditorDelegateInterseptor addDelegate: self];
        [self.textEditorDelegateInterseptor addDelegate: textEditor.delegate];
        textEditor.delegate = self.textEditorDelegateInterseptor;
    }

	return shouldEdit;
}

#pragma mark -
#pragma mark Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)childIndex ofItem:(id)parent {
	if (parent == nil) return [(Document *)[self representedObject] rootNode];
	
	NSTreeNode *parentNode = parent;
	return [[parentNode childNodes] objectAtIndex:childIndex];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)parent {
	return (parent == nil) ? 1 : [[(NSTreeNode *)parent childNodes] count];
}

- (BOOL)outlineView:(NSOutlineView *)view isItemExpandable:(id)item {
	return ! [(NSTreeNode *)item isLeaf];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return (tableColumn == valueColumn);
}

- (id)outlineView:(NSOutlineView *)theOutlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
	NSTreeNode *node = item;
    NSTreeNode *parentNode = [node parentNode];

	/***** Key column *****/
	if (tableColumn == keyColumn) {
		// The root object has a literal key
		if (nil == parentNode) return NSLocalizedString(@"Root", @"");
		
		// If it belongs to a dictionary, return its key
        NSString *key = [self.document keyForNode: node];
		if ([self.document typeForNode: parentNode] == kNodeObjectTypeDictionary && nil != key) return key;
		
		// If it doesn't belong to a dictionary then it belongs to an array. Return its position within the array
		NSIndexPath *indexPath = [node indexPath];
		NSUInteger position = [indexPath indexAtPosition:[indexPath length] - 1];
		return [NSString stringWithFormat:NSLocalizedString(@"Item %u", @""), position];
	}
	/***** Type column *****/
	else if (tableColumn == typeColumn) {
		// Because of the separator between dictionary/array and scalar values,
		// we need to change the type sent to the table view
        return [NSNumber numberWithLong: [self menuIndexForType:[self.document typeForNode: node]]];
	}
	/***** Value column *****/
	else if (tableColumn == valueColumn) {
		// Collections show the number of items
		if ([self.document typeForNode: node] & kNodeObjectTypeCollection) {
			NSUInteger count = [[node childNodes] count];
			if (count == 1) return [NSString stringWithString:NSLocalizedString(@"(1 item)", @"")];
			return [NSString stringWithFormat:NSLocalizedString(@"(%d items)", @""), count];
		}
		// Null shows, erm, null
		else if ([self.document typeForNode: node] == kNodeObjectTypeNull) return NSLocalizedString(@"(null)", @"");
		// Otherwise show the item itself
        else return [self.document valueForNode: node];
	}
	
	return @"";
}

- (void)changeTypeTo:(NSUInteger)newType {
    NSIndexSet *selectedIndexSet = [outlineView selectedRowIndexes];
    [self changeTypeTo:newType forIndexSet: selectedIndexSet];
}

- (void)changeTypeTo:(NSUInteger)newType forIndexSet:(NSIndexSet *)indexSet {
    
    for (NSUInteger currentIndex = [indexSet firstIndex];
         currentIndex != NSNotFound;
         currentIndex = [indexSet indexGreaterThanIndex:currentIndex]) {
        NSTreeNode *currentNode = [outlineView itemAtRow:currentIndex];
        NSTreeNode *parentNode = [outlineView parentForItem:currentNode];
        //        NodeObject *currentObject = [currentNode representedObject];
        
        if (kNodeObjectTypeDictionary == [self.document typeForNode: currentNode] && kNodeObjectTypeArray == newType) {
            NSInteger index = 0;
            for (NSTreeNode *each in currentNode.childNodes) {
                [self.document setKey:[NSString stringWithFormat:NSLocalizedString(@"Item %u", @""), index] forNode:each];
                index++;
            }
        }
        
        [self.document setType:newType forNode:currentNode];
        
        if (parentNode == nil) { // replacing the root object
            self.document.contents = [self.document valueForNode: currentNode];
            [outlineView reloadData];
        }
        else {
            [outlineView reloadItem:currentNode];
        }
        
        [self.document updateChangeCount:NSChangeDone];
    }
    
}


#pragma mark -PopUp Menu  items to Type convertor helper
- (NSInteger)menuIndexForType:(NodeContentType)type {
    switch (type) {
        case kNodeObjectTypeDictionary:
            return 0;
        case kNodeObjectTypeArray:
            return 1;
        case kNodeObjectTypeString:
            return 3;
        case kNodeObjectTypeNumber:
            return 4;
        case kNodeObjectTypeBool:
            return 5;
        case kNodeObjectTypeNull:
            return 6;
        case kNodeObjectTypeCollection:
        case kNodeObjectTypeLeaf:
            return -1;
    }
}

- (NodeContentType)typeForMenuIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return kNodeObjectTypeDictionary;
        case 1:
            return kNodeObjectTypeArray;
        case 3:
            return kNodeObjectTypeString;
        case 4:
            return kNodeObjectTypeNumber;
        case 5:
            return kNodeObjectTypeBool;
        case 6:
            return kNodeObjectTypeNull;
        default:
            return 0;
    }
}

- (void)outlineView:(NSOutlineView *)theOutlineView
	 setObjectValue:(id)newValue
	 forTableColumn:(NSTableColumn *)tableColumn
			 byItem:(id)item
{
	Document *doc = [self representedObject];
	BOOL changed = NO;
	
	/***** Key column *****/
	if (tableColumn == keyColumn) {
		NSTreeNode *currentNode = item;
		NSTreeNode *parentNode = [outlineView parentForItem:currentNode];

        // Only dictionary items can have their key changed
		if ([self.document typeForNode: parentNode] == kNodeObjectTypeDictionary) {
			NSMutableArray *children = [parentNode mutableChildNodes];
			
			// We only allow replacing an existing key with a non-existing one
			if (![children containsObject:newValue]) {
                [self.document setKey: newValue forNode: currentNode];
				[outlineView reloadItem:currentNode];
				changed = YES;
			}
		}
	}
	/***** Type column *****/
	else if (tableColumn == typeColumn) {
		// Because of the separator between dictionary/array and scalar values,
		// we need to change the type sent by the table view
		[self changeTypeTo: [self typeForMenuIndex: [newValue integerValue]]];
		changed = YES;
	}
	/***** Value column *****/
	else if (tableColumn == valueColumn) {
		NSTreeNode *currentNode = item;
        NSTreeNode *parentNode = [currentNode parentNode];
		
        if (nil == parentNode){
            doc.contents = newValue;
        }
		else {
            [self.document setValue: newValue forNode: currentNode];
			[outlineView reloadItem:currentNode];
		}
		changed = YES;
	}
	
	if (changed) [doc updateChangeCount:NSChangeDone];	
}

#pragma mark -


#pragma mark -
#pragma mark IB Actions

- (IBAction)addRow:(id)sender {
	// Search for a collection (array, dictionary) starting from the currently
	// selected item, up the hierarchy
	NSInteger row = [outlineView selectedRow];
    if (row < 0 || row > outlineView.numberOfRows) {
        row = 0;
    }
    NSAssert(row >= 0, @"addRow: row < 0");

	NSTreeNode *parentNode = [outlineView itemAtRow:row];
    NodeContentType parentType = [self.document typeForNode: parentNode];
	while (nil != parentNode && !(parentType & kNodeObjectTypeCollection)) {
		parentNode = [parentNode parentNode];
        parentType = [self.document typeForNode:parentNode];
	}
	
	// Do nothing if root node not a collection
	if (0 == (parentType & kNodeObjectTypeCollection)) return;
    
	// Rows belonging to a dictionary need a key. Find a key that doesn't exist yet
    NSString *newKey = nil;
	if (parentType == kNodeObjectTypeDictionary) {
		NSUInteger i = 0;
		BOOL foundKey;
		do {
			newKey = [NSString stringWithFormat:NSLocalizedString(@"New item %u", @""), i++];
			foundKey = [[parentNode childNodes] indexOfObjectPassingTest:^(NSTreeNode *node, NSUInteger idx, BOOL *stop) {
				if ([[self.document keyForNode: node] isEqualToString: newKey]) {
					*stop = YES;
					return YES;
				}
				return NO;
			}] != NSNotFound;
		} while (foundKey);
	}
    id newContent = @"";
    NSTreeNode *newNode = [self.document createNewTreeNodeWithKey: newKey content: newContent];
    [self.document insertNode:newNode toParentNode:parentNode atIndex:NSIntegerMax];
    [self.outlineView reloadItem:parentNode reloadChildren: YES];
    [self.outlineView expandItem:parentNode];
    
    NSUInteger rowToSelect = [outlineView rowForItem:newNode];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];

    NSInteger columnToEdit = (parentType == kNodeObjectTypeDictionary && (!editValueColumnOnly)) ? 0 : 2;
    [outlineView editColumn:columnToEdit row:rowToSelect withEvent:nil select:YES];

	[self.document updateChangeCount:NSChangeDone];
}


- (IBAction)deleteRow:(id)sender {
	NSIndexSet *selectedIndexSet = [outlineView selectedRowIndexes];
	
	for (NSUInteger currentIndex = [selectedIndexSet firstIndex];
		 currentIndex != NSNotFound;
		 currentIndex = [selectedIndexSet indexGreaterThanIndex:currentIndex])
	{
        NSTreeNode *currentNode = [outlineView itemAtRow:currentIndex];
        NSTreeNode *parentNode = [currentNode parentNode];
        [self.document deleteNode:currentNode fromParent:parentNode];
        [self.outlineView reloadItem:parentNode reloadChildren: YES];
	}
	if ([selectedIndexSet count] == 1) {
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[selectedIndexSet firstIndex]]
				 byExtendingSelection:NO];
	}
}

- (IBAction)changeType:(id)sender {
	[self changeTypeTo:[sender tag]];
}

- (IBAction)toggleEditValueColumnOnly:(id)sender {
	editValueColumnOnly = ! editValueColumnOnly;
	[outlineView setNeedsDisplay:YES];
}

- (IBAction)editKey:(id)sender {
    NSInteger selectedRow = outlineView.selectedRow;
    [outlineView editColumn:0 row:selectedRow withEvent:nil select:YES];
}

- (IBAction)editValue:(id)sender {
    NSInteger selectedRow = outlineView.selectedRow;
    [outlineView editColumn:2 row:selectedRow withEvent:nil select:YES];
}

#pragma mark -
#pragma mark Drag&Drop

/* Setup a local reorder. */
- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    NSMutableString *stringToDrag = [NSMutableString new];
    self.dragItems = draggedItems;
    for (NSTreeNode* each in draggedItems) {
        [stringToDrag appendString: [self.document stringRepresentationForNode:each]];
    }
    
    [session.draggingPasteboard setString:stringToDrag forType:NSPasteboardTypeString];
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    {
        switch (operation) {
            case NSDragOperationMove:
            case NSDragOperationGeneric:
            case NSDragOperationDelete: {
                [self.dragItems
                 enumerateObjectsWithOptions:NSEnumerationReverse
                 usingBlock:^(NSTreeNode *node, NSUInteger index, BOOL *stop) {
                     [self.document deleteNode:node fromParent:node.parentNode];
                     [self.outlineView reloadItem: node.parentNode reloadChildren:YES];
                 }];
                break;
            }
            default:
                break;
        }
        
        self.dragItems = nil;
    }
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    NSDragOperation moveOrCopy = (info.draggingSourceOperationMask == NSDragOperationCopy ? NSDragOperationCopy : NSDragOperationMove);
    return moveOrCopy;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    NSTreeNode *node = (NSTreeNode *)item;
    switch ([self.document typeForNode: node]) {
        case kNodeObjectTypeDictionary:
            break;
        case kNodeObjectTypeArray:
            break;
        case kNodeObjectTypeNull:
        case kNodeObjectTypeBool:
        case kNodeObjectTypeNumber:
        case kNodeObjectTypeString: {
            NSTreeNode *parentNode = [node parentNode];
            childIndex = [[parentNode childNodes] indexOfObject:node] + 1;
            node = parentNode;
            break;
        }
        default:
            break;
    }
    
    NSArray *classes = @[[NSPasteboardItem class]];
    
    __block BOOL result = NO;
    
    [info
     enumerateDraggingItemsWithOptions:0
     forView:self.outlineView
     classes:classes
     searchOptions:@{}
     usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
         NSPasteboardItem *pbItem = draggingItem.item;
         NSString *stringConent = [pbItem stringForType:NSPasteboardTypeString];
         if (nil == stringConent) {
             return;
         }
         SBJsonParser *parser = [SBJsonParser new];
         id parsedContents = [parser objectWithString:stringConent error: nil];
         if (nil == parsedContents) {
             return;
         }
         NSTreeNode *newNode = [[[self.document createNewTreeNodeWithContent:parsedContents] childNodes] lastObject];
         [self.document insertNode:newNode toParentNode:node atIndex:childIndex];
         [self.outlineView reloadItem:node reloadChildren:YES];
         [self.outlineView expandItem:node];

         result = YES;
         
    }];
    
    return result;
}


/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    NSString *string = [self.representedObject stringRepresentationForNode:(NSTreeNode *)item];
    
    return string;
}



#pragma mark -
#pragma mark User Interface Validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(toggleEditValueColumnOnly:)) {
		NSMenuItem *menuItem = (NSMenuItem *)item;
		
        [menuItem setTitle:(editValueColumnOnly) ? NSLocalizedString(@"Edit All Columns",nil) : NSLocalizedString(@"Edit Value Column Only", nil)];
	}
	
	return YES;
}

#pragma mark -
#pragma mark Control Text Editing Delegate

- (BOOL)handleKeyDown:(NSEvent *)event {
	unichar character = [[event characters] characterAtIndex:0];
	
	/*
	 if (character == NSTabCharacter) {
	 NSLog(@"OutlineView -keyDown: Tab; focused column = %ld", [self focusedColumn]);
	 // If no column is focused, let's try to focus the first
	 // editable column, if any
	 if ([self focusedColumn] == -1) {
	 // Edit the key column if it is editable
	 NSTableColumn *keyCol = [[self tableColumns] objectAtIndex:kKeyColumnIndex];
	 NSTableColumn *valueCol = [[self tableColumns] objectAtIndex:kValueColumnIndex];
	 NSInteger row = [self selectedRow];
	 id item = [self itemAtRow:row];
	 
	 if ([[self delegate] outlineView:self shouldEditTableColumn:keyCol item:item]) {
	 [self editColumn:kKeyColumnIndex row:row withEvent:nil select:YES];				
	 return;
	 }
	 // Edit the value column if it is editable
	 else if ([[self delegate] outlineView:self shouldEditTableColumn:valueCol item:item]) {
	 [self editColumn:kValueColumnIndex row:row withEvent:nil select:YES];
	 return;
	 }
	 }
	 // If the value column is currently focused, try to focus the first editable column of the
	 // next editable line, if any
	 else if ([self focusedColumn] == kValueColumnIndex) {
	 NSLog(@"value column was focused");
	 for (NSInteger row = [self selectedRow] + 1; row < [self numberOfRows]; ++row) {
	 id item = [self itemAtRow:row];
	 
	 for (NSUInteger col = 0; col < 3; ++col) {
	 NSTableColumn *column = [[self tableColumns] objectAtIndex:col];
	 
	 if ([[self delegate] outlineView:self shouldEditTableColumn:column item:item]) {
	 [self editColumn:col row:row withEvent:nil select:YES];
	 return;
	 }
	 }
	 ++row;
	 }
	 }
	 }
	 else */
	if (character == NSCarriageReturnCharacter) {
        [self editValue: self];
		return YES;
	}
	
	// It's not a key event we want to capture, so let the
	// outline view deal with it
	return NO;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
	// We want to modify the behaviour of Tab (should skip to the next row(s), first focusable column if any)...
	if (command == @selector(insertTab:) && outlineView.lastFocusedColumn == kValueColumnIndex) {
		NSUInteger rowCount = [outlineView numberOfRows];
		NSUInteger colCount = [[outlineView tableColumns] count];
		
		for (NSUInteger row = [outlineView selectedRow] + 1; row < rowCount; ++row) {
			for (NSUInteger columnIndex = 0; columnIndex < colCount; ++columnIndex) {
				NSCell *cell = [outlineView preparedCellAtColumn:columnIndex row:row];
				
				if ([outlineView shouldFocusCell:cell atColumn:columnIndex row:row]) {
					[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
					[outlineView editColumn:columnIndex row:row withEvent:nil select:YES];				
					return YES;
				}
			}
		}
	}
	// ...and Backtab (should skip to the previous focusable column, possibly at a previous row)
	else if (command == @selector(insertBacktab:)) {
		NSUInteger lastColumn = [[outlineView tableColumns] count] - 1;
		NSInteger columnIndex = [outlineView focusedColumn] - 1;
		
		NSLog(@"back tabbing, first candidate = %ld", columnIndex);
		
		for (NSInteger row = [outlineView selectedRow]; row >= 0; --row) {
			while (columnIndex >= 0) {
				NSCell *cell = [outlineView preparedCellAtColumn:columnIndex row:row];
				
				if ([outlineView shouldFocusCell:cell atColumn:columnIndex row:row]) {
					[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
					[outlineView editColumn:columnIndex row:row withEvent:nil select:YES];				
					return YES;
				}
				--columnIndex;
			}
			
			columnIndex = lastColumn;
		}		
	}

	
	return NO;
}

#pragma mark -
#pragma mark Copy-paste

- (IBAction)copy:(id)sender {
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    
    NSMutableArray *objectsToCopy = [NSMutableArray new];
    NSIndexSet *selectedIndexSet = [outlineView selectedRowIndexes];
    
    for (NSUInteger currentIndex = [selectedIndexSet firstIndex];
         currentIndex != NSNotFound;
         currentIndex = [selectedIndexSet indexGreaterThanIndex:currentIndex])
    {
        NSTreeNode *currentNode = [outlineView itemAtRow:currentIndex];
        NSString *string = [self.representedObject stringRepresentationForNode:currentNode];
        if (string.length > 0) {
            [objectsToCopy addObject: string];
        }
    }
    if (objectsToCopy.count > 0) {
        [pasteboard clearContents];
        [pasteboard writeObjects:objectsToCopy];
    }
}
- (IBAction)paste:(id)sender {
    NSError *error = nil;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    if (![pasteboard canReadObjectForClasses:classes options:options]) return;
    
    NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classes options:options];
    NSString *pasteboardString = [[objectsToPaste objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *contentsToPaste;

    if ([[pasteboardString substringToIndex:7] isEqualToString:@"http://"] || [[pasteboardString substringToIndex:8] isEqualToString:@"https://"]) {
        NSURL *url = [NSURL URLWithString:pasteboardString];
        contentsToPaste = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        if (nil != error) {
            [NSApp presentError:error];
            return;
        }
    }
    else {
        contentsToPaste = pasteboardString;
    }
    SBJsonParser *parser = [SBJsonParser new];
    id parsedContents = [parser objectWithString:contentsToPaste error:&error];
    if (nil != error) {
        error = nil;
        // Try to remove trailing semicolons and  wrap content into brackets
        contentsToPaste = [NSString stringWithFormat:@"{\n%@\n}", [contentsToPaste stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;"]]];
        parsedContents = [parser objectWithString:contentsToPaste error:&error];
        if (nil != error) {
            [NSApp presentError:error];
            return;
        }
    }
    
    if (nil != parsedContents) {
        NSUInteger selectedRow = [outlineView selectedRow];
        NSTreeNode *currentNode = [outlineView itemAtRow: selectedRow];
        NSTreeNode *parrentNode = [currentNode parentNode];
        
        if (nil == parrentNode) {
            Document *newDoc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:NO error:&error];
            if (error) {
                [NSApp presentError:error];
                return;
            }
            newDoc.contents = parsedContents;
        }
        
        NSUInteger index = [[parrentNode childNodes] indexOfObject:currentNode] + 1;
        NSTreeNode *newNode = [self.document createNewTreeNodeWithContent:parsedContents];
        if (1 == newNode.childNodes.count) {
            [self.document insertNode:newNode.childNodes.lastObject toParentNode:parrentNode atIndex:index];
        }
        else {
            [self.document insertNode:newNode toParentNode:parrentNode atIndex:index];
        }
    }
}

#pragma mark -
#pragma mark - Search

- (NSInteger)selectItem:(NSTreeNode *)node {
    if (nil == node || ![node isKindOfClass:[NSTreeNode class]]) {
        return -1;
    }
    NSInteger index = -1;
    NSTreeNode *nodeToOpen = node;
    NSMutableOrderedSet *chain = [NSMutableOrderedSet new];
    do {
        [chain addObject: nodeToOpen];
        index = [self.outlineView rowForItem: nodeToOpen];
        nodeToOpen = nodeToOpen.parentNode;
    } while (index < 0 && nil != nodeToOpen);
    
    // If postion of root parent still unknown - return. Perhaps node not in tree at all.
    if (index < 0) {
        return -1;
    }
    
    // Expend all chain of parents up node
    for (NSTreeNode *each in [chain reversedOrderedSet]) {
        [self.outlineView expandItem: each];
    }
    
    index = [self.outlineView rowForItem: node];
    
    [self.outlineView
     selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
     byExtendingSelection: NO
     ];
    [self.outlineView scrollRowToVisible: index];
    return index;
}

- (NSOrderedSet *)searchFor:(NSString *)keyword withOptions:(SearchOptions)options {
    Document *doc = self.representedObject;
    NSOrderedSet *searchResult = [doc searchForString:keyword options:options node:nil];
    return searchResult;
}

- (BOOL)showSearchResult:(id)searchResult {
    NSInteger selectedIndex = [self selectItem: searchResult];
    return selectedIndex >= 0;
}



#pragma mark -
#pragma mark - TextViewDelegate

- (NSArray<NSString *> *)textView:(NSTextView *)textView completions:(NSArray<NSString *> *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    NSArray *suggestions = [AutocompletionPool.sharedInstance suggestionsForMask:textView.string];
    
    return suggestions;
}

@end




