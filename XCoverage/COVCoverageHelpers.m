//
//  COVCoverageHelpers.m
//  XCoverage
//
//  Created by Tyler Mann on 3/11/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import "COVCoverageHelpers.h"
#import "COVInternalHeaders.h"

void COVLog(NSString *format, ...) {
    va_list argptr;
    format = [@"COVLog " stringByAppendingString:format];
    va_start(argptr, format);
    NSString *logString = [[NSString alloc] initWithFormat:format arguments:argptr];
    NSLog(@"%@", logString);
    va_end(argptr);
}

typedef NS_ENUM(NSUInteger, COVPreviousGcovLocation) {
    COVPreviousGcovLocationDefault,
    COVPreviousGcovLocationRelative,
};

@interface COVPreviousLocationContext ()
@property (nonatomic, assign) COVPreviousGcovLocation location;
@end

@implementation COVPreviousLocationContext
@end

@implementation COVCoverageHelpers

#pragma mark - Getting current file

+ (id<COVEditor>)cov_currentEditor
{
    NSWindowController *windowController = [[NSApp keyWindow] windowController];
    if ([windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        return [[[(id)windowController editorArea] lastActiveEditorContext] editor];
    }
    return nil;
}

+ (NSURL *)currentFileURL
{
    id<COVEditor> editor = [self cov_currentEditor];
    IDESourceCodeDocument *sourceCodeDoc = nil;
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        sourceCodeDoc = [editor sourceCodeDocument];
    } else if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")] && [[editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
        sourceCodeDoc = [editor primaryDocument];
    }
    return [sourceCodeDoc fileURL];
}

#pragma mark - Getting currente textView

+ (NSTextView *)currentTextView
{
    id<COVEditor> editor = [self cov_currentEditor];
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return [editor textView];
    } else if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        return [editor keyTextView];
    }
    return nil;
}

#pragma mark - Searching for gcov files

+ (NSURL *)automaticallyFindCoverageFileForSourceFile:(NSURL *)sourceFile withPreviousLocationContext:(COVPreviousLocationContext *)context
{
    if (context.location == COVPreviousGcovLocationDefault) {
        NSURL *url = [self cov_defaultCoverageFileLocationForSourceFile:sourceFile];
        if (!url) {
            url = [self cov_relativeCoverageFileLocationForSourceFile:sourceFile];
            if (url) {
                // Update the context location if we found a url in a new location
                context.location = COVPreviousGcovLocationRelative;
            }
        }
        return url;
    } else {
        NSURL *url = [self cov_relativeCoverageFileLocationForSourceFile:sourceFile];
        if (!url) {
            url = [self cov_defaultCoverageFileLocationForSourceFile:sourceFile];
            if (url) {
                // Update the context location if we found a url in a new location
                context.location = COVPreviousGcovLocationDefault;
            }
        }
        return url;
    }
}

+ (NSURL *)findCoverageFileForSourceFile:(NSURL *)sourceFile manualSearchDirectory:(NSURL *)searchDirectory
{
    NSString *gcovFileName = [[sourceFile lastPathComponent] stringByAppendingPathExtension:@"gcov"];
    return [self cov_findFileName:gcovFileName inDirectoryURL:searchDirectory];
}

#pragma mark private helpers

+ (NSURL *)cov_buildIntermediatesURL
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") workspaceWindowControllers];

    if (workspaceWindowControllers.count == 0) {
        return nil;
    }

    id workspace = [[workspaceWindowControllers firstObject] valueForKey:@"_workspace"];
    id workspaceArena = [workspace valueForKey:@"_workspaceArena"];
    NSString *buildIntermediatesPath = [[workspaceArena buildIntermediatesFolderPath] valueForKey:@"_pathString"];
    return [NSURL URLWithString:buildIntermediatesPath];
}

+ (NSURL *)cov_findFileName:(NSString *)fileName inDirectoryURL:(NSURL *)directoryURL
{
    if (!directoryURL) {
        COVLog(@"directoryURL is nil! cannot enumerate.");
        return nil;
    }
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:nil
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             return YES;
                                         }];

    for (NSURL *url in enumerator) {
        if ([[url lastPathComponent] isEqualToString:fileName]) {
            return url;
        }
    }

    return nil;
}

#pragma mark  search directories used for automatic search

+ (NSURL *)cov_defaultCoverageFileLocationForSourceFile:(NSURL *)sourceFile
{
    NSString *gcovFileName = [[sourceFile lastPathComponent] stringByAppendingPathExtension:@"gcov"];
    NSURL *directoryURL = [self cov_buildIntermediatesURL];
    return [self cov_findFileName:gcovFileName inDirectoryURL:directoryURL];
}

+ (NSURL *)cov_relativeCoverageFileLocationForSourceFile:(NSURL *)sourceFile
{
    NSString *gcovFileName = [[sourceFile lastPathComponent] stringByAppendingPathExtension:@"gcov"];

    NSString *directoryPath = [[[sourceFile path] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    COVLog(@"Looking in relative path");
    return [self cov_findFileName:gcovFileName inDirectoryURL:[NSURL URLWithString:directoryPath]];
}

@end
