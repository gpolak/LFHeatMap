//
//  RMPolygonAnnotation.h
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

#import "RMShapeAnnotation.h"

/** An RMPolygonAnnotation is a concrete subclass of RMShapeAnnotation that is used to represent a shape consisting of one or more points that define a closed polygon. The points are connected end-to-end in the order they are provided. The first and last points are connected to each other to create the closed shape. The annotation will automatically have a layer created when needed that displays an RMShape.
*
*   When creating a polygon, you can mask out portions of the polygon by specifying one or more interior polygons. Areas that are masked by an interior polygon are not considered part of the polygon’s occupied area. 
*
*   If you wish to customize the layer appearance in more detail, you should instead create an RMAnnotation and configure its layer directly. Providing a layer manually for instances of RMPolygonAnnotation will not have any effect. */
@interface RMPolygonAnnotation : RMShapeAnnotation

/** Initialize a polygon annotation.
*   @param aMapView The map view on which to place the annotation.
*   @param points An array of CLLocation points defining the polygon. The data in this array is copied to the new object.
*   @param interiorPolygons An array of RMPolygonAnnotation objects that define one or more cutout regions for the receiver’s polygon.
*   @return An initialized polygon annotation object, or `nil` if an annotation was unable to be initialized. */
- (id)initWithMapView:(RMMapView *)aMapView points:(NSArray *)points interiorPolygons:(NSArray *)interiorPolygons;

/** The array of polygons nested inside the receiver. (read-only)
*
*   When a polygon is rendered on screen, the area occupied by any interior polygons is masked out and not considered part of the polygon. */
@property (nonatomic, readonly, strong) NSArray *interiorPolygons;

@end
