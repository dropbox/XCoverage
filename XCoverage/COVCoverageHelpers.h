//
//  COVCoverageHelpers.h
//  XCoverage
//
//  Created by Tyler Mann on 3/11/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void COVLog(NSString *format, ...);

@interface COVPreviousLocationContext : NSObject
@end

@interface COVCoverageHelpers : NSObject

- (instancetype)init __attribute__((unavailable("Not intended to be initialized. Helpers only.")));

// Returns the URL of the current file that is being viewed/edited.
+ (NSURL *)currentFileURL;

// Returns the textView of the current file that is being viewed/edited.
+ (NSTextView *)currentTextView;

/**
 *  Automatically tries to find the coverage file matching the sourceFile. Looks in
 *  two places, either the build products directory in DerivedData or the relative 
 *  build directory. The ordering if this search is determined by the previousLocationContext
 *  which can aid to look in the same place that a coverage file was last found.
 *
 *  @param sourceFile The sourceFile that you want to find the matching coverage file for.
 *  @param context    This parameter is optional, but you can create a COVPreviousLocationContext
 *      and pass it in every time that you call this method to use the most recently used location.
 *
 *  @return NSURL to the coverage file or nil if none was found.
 */
+ (NSURL *)automaticallyFindCoverageFileForSourceFile:(NSURL *)sourceFile withPreviousLocationContext:(COVPreviousLocationContext *)context;

/**
 *  This method tries to find the coverage file matching the sourceFile by recursively 
 *  searching in the searchDirectory.
 *
 *  @param sourceFile The sourceFile that you want to find the matching coverage file for.
 *  @param searchDirectory The directory to recursively search through for the coverage file.
 *
 *  @return NSURL to the coverage file or nil if none was found.
 */
+ (NSURL *)findCoverageFileForSourceFile:(NSURL *)sourceFile manualSearchDirectory:(NSURL *)searchDirectory;

@end
