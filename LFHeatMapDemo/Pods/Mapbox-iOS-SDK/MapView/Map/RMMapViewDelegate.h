//
//  RMMapViewDelegate.h
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

@class RMMapView;
@class RMMapLayer;
@class RMMarker;
@class RMAnnotation;
@class RMUserLocation;

typedef enum : NSUInteger {
    RMMapLayerDragStateNone = 0,
    RMMapLayerDragStateStarting,
    RMMapLayerDragStateDragging,
    RMMapLayerDragStateCanceling,
    RMMapLayerDragStateEnding
} RMMapLayerDragState;

typedef enum : NSUInteger {
    RMUserTrackingModeNone              = 0,
    RMUserTrackingModeFollow            = 1,
    RMUserTrackingModeFollowWithHeading = 2
} RMUserTrackingMode;

/** The RMMapViewDelegate protocol defines a set of optional methods that you can use to receive map-related update messages. Because many map operations require the RMMapView class to load data asynchronously, the map view calls these methods to notify your application when specific operations complete. The map view also uses these methods to request annotation layers and to manage interactions with those layers. */
@protocol RMMapViewDelegate <NSObject>
@optional

/** @name Working With Annotation Layers */

/** Returns (after creating or reusing) the layer associated with the specified annotation object. 
*
*   An annotation layer can be created using RMMapLayer and its subclasses, such as RMMarker for points and RMShape for shapes such as lines and polygons.
*
*   If the object in the annotation parameter is an instance of the RMUserLocation class, you can provide a custom layer to denote the user’s location. To display the user’s location using the default system layer, return `nil`.
*
*   If you do not implement this method, or if you return `nil` from your implementation for annotations other than the user location annotation, the map view does not display a layer for the annotation.
*
*   @param mapView The map view that requested the annotation layer.
*   @param annotation The object representing the annotation that is about to be displayed. In addition to your custom annotations, this object could be an RMUserLocation object representing the user’s current location.
*   @return The annotation layer to display for the specified annotation or `nil` if you do not want to display a layer. */
- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation;

/** Returns a block used for determining the display sort order of annotation layers. The block will be called repeatedly during map change events to ensure annotation layers stay sorted in the desired order.
*
*   If you do not implement this method, a default sort order will be used as follows: 
*
*   1. User location annotations are below all others. These can be distinguished by `annotation.isUserLocationAnnotation = YES`.
*
*   1. Amongst user location annotations, the accuracy circle is below the tracking halo, which is below the user location. These can be distinguished by `annotation.annotationType = kRMTrackingHaloAnnotationTypeName`, `annotation.annotationType = kRMAccuracyCircleAnnotationTypeName`, and checking annotation object type against RMUserLocation.
*
*   1. Cluster annotations are above non-cluster annotations. These can be distinguished by `annotation.isClusterAnnotation = YES`. 
*
*   1. Markers are above shapes. These can be distinguished by checking annotation object type against RMMarker. 
*
*   1. The remaining annotations are sorted with those closer to the bottom of the view above those closer to the top of the view. This includes during user tracking mode map rotation events, when markers always remain upright and their relative layer positions change.
*
*   In all cases, any currently selected annotation (and its callout, if visible) are shown above all other annotations. When deselected, the desired sort order is reapplied.
*
*   Your implementation of this method should be as lightweight as possible to avoid affecting map renderering performance. 
*
*   @see [RMAnnotation isUserLocationAnnotation]
*   @see [RMAnnotation annotationType]
*   @see [RMAnnotation isClusterAnnotation]
*   @see [RMMapView coordinateToPixel:]
*
*   @param mapView The map view whose annotations need sorting. 
*   @return A comparison block to use in order to sort the annotations. */
- (NSComparator)annotationSortingComparatorForMapView:(RMMapView *)mapView;

/** Tells the delegate that the visible layer for an annotation is about to be hidden from view due to scrolling or zooming the map.
*   @param mapView The map view whose annotation alyer will be hidden.
*   @param annotation The annotation whose layer will be hidden. */
- (void)mapView:(RMMapView *)mapView willHideLayerForAnnotation:(RMAnnotation *)annotation;

/** Tells the delegate that the visible layer for an annotation has been hidden from view due to scrolling or zooming the map.
*   @param mapView The map view whose annotation layer was hidden.
*   @param annotation The annotation whose layer was hidden. */
- (void)mapView:(RMMapView *)mapView didHideLayerForAnnotation:(RMAnnotation *)annotation;

/** Tells the delegate that one of its annotations was selected.
*
*   You can use this method to track changes in the selection state of annotations.
*   @param mapView The map view containing the annotation.
*   @param annotation The annotation that was selected. */
- (void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation;

/** Tells the delegate that one of its annotations was deselected.
*
*   You can use this method to track changes in the selection state of annotations.
*   @param mapView The map view containing the annotation.
*   @param annotation The annotation that was deselected. */
- (void)mapView:(RMMapView *)mapView didDeselectAnnotation:(RMAnnotation *)annotation;

/** @name Responding to Map Position Changes */

/** Tells the delegate when a map is about to move. 
*   @param map The map view that is about to move.
*   @param wasUserAction A Boolean indicating whether the map move is in response to a user action or not. */
- (void)beforeMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction;

/** Tells the delegate when a map has finished moving. 
*   @param map The map view that has finished moving. 
*   @param wasUserAction A Boolean indicating whether the map move was in response to a user action or not. */
- (void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction;

/** Tells the delegate when a map is about to zoom. 
*   @param map The map view that is about to zoom. 
*   @param wasUserAction A Boolean indicating whether the map zoom is in response to a user action or not. */
- (void)beforeMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction;

/** Tells the delegate when a map has finished zooming. 
*   @param map The map view that has finished zooming. 
*   @param wasUserAction A Boolean indicating whether the map zoom was in response to a user action or not. */
- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction;

/** Tells the delegate that the region displayed by the map view just changed. 
*
*   This method is called whenever the currently displayed map region changes. During scrolling, this method may be called many times to report updates to the map position. Therefore, your implementation of this method should be as lightweight as possible to avoid affecting scrolling performance.
*   @param mapView The map view whose visible region changed. */
- (void)mapViewRegionDidChange:(RMMapView *)mapView;

/** @name Responding to Map Gestures */

/** Tells the delegate when the user double-taps a map view. 
*   @param map The map that was double-tapped. 
*   @param point The point at which the map was double-tapped. */
- (void)doubleTapOnMap:(RMMapView *)map at:(CGPoint)point;

/** Tells the delegate when the user taps a map view.
*   @param map The map that was tapped.
*   @param point The point at which the map was tapped. */
- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point;

/** Tells the delegate when the user taps a map view with two fingers.
*   @param map The map that was tapped.
*   @param point The center point at which the map was tapped. */
- (void)singleTapTwoFingersOnMap:(RMMapView *)map at:(CGPoint)point;

/** Tells the delegate when the user long-presses a map view.
*   @param map The map that was long-pressed.
*   @param point The point at which the map was long-pressed. */
- (void)longPressOnMap:(RMMapView *)map at:(CGPoint)point;

/** @name Responding to User Annotation Gestures */

/** Tells the delegate when the user taps the layer for an annotation. 
*   @param annotation The annotation that was tapped. 
*   @param map The map view. */
- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Tells the delegate when the user double-taps the layer for an annotation.
*   @param annotation The annotation that was double-tapped.
*   @param map The map view. */
- (void)doubleTapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Tells the delegate when the user long-presses the layer for an annotation. 
*   @param annotation The annotation that was long-pressed. 
*   @param map The map view. */
- (void)longPressOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Tells the delegate when the user taps the label for an annotation.
*   @param annotation The annotation whose label was was tapped.
*   @param map The map view. */
- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Tells the delegate when the user double-taps the label for an annotation.
*   @param annotation The annotation whose label was was double-tapped.
*   @param map The map view. */
- (void)doubleTapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Tells the delegate that the user tapped one of the annotation layer's accessory buttons.
*
*   Accessory views contain custom content and are positioned on either side of the annotation title text. If a view you specify is a descendant of the UIControl class, the map view calls this method as a convenience whenever the user taps your view. You can use this method to respond to taps and perform any actions associated with that control. For example, if your control displayed additional information about the annotation, you could use this method to present a modal panel with that information.
*
*   If your custom accessory views are not descendants of the UIControl class, the map view does not call this method.
*   @param control The control that was tapped. 
*   @param annotation The annotation whose callout control was tapped. 
*   @param map The map view containing the specified annotation. */
- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

/** Asks the delegate whether the user should be allowed to drag the layer for an annotation. 
*   @param mapView The map view.
*   @param annotation The annotation the user is attempting to drag. 
*   @return A Boolean value indicating whether the user should be allowed to drag the annotation's layer. */
- (BOOL)mapView:(RMMapView *)mapView shouldDragAnnotation:(RMAnnotation *)annotation;

/** Tells the delegate that the drag state of one of its annotations changed.
*
*   The drag state typically changes in response to user interactions with the annotation layer. However, the annotation layer itself is responsible for changing that state as well.
*   @param mapView The map view containing the annotation layer.
*   @param annotation The annotation whose drag state changed.
*   @param newState The new drag state of the annotation layer. 
*   @param oldState The previous drag state of the annotation layer. */
- (void)mapView:(RMMapView *)mapView annotation:(RMAnnotation *)annotation didChangeDragState:(RMMapLayerDragState)newState fromOldState:(RMMapLayerDragState)oldState;

/** @name Tracking the User Location */

/** Tells the delegate that the map view will start tracking the user’s position.
*
*   This method is called when the value of the showsUserLocation property changes to YES.
*   @param mapView The map view that is tracking the user’s location. */
- (void)mapViewWillStartLocatingUser:(RMMapView *)mapView;

/** Tells the delegate that the map view stopped tracking the user’s location.
*
*   This method is called when the value of the showsUserLocation property changes to NO.
*   @param mapView The map view that stopped tracking the user’s location. */
- (void)mapViewDidStopLocatingUser:(RMMapView *)mapView;

/** Tells the delegate that the location of the user was updated.
*
*   While the showsUserLocation property is set to YES, this method is called whenever a new location update is received by the map view. This method is also called if the map view’s user tracking mode is set to RMUserTrackingModeFollowWithHeading and the heading changes.
*
*   This method is not called if the application is currently running in the background. If you want to receive location updates while running in the background, you must use the Core Location framework.
*   @param mapView The map view that is tracking the user’s location.
*   @param userLocation The location object representing the user’s latest location. */
- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation;

/** Tells the delegate that an attempt to locate the user’s position failed.
*   @param mapView The map view that is tracking the user’s location.
*   @param error An error object containing the reason why location tracking failed. */
- (void)mapView:(RMMapView *)mapView didFailToLocateUserWithError:(NSError *)error;

/** Tells the delegate that the user tracking mode changed.
*   @param mapView The map view whose user tracking mode changed.
*   @param mode The mode used to track the user’s location.
*   @param animated If YES, the change from the current mode to the new mode is animated; otherwise, it is not. This parameter affects only tracking mode changes. Changes to the user location or heading are always animated. */
- (void)mapView:(RMMapView *)mapView didChangeUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated;

@end
