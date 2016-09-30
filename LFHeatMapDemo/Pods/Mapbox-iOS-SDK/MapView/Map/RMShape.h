//
//  RMShape.h
//
// Copyright (c) 2008-2013, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import <UIKit/UIKit.h>

#import "RMFoundation.h"
#import "RMMapLayer.h"

@class RMMapView;

/** An RMShape object is used to represent a line, polygon, or other shape composed of two or more points connected by lines. An RMShape object changes visible size in response to map zooms in order to consistently represent coverage of the same geographic area. */
@interface RMShape : RMMapLayer
{
    CGRect pathBoundingBox;

    // Width of the line, in pixels
    float lineWidth;

    // Line dash style
    __weak NSArray *lineDashLengths;
    CGFloat lineDashPhase;

    BOOL scaleLineWidth;
    BOOL scaleLineDash; // if YES line dashes will be scaled to keep a constant size if the layer is zoomed
}

/** @name Creating Shape Objects */

/** Initializes and returns a newly allocated shape object for the specified map view.
*   @param aMapView The map view the shape should be drawn on. */
- (id)initWithView:(RMMapView *)aMapView;

/** @name Accessing the Drawing Properties */

@property (nonatomic, strong) NSString *fillRule;
@property (nonatomic, strong) NSString *lineCap;
@property (nonatomic, strong) NSString *lineJoin;

/** The line color of the shape. Defaults to black. */
@property (nonatomic, strong) UIColor *lineColor;

/** The fill color of the shape. Defaults to clear. */
@property (nonatomic, strong) UIColor *fillColor;

/** The fill pattern image of the shape. If set, the fillColor is set to `nil`. */
@property (nonatomic, strong) UIImage *fillPatternImage;

@property (nonatomic, weak) NSArray *lineDashLengths;
@property (nonatomic, assign) CGFloat lineDashPhase;
@property (nonatomic, assign) BOOL scaleLineDash;

/** The line width of the shape. Defaults to 2.0. */
@property (nonatomic, assign) float lineWidth;

@property (nonatomic, assign) BOOL scaleLineWidth;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) BOOL enableShadow;

/** The bounding box of the shape in the current viewport. */
@property (nonatomic, readonly) CGRect pathBoundingBox;

/** An additional pixel area around the shape that is applied to touch hit testing events. Defaults to none. */
@property (nonatomic, assign) CGFloat additionalTouchPadding;

/** @name Drawing Shapes */

/** Move the drawing pen to a projected point. 
*   @param projectedPoint The projected point to move to. */
- (void)moveToProjectedPoint:(RMProjectedPoint)projectedPoint;

/** Move the drawing pen to a screen point. 
*   @param point The screen point to move to. */
- (void)moveToScreenPoint:(CGPoint)point;

/** Move the drawing pen to a coordinate. 
*   @param coordinate The coordinate to move to. */
- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate;

/** Draw a line from the current pen location to a projected point. 
*   @param projectedPoint The projected point to draw to. */
- (void)addLineToProjectedPoint:(RMProjectedPoint)projectedPoint;

/** Draw a line from the current pen location to a screen point.
*   @param point The screen point to draw to. */
- (void)addLineToScreenPoint:(CGPoint)point;

/** Draw a line from the current pen location to a coordinate.
*   @param coordinate The coordinate to draw to. */
- (void)addLineToCoordinate:(CLLocationCoordinate2D)coordinate;

/** Draw a curve from the current pen location to a coordinate.
*   @param coordinate The coordinate to draw to.
*   @param controlCoordinate1 The first control coordinate.
*   @param controlCoordinate2 The second control coordinate. */
- (void)addCurveToCoordinate:(CLLocationCoordinate2D)coordinate controlCoordinate1:(CLLocationCoordinate2D)controlCoordinate1 controlCoordinate2:(CLLocationCoordinate2D)controlCoordinate2;

/** Draw a quad curve from the current pen location to a coordinate.
*   @param coordinate The coordinate to draw to.
*   @param controlCoordinate The control coordinate. */
- (void)addQuadCurveToCoordinate:(CLLocationCoordinate2D)coordinate controlCoordinate:(CLLocationCoordinate2D)controlCoordinate;

/** Draw a curve from the current pen location to a projected point.
*   @param projectedPoint The projected point to draw to.
*   @param controlProjectedPoint1 The first control projected point.
*   @param controlProjectedPoint2 The second control projected point. */
- (void)addCurveToProjectedPoint:(RMProjectedPoint)projectedPoint controlProjectedPoint1:(RMProjectedPoint)controlProjectedPoint1 controlProjectedPoint2:(RMProjectedPoint)controlProjectedPoint2;

/** Draw a quad curve from the current pen location to a projected point.
*   @param projectedPoint The projected point to draw to.
*   @param controlProjectedPoint The control projected point. */
- (void)addQuadCurveToProjectedPoint:(RMProjectedPoint)projectedPoint controlProjectedPoint:(RMProjectedPoint)controlProjectedPoint;

/** Alter the path without rerecalculating the geometry. Recommended for many operations in order to increase performance. 
*   @param block A block containing the operations to perform. */
- (void)performBatchOperations:(void (^)(RMShape *aShape))block;

/** Closes the path, connecting the last point to the first. After this action, no further points can be added to the path.
*
* There is no requirement that a path be closed. */
- (void)closePath;

@end
