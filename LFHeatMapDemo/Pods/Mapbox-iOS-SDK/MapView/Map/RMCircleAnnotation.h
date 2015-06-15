//
//  RMCircleAnnotation.h
//  MapView
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

#import "RMShapeAnnotation.h"

/** An RMCircleAnnotation is a concrete subclass of RMShapeAnnotation that is used to represent a circle shape on the map. The annotation will automatically have a layer created when needed that displays an RMCircle.
*
*   If you wish to customize the layer appearance in more detail, you should instead create an RMAnnotation and configure its layer directly. Providing a layer manually for instances of RMCircleAnnotation will not have any effect. */
@interface RMCircleAnnotation : RMShapeAnnotation

/** Initialize a circle annotation.
*   @param aMapView The map view on which to place the annotation.
*   @param centerCoordinate The center of the annotation. 
*   @param radiusInMeters The radius of the circle in projected meters.
*   @return An initialized circle annotation object, or `nil` if an annotation was unable to be initialized. */
- (id)initWithMapView:(RMMapView *)aMapView centerCoordinate:(CLLocationCoordinate2D)centerCoordinate radiusInMeters:(CGFloat)radiusInMeters;

/** The circle annotation's center coordinate. */
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;

/** The circle annotation's line width. */
@property (nonatomic, assign) CGFloat lineWidthInPixels;

/** The radius of the circle annotation in projected meters. Regardless of map zoom, the circle will change visible size to continously represent this radius on the map. */
@property (nonatomic, assign) CGFloat radiusInMeters;

@end
