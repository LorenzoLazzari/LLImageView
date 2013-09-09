//
//  AppDelegate.m
//  Example
//
//  Created by Lorenzo on 09/09/13.
//  Copyright (c) 2013 Lorenzo. All rights reserved.
//

#import "AppDelegate.h"
#import "LLImageView.h"

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self openImage:nil];
}

- (void)openImage:(id)sender {

    NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG/PNG/BMP/bmp";
    NSArray *     types = [extensions pathComponents];
    
    // Let the user choose an output file, then start the process of writing samples
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:types/*[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]*/];
    [openPanel setCanSelectHiddenExtension:YES];
    [openPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            // user did select an image...
            
            [self openImageURL: [openPanel URL]];
        }
    }];
}

- (void)openImageURL:(NSURL*)url
{
    CGImageRef          image = NULL;
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (CFURLRef)url, NULL);
    NSDictionary *imageProperties = nil;
    if (isr) {
        image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
        if (image) {
            imageProperties = (NSDictionary*)CGImageSourceCopyPropertiesAtIndex(isr, 0, (CFDictionaryRef)imageProperties);
        }
        CFRelease(isr);
    }
    
    LLImageView *imageController = [[LLImageView alloc] initWithFrame:_window.frame];
    [_window setContentView:imageController];
    [imageController setImage:image imageProperties:imageProperties];
}
    

@end
