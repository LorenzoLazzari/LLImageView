//
//  LLImageView.h
//  Version 1.0
//
//  Created by Lorenzo Lazzari on 04/09/13.
//  Copyright (c) 2013 Lorenzo Lazzari . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLImageView : NSView
{
    NSTrackingArea *trackingArea;
    NSPoint previousMousePosition;
    float previousDeltaY;
    BOOL hasDraggedOutside;
    float totDiffX;
    float totDiffY;
}

@property (nonatomic, retain) id viewController;///< The class that manage the view operations.
@property (nonatomic) CGImageRef image;///< Image data reference.
@property (nonatomic) NSSize imageSize;///< The size of image in pixel.
@property (nonatomic, retain) NSDictionary *imageProperties;///< Properties of image.
@property (nonatomic) float zoomFactor;///< The actual zoom of the image.
@property (nonatomic) NSPoint imageCenterPoint;///< The point of the image that you want to display in the center.
@property (nonatomic) NSPoint mousePosition;///< The last mouse position in image taked from an event.
@property (nonatomic) BOOL isPanning;///< YES if image is dragging.
@property (nonatomic) BOOL isMouseInside;///< YES if mouse is inside view.
@property (nonatomic) BOOL canClientZoom;///< YES if the user can zoom with scroll wheel
@property (nonatomic) float minZoom;///< Minimum zoom value is equal to the zoom at zoomImageToFit:

- (void)setImage:(CGImageRef)image imageProperties:(NSDictionary *)metaData;

#pragma Mark - Zooming
- (void)zoomImageToFit:(id)sender;
- (void)zoomImageToActualSize:(id)sender;
- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;

#pragma Mark - Coordinates conversion
- (NSPoint)convertViewPointToImagePoint:(NSPoint)viewPoint;
- (NSRect)convertViewRectToImageRect:(NSRect)viewRect;
- (NSPoint)convertImagePointToViewPoint:(NSPoint)imagePoint;
- (NSRect)convertImageRectToViewRect:(NSRect)imageRect;

#pragma Mark - Mouse tracking
- (void)updateTrackingAreas:(NSRect)area;
- (BOOL)acceptsFirstResponder;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)scrollWheel:(NSEvent *)theEvent;
- (void)otherMouseDown:(NSEvent *)theEvent;
- (void)otherMouseUp:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)otherMouseDragged:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;


@end
