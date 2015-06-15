//
//  RMAnnotation.h
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

#import "RMFoundation.h"

#define kRMTrackingHaloAnnotationTypeName   @"RMTrackingHaloAnnotation"
#define kRMAccuracyCircleAnnotationTypeName @"RMAccuracyCircleAnnotation"

@class RMMapView, RMMapLayer, RMQuadTreeNode;

/** An RMAnnotation defines a container for annotation data to be placed on a map. At a future point in time, depending on map use, a visible layer may be requested and displayed for the annotation. The layer is provided by an RMMapView's delegate when first needed for display. 
*
*   Subclasses of RMAnnotation such as RMPointAnnotation, RMPolylineAnnotation, and RMPolygonAnnotation are useful for simple needs such as easily putting points and shapes onto a map view. They manage their own layer and don't require configuration in the map view delegate in order to be displayed. */
@interface RMAnnotation : NSObject
{
    CLLocationCoordinate2D coordinate;
    NSString *title;

    CGPoint position;
    RMProjectedPoint projectedLocation;
    RMProjectedRect  projectedBoundingBox;
    BOOL hasBoundingBox;
    BOOL enabled, clusteringEnabled;

    RMMapLayer *layer;
    __weak RMQuadTreeNode *quadTreeNode;

    // provided for storage of arbitrary user data
    id userInfo;
    NSString *annotationType;
    UIImage  *annotationIcon, *badgeIcon;
    CGPoint   anchorPoint;
}

/** @name Configuration Basic Annotation Properties */

/** The annotation's location on the map. */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/** The annotation's title. */
@property (nonatomic, strong) NSString *title;

/** The annotation's subtitle. */
@property (nonatomic, strong) NSString *subtitle;

/** Storage for arbitrary data. */
@property (nonatomic, strong) id userInfo;

/** An arbitrary string representing the type of annotation. Useful for determining which layer to draw for the annotation when requested in the delegate. Cluster annotations, which are automatically created by a map view, will automatically have an annotationType of `RMClusterAnnotation`. */
@property (nonatomic, strong) NSString *annotationType;

/** An arbitrary icon image for the annotation. Useful to pass an image at annotation creation time for use in the layer at a later time. */
@property (nonatomic, strong) UIImage *annotationIcon;
@property (nonatomic, strong) UIImage *badgeIcon;
@property (nonatomic, assign) CGPoint anchorPoint;

/** The annotation's current location on screen relative to the map. Do not set this directly unless during temporary operations such as animations, but rather use the coordinate property to permanently change the annotation's location on the map. */
@property (nonatomic, assign) CGPoint position;

/** The annotation's absolute location on screen taking into account possible map rotation. */
@property (nonatomic, readonly, assign) CGPoint absolutePosition;

@property (nonatomic, assign) RMProjectedPoint projectedLocation; // in projected meters
@property (nonatomic, assign) RMProjectedRect  projectedBoundingBox;
@property (nonatomic, assign) BOOL hasBoundingBox;

/** Whether touch events for the annotation's layer are recognized. Defaults to `YES`. */
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

/** @name Representing an Annotation Visually */

/** An object representing the annotation's visual appearance.
*
*   @see RMMarker
*   @see RMShape
*   @see RMCircle */
@property (nonatomic, strong) RMMapLayer *layer;

/** @name Annotation Clustering */

/** Whether the annotation should be clustered when map view clustering is enabled. Defaults to `YES`. */
@property (nonatomic, assign) BOOL clusteringEnabled;

/** Whether an annotation is an automatically-managed cluster annotation. */
@property (nonatomic, readonly, assign) BOOL isClusterAnnotation;

/** If the annotation is a cluster annotation, returns an array containing the annotations in the cluster. Returns `nil` if the annotation is not a cluster annotation. */
@property (nonatomic, readonly, assign) NSArray *clusteredAnnotations;

@property (nonatomic, weak) RMQuadTreeNode *quadTreeNode;

/** @name Filtering Types of Annotations */

/** Whether the annotation is related to display of the user's location. Useful for filtering purposes when providing annotation layers in the delegate. 
*
*   There are three possible user location annotations, depending on current conditions: the user dot, the pulsing halo, and the accuracy circle. All may have custom layers provided, but if you only want to customize the user dot, you should check that the annotation is a member of the RMUserLocation class in order to ensure that you are altering only the correct annotation layer. */
@property (nonatomic, readonly) BOOL isUserLocationAnnotation;

#pragma mark -

/** @name Initializing Annotations */

/** Create and initialize an annotation. 
*   @param aMapView The map view on which to place the annotation. 
*   @param aCoordinate The location for the annotation. 
*   @param aTitle The annotation's title. 
*   @return An annotation object, or `nil` if an annotation was unable to be created. */
+ (instancetype)annotationWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle;

/** Initialize an annotation. 
*   @param aMapView The map view on which to place the annotation. 
*   @param aCoordinate The location for the annotation.
*   @param aTitle The annotation's title. 
*   @return An initialized annotation object, or `nil` if an annotation was unable to be initialized. */
- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle;

- (void)setBoundingBoxCoordinatesSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast;
- (void)setBoundingBoxFromLocations:(NSArray *)locations;

#pragma mark -

/** @name Querying Annotation Visibility */

/** Whether the annotation is currently on the screen, regardless if clustered or not. */
@property (nonatomic, readonly) BOOL isAnnotationOnScreen;

/** Whether the annotation is within a certain screen bounds. 
*   @param bounds A given screen bounds. */
- (BOOL)isAnnotationWithinBounds:(CGRect)bounds;

/** Whether the annotation is currently visible on the screen. An annotation is not visible if it is either offscreen or currently in a cluster. */
@property (nonatomic, readonly) BOOL isAnnotationVisibleOnScreen;

#pragma mark -

- (void)setPosition:(CGPoint)position animated:(BOOL)animated;

#pragma mark -

// Used internally
@property (nonatomic, weak) RMMapView *mapView;

@end
