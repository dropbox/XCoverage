//
//  COVCoverageMap.h
//  CoverageMap
//
//  Created by Tyler Mann on 3/11/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import <Foundation/Foundation.h>

extern NSString *const COVCoverageTypeNotCode;
extern NSString *const COVCoverageTypeNotCovered;
extern NSString *const COVCoverageTypeCovered;
extern NSString *const COVCoverageTypeUnknown;

@interface COVCoverageMap : NSObject

- (instancetype)init __attribute__((unavailable("Not intended to be initialized. Helpers only.")));

/**
 *  Creates a mapping from line number to coverage data for that line.
 *
 *  @param NSURL of file to retreive coverage data for expected to be a '.gcov' file.
 *
 *  @return NSDictionary mapping NSNumber line numbers to coverage
 */
+ (NSDictionary *)coverageMapForURL:(NSURL *)fileURL;

@end
