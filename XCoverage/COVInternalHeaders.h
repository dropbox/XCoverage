//
//  COVInternalHeaders.h
//  XCoverage
//
//  Created by Tyler Mann on 3/13/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 *  These are just XCode internal class interfaces.
 */

@interface IDESourceCodeDocument : NSDocument
@end

@protocol COVEditor <NSObject>
@optional
// Exists if is IDESourceCodeEditor class
- (IDESourceCodeDocument *)sourceCodeDocument;
- (NSTextView *)textView;

// Exists if is IDESourceCodeComparisonEditor class
- (IDESourceCodeDocument *)primaryDocument;
- (NSTextView *)keyTextView;
@end

@interface IDEEditorContext : NSObject
- (id<COVEditor>)editor;
@end

@interface IDEEditorArea : NSObject
- (IDEEditorContext *)lastActiveEditorContext;
@end

@interface IDEWorkspaceWindowController : NSObject
- (IDEEditorArea *)editorArea;
+ (NSArray *)workspaceWindowControllers;
@end

@interface IDEWorkspaceArena : NSObject

// Returns a DVTFilePath with _pathString string ivar
- (id)buildIntermediatesFolderPath;

@end
