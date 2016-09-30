//
//  RMMapView.h
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
#import <CoreGraphics/CGGeometry.h>

#import "RMGlobalConstants.h"
#import "RMFoundation.h"
#import "RMMapViewDelegate.h"
#import "RMTile.h"
#import "RMProjection.h"
#import "RMMapOverlayView.h"
#import "RMMapTiledLayerView.h"
#import "RMMapScrollView.h"
#import "RMTileSourcesContainer.h"

@class RMProjection;
@class RMFractalTileProjection;
@class RMTileCache;
@class RMMapLayer;
@class RMMapTiledLayerView;
@class RMMapScrollView;
@class RMMarker;
@class RMAnnotation;
@class RMQuadTree;
@class RMUserLocation;

// constants for the scrollview deceleration mode
typedef enum : NSUInteger {
    RMMapDecelerationNormal = 0,
    RMMapDecelerationFast   = 1, // default
    RMMapDecelerationOff    = 2
} RMMapDecelerationMode;

/** An RMMapView object provides an embeddable map interface, similar to the one provided by Apple's MapKit. You use this class to display map information and to manipulate the map contents from your application. You can center the map on a given coordinate, specify the size of the area you want to display, and annotate the map with custom information.
*
*   @warning Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use. */
@interface RMMapView : UIView

/** @name Accessing the Delegate */

/** The receiver's delegate.
*
*   A map view sends messages to its delegate regarding the loading of map data and changes in the portion of the map being displayed. The delegate also manages the annotation layers used to highlight points of interest on the map.
*
*   The delegate should implement the methods of the RMMapViewDelegate protocol. */
@property (nonatomic, weak) IBOutlet id <RMMapViewDelegate>delegate;

#pragma mark - View properties

/** @name Configuring Map Behavior */

/** A Boolean value that determines whether the user may scroll around the map.
*
*   This property controls only user interactions with the map. If you set the value of this property to `NO`, you may still change the map location programmatically.
*
*   The default value of this property is `YES`. */
@property (nonatomic, assign) BOOL draggingEnabled;

/** A Boolean value that determines whether the map view bounces past the edge of content and back again and whether it animates the content scaling when the scaling exceeds the maximum or minimum limits.
*
*   If the value of this property is `YES`, the map view bounces when it encounters a boundary of the content or when zooming exceeds either the maximum or minimum limits for scaling. Bouncing visually indicates that scrolling or zooming has reached an edge of the content. If the value is `NO`, scrolling and zooming stop immediately at the content boundary without bouncing.
*
*   The default value is `NO`. */
@property (nonatomic, assign) BOOL bouncingEnabled;

/** A Boolean value that determines whether double-tap zooms of the map always zoom on the center of the map, or whether they zoom on the center of the double-tap gesture. The default value is `NO`, which zooms on the gesture. */
@property (nonatomic, assign) BOOL zoomingInPivotsAroundCenter;

/** A custom deceleration mode for the map view for drag operations. Set to `RMMapDecelerationOff` to disable map drag deceleration. The default value is `RMMapDecelerationFast`. */
@property (nonatomic, assign) RMMapDecelerationMode decelerationMode;

@property (nonatomic, assign)   double metersPerPixel;
@property (nonatomic, readonly) double scaledMetersPerPixel;
@property (nonatomic, readonly) double scaleDenominator; // The denominator in a cartographic scale like 1/24000, 1/50000, 1/2000000.
@property (nonatomic, readonly) float screenScale;

/** @name Supporting Retina Displays */

/** A Boolean value that adjusts the display of map tile images for retina-capable screens.
*
*   If set to `YES`, the map tiles are drawn at double size, typically 512 pixels square instead of 256 pixels, in order to compensate for smaller features and to make them more legible. If tiles designed for retina devices are used, this value should be set to `NO` in order to display these tiles at the proper size. The default value is `NO`. */
@property (nonatomic, assign)   BOOL adjustTilesForRetinaDisplay;

@property (nonatomic, readonly) float adjustedZoomForRetinaDisplay; // takes adjustTilesForRetinaDisplay and screen scale into account

/** @name Attributing Map Data */

/** Whether to hide map data attribution for the map view.
*
*   If this is set to NO, a small disclosure button will be added to the lower-right of the map view, allowing the user to tap it to display a modal view showing map data attribution info. The modal presentation uses a page curl animation to reveal the attribution info under the map view.
*
*   The default value is NO, meaning that attribution info will be shown. Please ensure that the terms & conditions of any map data used in your application are satisfied before setting this value to YES. */
@property (nonatomic, assign) BOOL hideAttribution;

/** @name Fine-Tuning the Map Appearance */

/** Take missing tiles from lower-numbered zoom levels, up to a given number of zoom levels. This can be used in order to increase perceived tile load performance or to allow zooming in beyond levels supported natively by a given tile source. Defaults to 1. */
@property (nonatomic, assign) NSUInteger missingTilesDepth;

/** A custom, static view to use behind the map tiles. The default behavior is to use grid imagery that moves with map panning like MapKit. */
@property (nonatomic, strong) UIView *backgroundView;

/** A custom image to use behind the map tiles. The default behavior is to show the default `backgroundView` and not a static image. 
*
*   @param backgroundImage The image to use. */
- (void)setBackgroundImage:(UIImage *)backgroundImage;

/** A Boolean value indicating whether to draw tile borders and z/x/y numbers on tile images for debugging purposes. Defaults to `NO`. */
@property (nonatomic, assign) BOOL debugTiles;

/** A Boolean value indicating whether to show a small logo in the corner of the map view. Defaults to `YES`. */
@property (nonatomic, assign) BOOL showLogoBug;

#pragma mark - Initializers

/** @name Initializing a Map View */

/** Initialize a map view with a given frame. A default watermarked Mapbox map tile source will be used. 
*
*   @param frame The frame with which to initialize the map view. 
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame;

/** Initialize a map view with a given frame and tile source. 
*   @param frame The frame with which to initialize the map view. 
*   @param newTilesource The tile source to use for the map tiles. 
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame andTilesource:(id <RMTileSource>)newTilesource;

/** Designated initializer. Initialize a map view. 
*   @param frame The map view's frame. 
*   @param newTilesource A tile source to use for the map tiles. 
*   @param initialCenterCoordinate The starting map center coordinate.
*   @param initialTileSourceZoomLevel The starting map zoom level, clamped to the zoom levels supported by the tile source(s).
*   @param initialTileSourceMaxZoomLevel The maximum zoom level allowed by the map view, clamped to the zoom levels supported by the tile source(s).
*   @param initialTileSourceMinZoomLevel The minimum zoom level allowed by the map view, clamped to the zoom levels supported by the tile source(s).
*   @param backgroundImage A custom background image to use behind the map instead of the default gridded tile background that moves with the map. 
*   @return An initialized map view, or `nil` if a map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame
      andTilesource:(id <RMTileSource>)newTilesource
   centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
          zoomLevel:(float)initialTileSourceZoomLevel
       maxZoomLevel:(float)initialTileSourceMaxZoomLevel
       minZoomLevel:(float)initialTileSourceMinZoomLevel
    backgroundImage:(UIImage *)backgroundImage;

- (void)setFrame:(CGRect)frame;

+ (UIImage *)resourceImageNamed:(NSString *)imageName;
+ (NSString *)pathForBundleResourceNamed:(NSString *)name ofType:(NSString *)extension;

#pragma mark - Movement

/** @name Panning the Map */

/** The center coordinate of the map view. */
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;

/** The center point of the map represented as a projected point. */
@property (nonatomic, assign) RMProjectedPoint centerProjectedPoint;

/** Set the map center to a given coordinate. 
*   @param coordinate A coordinate to set as the map center. 
*   @param animated Whether to animate the change to the map center. */
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

/** Set the map center to a given projected point. 
*   @param aPoint A projected point to set as the map center. 
*   @param animated Whether to animate the change to the map center. */
- (void)setCenterProjectedPoint:(RMProjectedPoint)aPoint animated:(BOOL)animated;

/** Move the map center by a given delta. 
*   @param delta A `CGSize` by which to move the map center. */
- (void)moveBy:(CGSize)delta;

#pragma mark - Zoom

/** @name Zooming the Map */

// minimum and maximum zoom number allowed for the view. #minZoom and #maxZoom must be within the limits of #tileSource but can be stricter; they are clamped to tilesource limits (minZoom, maxZoom) if needed.

/** The current zoom level of the map. */
@property (nonatomic, assign) float zoom;

/** The minimum zoom level of the map, clamped to the range supported by the tile source(s). */
@property (nonatomic, assign) float minZoom;

/** The maximum zoom level of the map, clamped to the range supported by the tile source(s). */
@property (nonatomic, assign) float maxZoom;

@property (nonatomic, assign) float tileSourcesZoom;
@property (nonatomic, assign) float tileSourcesMinZoom;
@property (nonatomic, assign) float tileSourcesMaxZoom;

@property (nonatomic, assign) RMProjectedRect projectedBounds;
@property (nonatomic, readonly) RMProjectedPoint projectedOrigin;
@property (nonatomic, readonly) RMProjectedSize projectedViewSize;

// recenter the map on #boundsRect, expressed in projected meters
- (void)setProjectedBounds:(RMProjectedRect)boundsRect animated:(BOOL)animated;

/** Set zoom level, optionally with an animation. 
*   @param newZoom The desired zoom level.
*   @param animated Whether to animate the map change. */
- (void)setZoom:(float)newZoom animated:(BOOL)animated;

/** Set both zoom level and center coordinate at the same time, optionally with an animation. 
*   @param newZoom The desired zoom level. 
*   @param newCenter The desired center coordinate. 
*   @param animated Whether to animate the map change. */
- (void)setZoom:(float)newZoom atCoordinate:(CLLocationCoordinate2D)newCenter animated:(BOOL)animated;

/** Zoom the map by a given factor near a certain point. 
*   @param zoomFactor The factor by which to zoom the map. 
*   @param center The point at which to zoom the map. 
*   @param animated Whether to animate the zoom. */
- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center animated:(BOOL)animated;

/** Zoom the map in at the next integral zoom level near a certain point. 
*   @param pivot The point at which to zoom the map. 
*   @param animated Whether to animate the zoom. */
- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;

/** Zoom the map out at the next integral zoom level near a certain point.
*   @param pivot The point at which to zoom the map.
*   @param animated Whether to animate the zoom. */
- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;

/** Zoom the map to a given latitude and longitude bounds. 
*   @param southWest The southwest point to zoom to. 
*   @param northEast The northeast point to zoom to. 
*   @param animated Whether to animate the zoom. */
- (void)zoomWithLatitudeLongitudeBoundsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast animated:(BOOL)animated;

- (float)nextNativeZoomFactor;
- (float)previousNativeZoomFactor;

- (void)setMetersPerPixel:(double)newMetersPerPixel animated:(BOOL)animated;

#pragma mark - Bounds

/** @name Querying the Map Bounds */

/** The smallest bounding box containing the entire map view. */
- (RMSphericalTrapezium)latitudeLongitudeBoundingBox;

/** The smallest bounding box containing a rectangular region of the map view. 
*   @param rect A rectangular region. */
- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxFor:(CGRect) rect;

- (BOOL)tileSourceBoundsContainProjectedPoint:(RMProjectedPoint)point;

/** @name Constraining the Map */

/** Contrain zooming and panning of the map view to a given coordinate boundary.
*   @param southWest The southwest point to constrain to.
*   @param northEast The northeast point to constrain to. */
- (void)setConstraintsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast;

- (void)setProjectedConstraintsSouthWest:(RMProjectedPoint)southWest northEast:(RMProjectedPoint)northEast;

#pragma mark - Snapshots

/** @name Capturing Snapshots of the Map View */

/** Take a snapshot of the map view. 
*
*   By default, the overlay containing any visible annotations is also captured.
*   @return An image depicting the map view. */
- (UIImage *)takeSnapshot;

/** Take a snapshot of the map view. 
*   @param includeOverlay Whether to include the overlay containing any visible annotations. 
*   @return An image depicting the map view. */
- (UIImage *)takeSnapshotAndIncludeOverlay:(BOOL)includeOverlay;

#pragma mark - Annotations

/** @name Annotating the Map */

/** The annotations currently added to the map. Includes user location annotations, if any. */
@property (nonatomic, weak, readonly) NSArray *annotations;

/** The annotations currently visible on the map. May include annotations currently shown in clusters. */
@property (nonatomic, weak, readonly) NSArray *visibleAnnotations;

/** Add an annotation to the map. 
*   @param annotation The annotation to add. */
- (void)addAnnotation:(RMAnnotation *)annotation;

/** Add one or more annotations to the map. 
*   @param annotations An array containing the annotations to add to the map. */
- (void)addAnnotations:(NSArray *)annotations;

/** Remove an annotation from the map. 
*   @param annotation The annotation to remove. */
- (void)removeAnnotation:(RMAnnotation *)annotation;

/** Remove one or more annotations from the map. 
*   @param annotations An array containing the annotations to remove from the map. */
- (void)removeAnnotations:(NSArray *)annotations;

/** Remove all annotations from the map. This does not remove user location annotations, if any. */
- (void)removeAllAnnotations;

/** The relative map position for a given annotation. 
*   @param annotation The annotation for which to return the current position.
*   @return The screen position of the annotation. */
- (CGPoint)mapPositionForAnnotation:(RMAnnotation *)annotation;

/** Selects the specified annotation and displays a callout view for it.
*
*   If the specified annotation is not onscreen, and therefore does not have an associated annotation layer, this method has no effect.
*   @param annotation The annotation object to select.
*   @param animated If `YES`, the callout view is animated into position. */
- (void)selectAnnotation:(RMAnnotation *)annotation animated:(BOOL)animated;

/** Deselects the specified annotation and hides its callout view.
*   @param annotation The annotation object to deselect.
*   @param animated If `YES`, the callout view is animated offscreen. */
- (void)deselectAnnotation:(RMAnnotation *)annotation animated:(BOOL)animated;

/** The annotation that is currently selected. */
@property (nonatomic, strong) RMAnnotation *selectedAnnotation;

#pragma mark - TileSources

@property (nonatomic, strong) RMQuadTree *quadTree;

/** @name Configuring Annotation Clustering */

/** Whether to enable clustering of map point annotations. Defaults to `NO`. */
@property (nonatomic, assign) BOOL clusteringEnabled;

/** Whether to order markers on the z-axis according to increasing y-position. Defaults to `YES`. 
*
*   @warning This property has been deprecated in favor of [RMMapViewDelegate annotationSortingComparatorForMapView:]. */
@property (nonatomic, assign) BOOL orderMarkersByYPosition DEPRECATED_MSG_ATTRIBUTE("use -[RMMapViewDelegate annotationSortingComparatorForMapView:] for annotation sorting");

/** Whether to position cluster markers at the weighted center of the points they represent. If `YES`, position clusters in weighted fashion. If `NO`, position them on a rectangular grid. Defaults to `YES`. */
@property (nonatomic, assign) BOOL positionClusterMarkersAtTheGravityCenter;

/** Whether to order cluster markers above non-clustered markers. Defaults to `YES`. 
*
*   @warning This property has been deprecated in favor of [RMMapViewDelegate annotationSortingComparatorForMapView:]. */
@property (nonatomic, assign) BOOL orderClusterMarkersAboveOthers DEPRECATED_MSG_ATTRIBUTE("use -[RMMapViewDelegate annotationSortingComparatorForMapView:] for annotation sorting");

@property (nonatomic, assign) CGSize clusterMarkerSize;
@property (nonatomic, assign) CGSize clusterAreaSize;

@property (nonatomic, weak, readonly) RMTileSourcesContainer *tileSourcesContainer;

/** @name Managing Tile Sources */

/** The first tile source of a map view, ordered from bottom to top. */
@property (nonatomic, strong) id <RMTileSource> tileSource;

/** All of the tile sources for a map view, ordered bottom to top. */
@property (nonatomic, strong) NSArray *tileSources;

/** Add a tile source to a map view above the current tile sources. 
*   @param tileSource The tile source to add. */
- (void)addTileSource:(id <RMTileSource>)tileSource;

/** Add a tile source to a map view at a given index. 
*   @param tileSource The tile source to add. 
*   @param index The index at which to add the tile source. A value of zero adds the tile source below all other tile sources. */
- (void)addTileSource:(id<RMTileSource>)tileSource atIndex:(NSUInteger)index;

/** Remove a tile source from the map view. 
*   @param tileSource The tile source to remove. */
- (void)removeTileSource:(id <RMTileSource>)tileSource;

/** Remove the tile source at a given index from the map view. 
*   @param index The index of the tile source to remove. */
- (void)removeTileSourceAtIndex:(NSUInteger)index;

/** Move the tile source at one index to another index. 
*   @param fromIndex The index of the tile source to move. 
*   @param toIndex The destination index for the tile source. */
- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/** Hide or show a tile source. 
*   @param isHidden A Boolean indicating whether to hide the tile source or not. 
*   @param tileSource The tile source to hide or show. */
- (void)setHidden:(BOOL)isHidden forTileSource:(id <RMTileSource>)tileSource;

/** Hide or show a tile source at a given index. 
*   @param isHidden A Boolean indicating whether to hide the tile source or not.
*   @param index The index of the tile source to hide or show. */
- (void)setHidden:(BOOL)isHidden forTileSourceAtIndex:(NSUInteger)index;

/** Change a tile source's alpha value.
*   @param alpha The desired alpha value.
*   @param tileSource The tile source to change. */
- (void)setAlpha:(CGFloat)alpha forTileSource:(id <RMTileSource>)tileSource;

/** Change the alpha value of a tile source at a given index.
*   @param alpha The desired alpha value.
*   @param index The index of the tile source to change. */
- (void)setAlpha:(CGFloat)alpha forTileSourceAtIndex:(NSUInteger)index;

/** Reload the tiles for a given tile source. 
*   @param tileSource The tile source to reload. */
- (void)reloadTileSource:(id <RMTileSource>)tileSource;

/** Reload the tiles for a tile source at a given index. 
*   @param index The index of the tile source to reload. */
- (void)reloadTileSourceAtIndex:(NSUInteger)index;

#pragma mark - Cache

/** @name Managing Tile Caching Behavior */

/** The tile cache for the map view, typically composed of both an in-memory RMMemoryCache and a disk-based RMDatabaseCache. */
@property (nonatomic, strong)   RMTileCache *tileCache;

/** Clear all tile images from the caching system. */
-(void)removeAllCachedImages;

#pragma mark - Conversions

// projections to convert from latitude/longitude to meters, from projected meters to tile coordinates
@property (nonatomic, weak, readonly) RMProjection *projection;
@property (nonatomic, weak, readonly) id <RMMercatorToTileProjection> mercatorToTileProjection;

/** @name Converting Map Coordinates */

/** Convert a projected point to a screen location. 
*   @param projectedPoint The projected point to convert. 
*   @return The equivalent screen location. */
- (CGPoint)projectedPointToPixel:(RMProjectedPoint)projectedPoint;

/** Convert a coordinate to a screen location. 
*   @param coordinate The coordinate to convert. 
*   @return The equivalent screen location. */
- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)coordinate;

/** Convert a screen location to a projected point. 
*   @param pixelCoordinate A screen location to convert.
*   @return The equivalent projected point. */
- (RMProjectedPoint)pixelToProjectedPoint:(CGPoint)pixelCoordinate;

/** Convert a screen location to a coordinate.
*   @param pixelCoordinate A screen location to convert. 
*   @return The equivalent coordinate. */
- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)pixelCoordinate;

/** Convert a coordiante to a projected point. 
*   @param coordinate A coordinate to convert. 
*   @return The equivalent projected point. */
- (RMProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)coordinate;

/** Convert a projected point to a coordinate. 
*   @param projectedPoint A projected point to convert. 
*   @return The equivalent coordinate. */
- (CLLocationCoordinate2D)projectedPointToCoordinate:(RMProjectedPoint)projectedPoint;

- (RMProjectedSize)viewSizeToProjectedSize:(CGSize)screenSize;
- (CGSize)projectedSizeToViewSize:(RMProjectedSize)projectedSize;

- (CLLocationCoordinate2D)normalizeCoordinate:(CLLocationCoordinate2D)coordinate;
- (RMTile)tileWithCoordinate:(CLLocationCoordinate2D)coordinate andZoom:(int)zoom;

/** Return the bounding box for a given map tile. 
*   @param aTile A map tile. 
*   @return The bounding box for the tile in the current projection. */
- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxForTile:(RMTile)aTile;

#pragma mark -
#pragma mark User Location

/** @name Tracking the User Location */

/** A Boolean value indicating whether the map may display the user location.
*
*   This property does not indicate whether the user’s position is actually visible on the map, only whether the map view is allowed to display it. To determine whether the user’s position is visible, use the userLocationVisible property. The default value of this property is `NO`.
*
*   Setting this property to `YES` causes the map view to use the Core Location framework to find the current location. As long as this property is `YES`, the map view continues to track the user’s location and update it periodically. 
*
*   On iOS 8 and above, your app must specify a value for `NSLocationWhenInUseUsageDescription` in its `Info.plist` to satisfy the requirements of the underlying Core Location framework when enabling this property. */
@property (nonatomic, assign) BOOL showsUserLocation;

/** The annotation object representing the user’s current location. (read-only) */
@property (nonatomic, readonly) RMUserLocation *userLocation;

/** A Boolean value indicating whether the device’s current location is visible in the map view. (read-only)
*
*   This property uses the horizontal accuracy of the current location to determine whether the user’s location is visible. Thus, this property is `YES` if the specific coordinate is offscreen but the rectangle surrounding that coordinate (and defined by the horizontal accuracy value) is partially onscreen.
*
*   If the user’s location cannot be determined, this property contains the value `NO`. */
@property (nonatomic, readonly, getter=isUserLocationVisible) BOOL userLocationVisible;

/** The mode used to track the user location. */
@property (nonatomic, assign) RMUserTrackingMode userTrackingMode;

/** Whether the map view should display a heading calibration alert when necessary. The default value is `YES`. */
@property (nonatomic, assign) BOOL displayHeadingCalibration;

/** Set the mode used to track the user location. 
*
*   Setting the tracking mode to `RMUserTrackingModeFollow` or `RMUserTrackingModeFollowWithHeading` causes the map view to center the map on that location and begin tracking the user’s location. If the map is zoomed out, the map view automatically zooms in on the user’s location, effectively changing the current visible region.
*
*   On iOS 8 and above, your app must specify a value for `NSLocationWhenInUseUsageDescription` in its `Info.plist` to satisfy the requirements of the underlying Core Location framework when tracking the user location.
*
*   @param mode The mode used to track the user location. 
*   @param animated Whether changes to the map center or rotation should be animated when the mode is changed. */
- (void)setUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated;

@end
