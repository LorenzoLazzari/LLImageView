//
//  LLImageView.m
//  Version 1.0
//
//  Created by Lorenzo Lazzari on 04/09/13.
//  Copyright (c) 2013 Lorenzo Lazzari. All rights reserved.
//

#import "LLImageView.h"

#define ZOOM_IN_FACTOR sqrt(2)
#define ZOOM_OUT_FACTOR (1.0 / sqrt(2))
#define PAD_FACTOR_IN 1.090507732665258
#define PAD_FACTOR_OUT 0.91700404320467

@implementation LLImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _zoomFactor = 1;
        _isMouseInside = NO;
        _isPanning = NO;
        _canClientZoom = YES;
        previousDeltaY = 0;
        previousMousePosition = CGPointMake(-1, -1);
        hasDraggedOutside = NO;
        totDiffX = totDiffY = 0;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    if (_zoomFactor >= 1) {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    } else if (_zoomFactor >= 0.45) {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationLow];
    } else {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationMedium];
    }
    
    NSRect imageFrame = [self getImageFrameFromBouds:self.bounds];
    CGContextSetRGBFillColor(context, 156/255.0, 156/255.0, 156/255.0, 1);
    CGContextFillRect(context, self.bounds);
    CGContextDrawImage(context, imageFrame, _image);
    
    if (_imageSize.width > _imageSize.height) {
        _zoomFactor = imageFrame.size.width / _imageSize.width;
    } else {
        _zoomFactor = imageFrame.size.height / _imageSize.height;
    }
    
}

/**
 Set image reference and his properties. Fit the image with the view.
 @param image Image data reference.
 @param metaData Properties of image.
 */
- (void)setImage:(CGImageRef)image imageProperties:(NSDictionary *)metaData
{
    _image = image;
    _imageProperties = metaData;
    _imageSize = CGSizeMake([[_imageProperties valueForKey:@"PixelWidth"] floatValue], [[_imageProperties valueForKey:@"PixelHeight"] floatValue]);
    [self fitImage];
}

#pragma Mark - Zooming

- (void)zoomImageToFit:(id)sender
{
    [self fitImage];
    _minZoom = _zoomFactor;
    [self setNeedsDisplay:YES];
}

- (void)zoomImageToActualSize:(id)sender
{
    _zoomFactor = 1;
    [self setNeedsDisplay:YES];
}

- (void)zoomIn:(id)sender
{
    _zoomFactor *= ZOOM_IN_FACTOR;
    [self setNeedsDisplay:YES];
}

- (void)zoomOut:(id)sender
{
    _zoomFactor *= ZOOM_OUT_FACTOR;
    if (_zoomFactor < _minZoom) {
        [self zoomImageToFit:self];
        return;
    }
    [self setNeedsDisplay:YES];
}

- (void)zoomInFromPad:(id)sender
{
    _zoomFactor *= PAD_FACTOR_IN;
    [self setNeedsDisplay:YES];
}

- (void)zoomOutFromPad:(id)sender
{
    _zoomFactor *= PAD_FACTOR_OUT;
    if (_zoomFactor < _minZoom) {
        [self zoomImageToFit:self];
        return;
    }
    [self setNeedsDisplay:YES];
}

#pragma Mark - Coordinates conversion

- (NSPoint)convertViewPointToImagePoint:(NSPoint)viewPoint
{
    NSView *displayedView = [[NSView alloc] initWithFrame:[self getImageFrameFromBouds:self.bounds]];
    [self addSubview:displayedView];
    NSPoint convertedPoint = [displayedView convertPoint:viewPoint fromView:self];
    
    convertedPoint = CGPointMake(convertedPoint.x / _zoomFactor, convertedPoint.y / _zoomFactor);
    [displayedView removeFromSuperview];
    [displayedView release];
    return convertedPoint;
}

- (NSRect)convertViewRectToImageRect:(NSRect)viewRect
{
    CGPoint origin = [self convertViewPointToImagePoint:viewRect.origin];
    CGPoint end = [self convertViewPointToImagePoint:CGPointMake(viewRect.origin.x + viewRect.size.width, viewRect.origin.y + viewRect.size.height)];
    CGSize newSize = CGSizeMake(end.x - origin.x, end.y - origin.y);
    return CGRectMake(origin.x, origin.y, newSize.width, newSize.height);
}

- (NSPoint)convertImagePointToViewPoint:(NSPoint)imagePoint
{
    NSPoint convertedPoint = CGPointMake(imagePoint.x * _zoomFactor, imagePoint.y * _zoomFactor);
    
    NSView *displayedView = [[NSView alloc] initWithFrame:[self getImageFrameFromBouds:self.bounds]];
    [self addSubview:displayedView];
    convertedPoint = [self convertPoint:convertedPoint fromView:displayedView];
    [displayedView removeFromSuperview];
    [displayedView release];
    return convertedPoint;
}

- (NSRect)convertImageRectToViewRect:(NSRect)imageRect
{
    CGPoint origin = [self convertImagePointToViewPoint:imageRect.origin];
    CGPoint end = [self convertImagePointToViewPoint:CGPointMake(imageRect.origin.x + imageRect.size.width, imageRect.origin.y + imageRect.size.height)];
    CGSize newSize = CGSizeMake(end.x - origin.x, end.y - origin.y);
    return CGRectMake(origin.x, origin.y, newSize.width, newSize.height);
}

#pragma Mark - Mouse tracking

/**
 Update reference area for mouse.
 @param area Reference area. If NSZeroRect take all available area of the image.
 */

- (void)updateTrackingAreas:(NSRect)area
{ 
    if (trackingArea) {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
        trackingArea = nil;
    }

    NSRect eyeBox;
    if (CGRectEqualToRect(area, CGRectZero)) eyeBox = [self bounds];
    else eyeBox = area;
    
    trackingArea = [[NSTrackingArea alloc] initWithRect:eyeBox
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
                                                  owner:self userInfo:nil];
    
    [self addTrackingArea:trackingArea];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([_viewController respondsToSelector:@selector(mouseDown:)]) {
        [_viewController mouseDown:theEvent];
    }
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    
    if (!_canClientZoom) {
        return;
    }

    if ([self isAltKeyDown]) {
        
        float deltaY = [theEvent deltaY];
        NSWindow *mainwindow = [[NSApplication sharedApplication] mainWindow];
        _mousePosition = [self convertViewPointToImagePoint:[self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView]];
        NSPoint viewPoint = [self convertImagePointToViewPoint:_mousePosition];
        
        if (deltaY < previousDeltaY) {
            _imageCenterPoint = _mousePosition;
            [self zoomIn:self];
            NSPoint newImagePoint = [self convertViewPointToImagePoint:viewPoint];
            int diffX = newImagePoint.x - _imageCenterPoint.x;
            int diffY = newImagePoint.y - _imageCenterPoint.y;
            _imageCenterPoint = CGPointMake(_imageCenterPoint.x - diffX, _imageCenterPoint.y - diffY);
            [self setNeedsDisplay:YES];
        } else if (_zoomFactor * ZOOM_OUT_FACTOR > _minZoom){
            _imageCenterPoint = _mousePosition;
            [self zoomOut:self];
            NSPoint newImagePoint = [self convertViewPointToImagePoint:viewPoint];
            int diffX = newImagePoint.x - _imageCenterPoint.x;
            int diffY = newImagePoint.y - _imageCenterPoint.y;
            _imageCenterPoint = CGPointMake(_imageCenterPoint.x - diffX, _imageCenterPoint.y - diffY);
            [self setNeedsDisplay:YES];
        } else {
            [self zoomImageToFit:self];
        }
        previousDeltaY = deltaY;
    }
    previousDeltaY = 0;
    
    if ([_viewController respondsToSelector:@selector(scrollWheel:)]) {
        [_viewController scrollWheel:theEvent];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if ([_viewController respondsToSelector:@selector(otherMouseDown:)]) {
        [_viewController otherMouseDown:theEvent];
    }
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
    _isPanning = NO;
    
    if (hasDraggedOutside) {
        _imageCenterPoint = CGPointMake(_imageCenterPoint.x + totDiffX, _imageCenterPoint.y + totDiffY);
        totDiffX = totDiffY = 0;
        [self setNeedsDisplay:YES];
    }
    
    if ([_viewController respondsToSelector:@selector(otherMouseUp:)]) {
        [_viewController otherMouseUp:theEvent];
    }
    
    previousMousePosition = CGPointMake(-1, -1);
    NSWindow *mainwindow = [[NSApplication sharedApplication] mainWindow];
    _mousePosition = [self convertViewPointToImagePoint:[self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView]];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
    BOOL isUp = NO;
    if ([theEvent magnification] > 0) {
        isUp = YES;
    }

    if (!_canClientZoom) {
        return;
    }

    NSPoint viewPoint = [self convertImagePointToViewPoint:_mousePosition];
    
    if (isUp) {
        _imageCenterPoint = _mousePosition;
        [self zoomInFromPad:self];
        NSPoint newImagePoint = [self convertViewPointToImagePoint:viewPoint];
        int diffX = newImagePoint.x - _imageCenterPoint.x;
        int diffY = newImagePoint.y - _imageCenterPoint.y;
        _imageCenterPoint = CGPointMake(_imageCenterPoint.x - diffX, _imageCenterPoint.y - diffY);
        [self setNeedsDisplay:YES];
    } else if (_zoomFactor * PAD_FACTOR_OUT > _minZoom){
        _imageCenterPoint = _mousePosition;
        [self zoomOutFromPad:self];
        NSPoint newImagePoint = [self convertViewPointToImagePoint:viewPoint];
        int diffX = newImagePoint.x - _imageCenterPoint.x;
        int diffY = newImagePoint.y - _imageCenterPoint.y;
        _imageCenterPoint = CGPointMake(_imageCenterPoint.x - diffX, _imageCenterPoint.y - diffY);
        [self setNeedsDisplay:YES];
    } else {
        [self zoomImageToFit:self];
    }
    
    if ([_viewController respondsToSelector:@selector(scrollWheel:)]) {
        [_viewController scrollWheel:theEvent];
    }

}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([self isAltKeyDown]) {
        _isPanning = YES;
        [self otherMouseDragged:theEvent];
        return;
    }
    
    NSWindow *mainwindow = [[NSApplication sharedApplication] mainWindow];
    _mousePosition = [self convertViewPointToImagePoint:[self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView]];
    
    if ([_viewController respondsToSelector:@selector(mouseDragged:)]) {
        [_viewController mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (hasDraggedOutside) {
        [self otherMouseUp:theEvent];
    }
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
    NSWindow *mainwindow = [[NSApplication sharedApplication] mainWindow];
    _mousePosition = [self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView];
    
    _isPanning = YES;
    
    if (CGPointEqualToPoint(previousMousePosition, CGPointMake(-1, -1))) {
        previousMousePosition = _mousePosition;
    }
    
    float diffX = (_mousePosition.x - previousMousePosition.x) / _zoomFactor;
    float diffY = (_mousePosition.y - previousMousePosition.y) / _zoomFactor;
    
    if (![self canBeImageDraggedAlongX:diffX]) {
        diffX /= 10.0;
        totDiffX += diffX;
        hasDraggedOutside = YES;
    }
    
    if (![self canBeImageDraggedAlongY:diffY]) {
        diffY /= 10.0;
        totDiffY += diffY;
        hasDraggedOutside = YES;
    }
    
    _imageCenterPoint = CGPointMake(_imageCenterPoint.x - diffX, _imageCenterPoint.y - diffY);
    
    previousMousePosition = _mousePosition;
    _mousePosition = [self convertViewPointToImagePoint:[self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView]];
    
    [self setNeedsDisplay:YES];
    if ([_viewController respondsToSelector:@selector(mouseMoved:)]) {
        [_viewController mouseMoved:theEvent];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSWindow *mainwindow = [[NSApplication sharedApplication] mainWindow];
    _mousePosition = [self convertViewPointToImagePoint:[self convertPoint:[theEvent locationInWindow] fromView:mainwindow.contentView]];
    
    if ([_viewController respondsToSelector:@selector(mouseMoved:)]) {
        [_viewController mouseMoved:theEvent];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    _isMouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _isMouseInside = NO;
}

- (void)resetCursorRects
{
    if (_isPanning) {
        [self addCursorRect:self.bounds cursor:[NSCursor closedHandCursor]];
    } else {
        [self addCursorRect:self.bounds cursor:[NSCursor crosshairCursor]];
    }
    
}

#pragma Mark - Utilities

- (NSRect)getImageFrameFromBouds:(NSRect)bounds
{
    float width = 0;
    float height = 0;
    float oX = 0;
    float oY = 0;
    float ratio = _imageSize.width / _imageSize.height;
    
    if (_imageSize.width > _imageSize.height) {
        width = _imageSize.width * _zoomFactor;
        height = width / ratio;
    } else {
        height = _imageSize.height * _zoomFactor;
        width = height * ratio;
    }
    
    NSPoint centerInScale = CGPointMake(_imageCenterPoint.x * _zoomFactor, _imageCenterPoint.y * _zoomFactor);
    
    float dx = self.bounds.size.width / 2 - centerInScale.x;
    float dy = self.bounds.size.height / 2 - centerInScale.y;
    
    oX += dx;
    oY += dy;

    return CGRectMake(round(oX), round(oY), width, height);
}

- (void)fitImage
{
    _imageCenterPoint = CGPointMake(_imageSize.width / 2, _imageSize.height / 2);
    
    if (_imageSize.width > _imageSize.height) {
        _zoomFactor = self.bounds.size.width / _imageSize.width;
    } else {
        _zoomFactor = self.bounds.size.height / _imageSize.height;
    }
    
    if (_imageSize.width * _zoomFactor > self.bounds.size.width) {
        _zoomFactor = self.bounds.size.width / _imageSize.width;
    }
    
    if (_imageSize.height * _zoomFactor > self.bounds.size.height) {
        _zoomFactor = self.bounds.size.height / _imageSize.height;
    }
}

- (BOOL)canBeImageDraggedAlongX:(float)diffX
{
    if (_imageSize.width * _zoomFactor <= self.bounds.size.width || diffX == 0) {
        return NO;
    }
        
    if (diffX > 0) {
        NSPoint checkPoint = [self convertImagePointToViewPoint:CGPointMake(diffX, 0)];
        if (checkPoint.x > 0) {
            return NO;
        }
    } else {
        NSPoint checkPoint = [self convertImagePointToViewPoint:CGPointMake(_imageSize.width + diffX, _imageSize.height)];
        if (checkPoint.x < self.bounds.size.width) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)canBeImageDraggedAlongY:(float)diffY
{
    if (_imageSize.height * _zoomFactor <= self.bounds.size.height || diffY == 0) {
        return NO;
    }
    
    if (diffY > 0) {
        NSPoint checkPoint = [self convertImagePointToViewPoint:CGPointMake(0, diffY)];
        if (checkPoint.y > 0) {
            return NO;
        }
    } else {
        NSPoint checkPoint = [self convertImagePointToViewPoint:CGPointMake(_imageSize.width, _imageSize.height + diffY)];
        if (checkPoint.y < self.bounds.size.height) {
            return NO;
        }
    }
    
    return YES;
}

- (float)firstAvailableDiffX:(float)diffX
{
    if (diffX > 0) {
        NSRect checkRect = [self convertViewRectToImageRect:self.bounds];
        return _imageCenterPoint.x - checkRect.size.width / 2;
    } else {
        NSRect checkRect = [self convertViewRectToImageRect:self.bounds];
        return (_imageCenterPoint.x - _imageSize.width) + checkRect.size.width / 2;
    }
}

- (float)firstAvailableDiffY:(float)diffY
{
    if (diffY > 0) {
        NSRect checkRect = [self convertViewRectToImageRect:self.bounds];
        return _imageCenterPoint.y - checkRect.size.height / 2;
    } else {
        NSRect checkRect = [self convertViewRectToImageRect:self.bounds];
        return (_imageCenterPoint.y - _imageSize.height) + checkRect.size.height / 2;
    }

}

- (BOOL)isAltKeyDown
{
    return ([[NSApp currentEvent] modifierFlags] ==
            524576);
}

@end
