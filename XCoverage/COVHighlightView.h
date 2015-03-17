//
//  COVHighlightView.h
//  XCoverage
//
//  Created by Tyler Mann on 3/10/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import <Cocoa/Cocoa.h>

@interface COVHighlightView : NSView

- (instancetype)init __attribute__((unavailable("Please use designated initializer instead")));
- (instancetype)initWithFrame:(NSRect)frameRect __attribute__((unavailable("Please use designated initializer instead")));

- (instancetype)initWithFrame:(NSRect)frameRect color:(NSColor *)color;

@end
