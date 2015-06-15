//
//  RMShapeAnnotation.h
//  MapView
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import "RMAnnotation.h"

/** An RMShapeAnnotation is an abstract subclass of RMAnnotation that is used to represent a shape consisting of one or more points. You should not create instances of this class directly. Instead, you should create instances of the RMPolylineAnnotation or RMPolygonAnnotation classes. However, you can use the properties of this class to access information about the specific points associated with the line or polygon. 
*
*   Providing a layer manually for instances of RMShapeAnnotation subclasses will not have any effect. */
@interface RMShapeAnnotation : RMAnnotation

/** Initialize a shape annotation.
*   @param aMapView The map view on which to place the annotation.
*   @param points An array of CLLocation points defining the shape. The data in this array is copied to the new object.
*   @return An initialized shape annotation object, or `nil` if an annotation was unable to be initialized. */
- (id)initWithMapView:(RMMapView *)aMapView points:(NSArray *)points;

/** The array of points associated with the shape. (read-only) */
@property (nonatomic, readonly, strong) NSArray *points;

/** A line color for the annotation's shape. */
@property (nonatomic, strong) UIColor *lineColor;

/** A line width for the annotation's shape. */
@property (nonatomic, assign) CGFloat lineWidth;

/** A fill color for the annotation's shape. */
@property (nonatomic, strong) UIColor *fillColor;

@end
