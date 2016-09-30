//
//  RMCircle.h
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

#import <Foundation/Foundation.h>
#import "RMFoundation.h"
#import "RMMapLayer.h"

@class RMMapView;

/** An RMCircle is used to represent a perfect circle shape on a map view. An RMCircle changes visible size in response to map zooms in order to consistently represent coverage of the same geographic area. */
@interface RMCircle : RMMapLayer
{
	RMMapView *mapView;
	CAShapeLayer *shapeLayer;

	UIColor *lineColor;
	UIColor *fillColor;
	CGFloat radiusInMeters;
	CGFloat lineWidthInPixels;
	BOOL scaleLineWidth;

	CGMutablePathRef circlePath;
}

/** @name Accessing Drawing Properties */

/** The circle's underlying shape layer. */
@property (nonatomic, strong) CAShapeLayer *shapeLayer;

/** The circle's line color. Defaults to black. */
@property (nonatomic, strong) UIColor *lineColor;

/** The circle's fill color. Defaults to blue with a 25% alpha value. */
@property (nonatomic, strong) UIColor *fillColor;

/** The fill pattern image of the circle. If set, the fillColor is set to `nil`. */
@property (nonatomic, strong) UIImage *fillPatternImage;

/** The radius of the circle in projected meters. Regardless of map zoom, the circle will change visible size to continously represent this radius on the map. */
@property (nonatomic, assign) CGFloat radiusInMeters;

/** The circle's line width. Defaults to 2.0. */
@property (nonatomic, assign) CGFloat lineWidthInPixels;

/** @name Creating Circle Objects */

/** Initializes and returns a newly allocated RMCircle for the specified map view.
*   @param aMapView The map view the shape should be drawn on.
*   @param newRadiusInMeters The radius of the circle object in projected meters. Regardless of map zoom, the circle will change visible size to continously represent this radius on the map. */
- (id)initWithView:(RMMapView *)aMapView radiusInMeters:(CGFloat)newRadiusInMeters;

@end
