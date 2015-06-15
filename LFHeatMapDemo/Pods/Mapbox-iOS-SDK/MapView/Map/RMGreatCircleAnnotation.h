//
//  RMGreatCircleAnnotation.h
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

/** An RMGreatCircleAnnotation class represents a line shape that traces the shortest path along the surface of the Earth. You specify a great circle (also known as a geodesic polyline) using a pair of points. When displayed on a two-dimensional map view, the line segment between the two points may appear curved. */
@interface RMGreatCircleAnnotation : RMShapeAnnotation

/** Initialize a great circle annotation using the specified coordinates.
*   @param aMapView The map view on which to place the annotation.
*   @param coordinate1 The starting coordinate.
*   @param coordinate2 The ending coordinate. 
*   @return An initialized great circle annotation object, or `nil` if an annotation was unable to be initialized. */
- (id)initWithMapView:(RMMapView *)aMapView coordinate1:(CLLocationCoordinate2D)coordinate1 coordinate2:(CLLocationCoordinate2D)coordinate2;

/** The starting coordinate of the annotation. */
@property (nonatomic, readonly, assign) CLLocationCoordinate2D coordinate1;

/** The ending coordinate of the annotation. */
@property (nonatomic, readonly, assign) CLLocationCoordinate2D coordinate2;

@end
