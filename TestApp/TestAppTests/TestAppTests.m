//
//  TestAppTests.m
//  TestAppTests
//
//  Created by Tyler Mann on 3/18/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ViewController.h"

@interface TestAppTests : XCTestCase

@end

@implementation TestAppTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCoveredMethod
{
    [ViewController testedMethod];
}

- (void)testPartiallyCoveredMethod
{
    [ViewController partiallyTestedMethod];
}

@end
