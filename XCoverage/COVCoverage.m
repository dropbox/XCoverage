//
//  COVCoverage.m
//  XCoverage
//
//  Created by Tyler Mann on 3/10/15.
//  Copyright (c) 2015 Dropbox, Inc
//

#import "COVCoverage.h"
#import "COVCoverageHelpers.h"
#import "COVHighlightView.h"
#import "COVCoverageMap.h"
#import <AppKit/AppKit.h>

static NSString *const COVManualSearchLocation = @"XCoverage-COVManualSearchLocation";

@implementation COVCoverage
{
    BOOL _enabled;
    COVPreviousLocationContext *_previousLocationContext;
    dispatch_queue_t _serialQueue;

    // Need to be cleared on disable
    NSMutableArray *_highlightViews;
    NSArray *_observers;
    NSTextView *_textView;
    NSURL *_currentFileURL;

    NSMenuItem *_manualLocationMenuItem;
    NSMenuItem *_autoLocationMenuItem;
}

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static COVCoverage *s_sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            s_sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

// For debugging
/*
- (void)cov_listenToAllNotifications:(BOOL)shouldListen
{
    if (shouldListen) {
        if (!_allNotificationListener) {
            _allNotificationListener = [[NSNotificationCenter defaultCenter] addObserverForName:nil object:nil queue:nil usingBlock:^(NSNotification *note) {
                if (![[note name] hasPrefix:@"NS"] && ![[note name] hasPrefix:@"_NS"]) {
                    COVLog(@"Received: %@", note.name);
                }
            }];
        }
    } else {
        if (_allNotificationListener) {
            [[NSNotificationCenter defaultCenter] removeObserver:_allNotificationListener];
            _allNotificationListener = nil;
        }
    }
}
*/

- (instancetype)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("XCoverageQueue", DISPATCH_QUEUE_SERIAL);
        _previousLocationContext = [[COVPreviousLocationContext alloc] init];

        [self cov_addMenuItems];
    }
    return self;
}

- (void)dealloc
{
    [self cov_removeObservers];
}

#pragma mark - Enable/disable

- (void)cov_togglePluginEnabled
{
    if (!_enabled) {
        // Enabling
        NSTextView *textView = [COVCoverageHelpers currentTextView];
        [self cov_updateCoverageHighlightWithTextView:textView];
        [self cov_addObservers];
    } else {
        // Disabling
        [self cov_removeObservers];
        [self cov_removeHighlightViews];
        _textView = nil;
        _currentFileURL = nil;
    }

    // Toggle
    _enabled = !_enabled;
}

- (void)cov_removeObservers
{
    for (id observer in _observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

- (void)cov_addObservers
{
    __weak COVCoverage *weakSelf = self;
    NSMutableArray *observers = [@[] mutableCopy];
    [observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:NSTextViewDidChangeSelectionNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf cov_updateCoverageHighlightFromFirstResponder];
    }]];
    [observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf cov_updateCoverageHighlightFromFirstResponder];
    }]];
    [observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf cov_updateCoverageHighlightFromFirstResponder];
    }]];
    [observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:@"IDEControlGroupDidChangeNotificationName" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf cov_updateCoverageHighlightFromFirstResponder];
    }]];
    _observers = observers;
}

#pragma mark - Menu items

- (void)cov_addMenuItems
{
    NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:@"View"];

    // Add separator
    [[viewMenuItem submenu] addItem:[NSMenuItem separatorItem]];

    // Add Main menu to the viewMenu
    NSString *versionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSMenuItem *coverageMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"XCoverage (%@)", versionString]
                                                            action:nil
                                                     keyEquivalent:@""];
    [[viewMenuItem submenu] addItem:coverageMenuItem];

    // Add the second-level coverage container Menu
    NSMenu *coverageMenu = [[NSMenu alloc] initWithTitle:@"Coverage"];
    coverageMenu.autoenablesItems = NO;
    coverageMenuItem.submenu = coverageMenu;

    // Add 'Show Coverage' toggle
    NSMenuItem *toggleItem = [[NSMenuItem alloc] initWithTitle:@"Show Coverage" action:@selector(cov_showCoverage:) keyEquivalent:@"\\"];
    toggleItem.keyEquivalentModifierMask = NSShiftKeyMask | NSCommandKeyMask;
    toggleItem.target = self;
    [coverageMenu addItem:toggleItem];

    // Add separator
    [coverageMenu addItem:[NSMenuItem separatorItem]];

    // Add location menu
    _manualLocationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Set Location (Faster)" action:@selector(cov_setLocation:) keyEquivalent:@""];
    _manualLocationMenuItem.target = self;
    [coverageMenu addItem:_manualLocationMenuItem];

    // Add auto-location menu
    _autoLocationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Auto location" action:@selector(cov_enableAutoLocation:) keyEquivalent:@""];
    _autoLocationMenuItem.target = self;
    [coverageMenu addItem:_autoLocationMenuItem];

    [self cov_updateLocationState];
}

- (NSURL *)cov_manualLocation
{
    return [[NSUserDefaults standardUserDefaults] URLForKey:COVManualSearchLocation];
}

- (void)cov_setManualLocation:(NSURL *)location
{
    if (!location) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:COVManualSearchLocation];
    } else {
        [[NSUserDefaults standardUserDefaults] setURL:location forKey:COVManualSearchLocation];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cov_showCoverage:(NSMenuItem *)sender
{
    COVLog(@"Show coverage tapped.");
    NSInteger prevState = sender.state;
    sender.state = (prevState == NSOffState) ? NSOnState : NSOffState;
    [self cov_togglePluginEnabled];
}

- (void)cov_updateLocationState
{
    BOOL isAuto = [self cov_manualLocation] == nil;
    _autoLocationMenuItem.state = isAuto ? NSOnState : NSOffState;
    _manualLocationMenuItem.state = isAuto ? NSOffState : NSOnState;
}

- (void)cov_showInvalidLocationAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid location" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The location you entered is not a directory."];
    [alert runModal];
}

- (void)cov_setLocation:(NSMenuItem *)sender
{
    COVLog(@"Set location tapped.");
    // Add alert picker?
    NSAlert *alert = [NSAlert alertWithMessageText:@"Set Manual Location" defaultButton:@"Ok" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Please enter a location (directory) that you would like to use for recursively finding .gcov files."];
    NSTextField *textInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 500, 48)];
    textInput.stringValue = [[self cov_manualLocation] path] ?: @"";
    alert.accessoryView = textInput;

    NSString *location = nil;

    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [textInput validateEditing];
        location = [textInput stringValue];

        COVLog(@"location: %@", location);

        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:location isDirectory:&isDirectory] && isDirectory) {
            [self cov_setManualLocation:[NSURL URLWithString:location]];
        } else {
            [self cov_setManualLocation:nil];
            [self cov_showInvalidLocationAlert];
        }

        [self cov_updateLocationState];
    } else if (button == NSAlertAlternateReturn) {
        location = nil;
    }
}

- (void)cov_enableAutoLocation:(NSMenuItem *)sender
{
    COVLog(@"Auto location tapped.");

    [self cov_setManualLocation:nil];
    [self cov_updateLocationState];
}

#pragma mark - Coverage updating


- (void)cov_addHighlightingToTextView:(NSTextView *)textView coverageMap:(NSDictionary *)coverageMap
{

    NSUInteger index = 0;
    NSUInteger stringLength = [textView.string length];
    NSUInteger lineNumber = 1;
    while (index < stringLength) {
        lineNumber++;
        index = NSMaxRange([textView.string lineRangeForRange:NSMakeRange(index, 0)]);

        CGRect frame = [COVCoverage cov_frameFromTextView:textView index:index];
        if ([coverageMap[@(lineNumber)] isEqualToString:COVCoverageTypeNotCovered]) {

            [self cov_addHighlightViewWithFrame:frame color:[[NSColor redColor] colorWithAlphaComponent:0.25]];
        } else if ([coverageMap[@(lineNumber)] isEqualToString:COVCoverageTypeCovered]) {
            NSColor *mintGreenColor = [NSColor colorWithHue:.49 saturation:.50 brightness:.65 alpha:0.25];
            [self cov_addHighlightViewWithFrame:frame color:mintGreenColor];
        }
    }
}

- (void)cov_addHighlightViewWithFrame:(CGRect)frame color:(NSColor *)color
{
    if (!_highlightViews) {
        _highlightViews = [[NSMutableArray alloc] init];
    }

    COVHighlightView *highlightView = [[COVHighlightView alloc] initWithFrame:frame color:color];
    [_highlightViews addObject:highlightView];
    [_textView addSubview:highlightView];
}

+ (CGRect)cov_frameFromTextView:(NSTextView *)textView index:(NSUInteger)index
{

    NSRange startLineRange = [textView.string lineRangeForRange:NSMakeRange(index, 0)];
    NSInteger er = NSMaxRange(startLineRange) - 1;
    if (er < startLineRange.location) {
        er = startLineRange.location;
    }

    NSRange endLineRange = [textView.string lineRangeForRange:NSMakeRange(er, 0)];
    NSRange highlightRange = NSMakeRange(startLineRange.location, NSMaxRange(endLineRange) - startLineRange.location - 1);
    NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:highlightRange
                                                        actualCharacterRange:NULL];
    NSRect glyphRect = [textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                         inTextContainer:textView.textContainer];
    return glyphRect;
}

- (void)cov_removeHighlightViews
{
    for (COVHighlightView *view in _highlightViews) {
        [view removeFromSuperview];
    }
    _highlightViews = nil;
}

- (void)cov_updateCoverageHighlightFromFirstResponder
{
    id firstResponder = [[NSApp keyWindow] firstResponder];
    if (![firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        return;
    }

    NSTextView *textView = firstResponder;
    [self cov_updateCoverageHighlightWithTextView:textView];
}

- (void)cov_updateCoverageHighlightWithTextView:(NSTextView *)textView
{
    NSURL *currentURL = [COVCoverageHelpers currentFileURL];
    if (!currentURL || [currentURL isEqual:_currentFileURL]) {
        return;
    }
    _currentFileURL = currentURL;
    if (!currentURL) {
        return;
    }
    NSURL *manualLocation = [self cov_manualLocation];
    dispatch_async(_serialQueue, ^{
        NSURL *url = nil;
        if (manualLocation) {
            COVLog(@"Doing a manual search.");
            url = [COVCoverageHelpers findCoverageFileForSourceFile:currentURL manualSearchDirectory:manualLocation];
        } else {
            COVLog(@"Doing an auto search.");
            url = [COVCoverageHelpers automaticallyFindCoverageFileForSourceFile:currentURL withPreviousLocationContext:_previousLocationContext];
        }
        NSDictionary *coverageMap = [COVCoverageMap coverageMapForURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![_currentFileURL isEqual:currentURL]) {
                // If the _currentFileURL has already change then we should not update this data
                return;
            }
            _textView = textView;
            [self cov_removeHighlightViews];
            [self cov_addHighlightingToTextView:_textView coverageMap:coverageMap];
        });
    });

}


@end
