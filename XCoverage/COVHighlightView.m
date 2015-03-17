//
//  COVHighlightView.m
//  XCoverage
//
//  Created by Tyler Mann on 3/10/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import "COVHighlightView.h"

@implementation COVHighlightView
{
    NSColor *_color;
}

- (instancetype)initWithFrame:(NSRect)frameRect color:(NSColor *)color
{
    self =  [super initWithFrame:frameRect];
    if (self) {
        _color = color;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

    [_color set];
    NSRectFillUsingOperation(rect, NSCompositeSourceOver);
}

@end
