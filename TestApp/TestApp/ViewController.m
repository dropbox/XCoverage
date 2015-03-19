//
//  ViewController.m
//  TestApp
//
//  Created by Tyler Mann on 3/18/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

+ (void)testedMethod
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)partiallyTestedMethod
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL val = NO;
    if (val) {
        NSLog(@"%@", @"Not tested");
    }
}

@end
