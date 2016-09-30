//
//  RMMapLayer.h
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
#import <QuartzCore/QuartzCore.h>

#import "RMFoundation.h"
#import "RMMapViewDelegate.h"

@class RMAnnotation;

/** RMMapLayer is a generic class for displaying scrollable vector layers on a map view. Generally, a more specialized subclass such as RMMarker will be used for a specific purpose, but RMMapLayer can also be used directly for special purposes. */
@interface RMMapLayer : CAScrollLayer
{
    __weak RMAnnotation *annotation;

    // expressed in projected meters. The anchorPoint of the image/path/etc. is plotted here.
    RMProjectedPoint projectedLocation;

    BOOL draggingEnabled;

    // provided for storage of arbitrary user data
    id userInfo;
}

/** @name Configuring Map Layer Properties */

/** The annotation associated with the layer. This can be useful to inspect the annotation's userInfo in order to customize the visual representation. */
@property (nonatomic, weak) RMAnnotation *annotation;

/** The current projected location of the layer on the map. */
@property (nonatomic, assign) RMProjectedPoint projectedLocation;

/** The current drag state of the annotation layer. 
*
*   To support drag operations, you must override the implementation of this property and update the drag state at the following times:
*
*   When the drag state changes to `RMMapLayerDragStateStarting`, you should set the state to `RMMapLayerDragStateDragging`. If you perform an animation to indicate the beginning of a drag, you should perform that animation before changing the state. Changing the state to the new value lets the map know that your animations are done.
*
*   When the state changes to either `RMMapLayerDragStateCanceling` or `RMMapLayerDragStateEnding`, set the state to `RMMapLayerDragStateNone`. If you perform an animation at the end of a drag, you should perform that animation before changing the state.
*
*   Changing the state to the `RMMapLayerDragStateDragging` or `RMMapLayerDragStateNone` value is the way to signal to the map view that you are done with any animations you wanted to perform. For example, when a drag operation begins for a marker, the RMMarker class executes an animation to lift the marker off the map. Similarly, when the marker is dropped, the class performs a drop animation. Even if you do not perform any animations, you should still change the value of this property to reflect the correct state.
*
*   You must not try to abort a new drag operation by changing the state from `RMMapLayerDragStateStarting` to `RMMapLayerDragStateNone`. If you do not want your annotation layer to be draggable, return `NO` from the map view delegate's implementation of mapView:shouldDragAnnotation:. */
@property (nonatomic, assign) RMMapLayerDragState dragState;

/** Storage for arbitrary data. */
@property (nonatomic, strong) id userInfo;

/** A Boolean value indicating whether the annotation layer is able to display extra information in a callout bubble.
*
*   If the value of this property is `YES`, a standard callout bubble is shown when the user taps the layer. The callout uses the title text from the associated annotation object. If there is no title text, though, the annotation is treated as if its enabled property is set to `NO`. The callout also displays any custom callout views stored in the leftCalloutAccessoryView and rightCalloutAccessoryView properties.
*
*   If the value of this property is `NO`, the value of the title string is ignored and the annotation remains enabled by default. You can still disable the annotation explicitly using the enabled property. 
*
*   Note that callouts are not supported on non-marker or cluster annotation layers. These annotations can be interacted with, but do not remain consistent visually during map pan and zoom events; thus, callout behavior would be inconsistent. */
@property (nonatomic, assign) BOOL canShowCallout;

/** The offset (in pixels) at which to place the callout bubble.
*
*   This property determines the additional distance by which to move the callout bubble. When this property is set to (0, 0), the anchor point of the callout bubble is placed on the top-center point of the annotation view’s frame. Specifying positive offset values moves the callout bubble down and to the right, while specifying negative values moves it up and to the left. */
@property (nonatomic, assign) CGPoint calloutOffset;

/** The view to display on the left side of the standard callout bubble.
*
*   The default value of this property is `nil`. The left callout view is typically used to display information about the annotation or to link to custom information provided by your application. The height of your view should be 32 pixels or less.
*
*   If the view you specify is also a descendant of the UIControl class, you can use the map view’s delegate to receive notifications when your control is tapped. If it does not descend from UIControl, your view is responsible for handling any touch events within its bounds. */
@property (nonatomic, strong) UIView *leftCalloutAccessoryView;

/** The view to display on the right side of the standard callout bubble.
*
*   This property is set to `nil` by default. The right callout view is typically used to link to more detailed information about the annotation. The height of your view should be 32 pixels or less. A common view to specify for this property is UIButton object whose type is set to UIButtonTypeDetailDisclosure.
*
*   If the view you specify is also a descendant of the UIControl class, you can use the map view’s delegate to receive notifications when your control is tapped. If it does not descend from UIControl, your view is responsible for handling any touch events within its bounds. */
@property (nonatomic, strong) UIView *rightCalloutAccessoryView;

/** Set the screen position of the layer.
*   @param position The desired screen position.
*   @param animated If set to `YES`, any position change is animated. */
- (void)setPosition:(CGPoint)position animated:(BOOL)animated;

- (void)setDragState:(RMMapLayerDragState)dragState animated:(BOOL)animated;

@end
