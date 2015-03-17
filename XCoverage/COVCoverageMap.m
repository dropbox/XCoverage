//
//  COVCoverageMap.m
//  CoverageMap
//
//  Created by Tyler Mann on 3/11/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import "COVCoverageMap.h"
#import "COVCoverageHelpers.h"

NSString *const COVCoverageTypeNotCode = @"COVCoverageTypeNotCode";
NSString *const COVCoverageTypeNotCovered = @"COVCoverageTypeNotCovered";
NSString *const COVCoverageTypeCovered = @"COVCoverageTypeCovered";
NSString *const COVCoverageTypeUnknown = @"COVCoverageTypeUnknown";

@implementation COVCoverageMap

+ (NSDictionary *)coverageMapForURL:(NSURL *)fileURL
{
    COVLog(@"generating coverageMap");

    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*?(.):.*?(\\d+)" options:0 error:&error];

    if (error) {
        COVLog(@"Error generating regex.");
    } else {
        NSString *fileText = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            // Unable to open file, may not exist
            return nil;
        } else {
            __block NSUInteger lineNumber = 0;
            [fileText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                [regex enumerateMatchesInString:line
                        options:0
                          range:NSMakeRange(0, [line length])
                     usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                         // Increment the lineNumber if there is a match for this line, since there are some header lines that won't match
                         lineNumber++;

                         NSString *substring = [line substringWithRange:[result range]];
                         [self cov_addCoverageData:substring toMap:map];

                         // Stop after first match since we only care about the beginning of the line
                         *stop = YES;
                     }];
            }];
        }
    }

//    COVLog(@"Generated map with %lu lines", [map count]);

    return map;
}

+ (void)cov_addCoverageData:(NSString *)coverageLine toMap:(NSMutableDictionary *)coverageMap
{
    NSMutableArray *components = [[coverageLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
    // Strip empty strings from the array (extra whitespaces)
    [components removeObject:@""];
    if ([components count] != 2) {
        COVLog(@"Expected there to only be two components.");
        return;
    }

    NSString *covData = components[0];
    NSNumber *lineNumber = @([components[1] integerValue]);
    if ([lineNumber integerValue] == 0) {
        // We don't want to add anything with line 0 since it is just coverage header data
        return;
    }
//    COVLog(@"Match: %@ linenumber: %lu", covData, [lineNumber integerValue]);

    coverageMap[lineNumber] = [self cov_coverageTypeGivenData:covData];
}

+ (BOOL)cov_isFirstCharacterADigit:(NSString *)string
{
    if ([string length] == 0) {
        return NO;
    }
    unichar c = [string characterAtIndex:0];
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    return [numericSet characterIsMember:c];
}

+ (NSString *)cov_coverageTypeGivenData:(NSString *)covData
{
    if ([covData hasPrefix:@"-"]) {
        return COVCoverageTypeNotCode;
    } else if ([covData hasPrefix:@"#"] || [covData hasPrefix:@"="]) {
        return COVCoverageTypeNotCovered;
    } else if ([self cov_isFirstCharacterADigit:covData]) {
        return COVCoverageTypeCovered;
    } else {
        COVLog(@"Unrecognized covData: %@", covData);
        return COVCoverageTypeUnknown;
    }
}


@end
