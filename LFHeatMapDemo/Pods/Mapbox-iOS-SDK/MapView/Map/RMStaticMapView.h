//
//  RMStaticMapView.h
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

#import <UIKit/UIKit.h>

#import "RMMapView.h"

/** An RMStaticMapView object provides an embeddable, static map image view. You use this class to display map information in your application that does not need to change or provide user interaction. You can center the map on a given coordinate and zoom level, specify the size of the area you want to display, and optionally provide a completion handler that can be performed upon map load. The map can also automatically have markers added to it if they were provided as simplestyle data when the map was created. 
*
*   @warning Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use. You are also responsible for displaying attribution details for the data elsewhere in your application, if applicable. */
@interface RMStaticMapView : RMMapView

/** @name Initializing a Static Map View */

/** Initialize a static map view with a given frame and mapID. 
*
*   The map ID is expected to provide initial center coordinate and zoom level information, and may optionally also include simplestyle marker data, which will automatically be added to the map view.
*   @param frame The frame with which to initialize the map view.
*   @param mapID The Mapbox map ID string, typically in the format `<username>.map-<mapname>`.
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID;

/** Initialize a static map view with a given frame and mapID, performing a block upon completion of the map load. 
*
*   The map ID is expected to provide initial center coordinate and zoom level information, and may optionally also include simplestyle marker data, which will automatically be added to the map view. The block will be performed upon completion of the load of both the map and of any simplestyle markers included with the map ID.
*   @param frame The frame with which to initialize the map view.
*   @param mapID The Mapbox map ID string, typically in the format `<username>.map-<mapname>`.
*   @param handler A block to be performed upon map and marker load completion. An image of the map, including markers, is passed as an argument to the block in the event that you wish to use it elsewhere. The handler will be called on the main dispatch queue.
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID completionHandler:(void (^)(UIImage *))handler;

/** Initialize a static map view with a given frame, mapID, center coordinate, and zoom level.
*
*   The map ID may optionally also include simplestyle marker data, which will automatically be added to the map view.
*   @param frame The frame with which to initialize the map view.
*   @param mapID The Mapbox map ID string, typically in the format `<username>.map-<mapname>`.
*   @param centerCoordinate The map center coordinate.
*   @param zoomLevel The map zoom level.
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel;

/** Designated initializer. Initialize a static map view with a given frame, mapID, center coordinate, and zoom level, performing a block upon completion of the map load.
*
*   The map ID may optionally also include simplestyle marker data, which will automatically be added to the map view. The block will be performed upon completion of the load of both the map and of any simplestyle markers included with the map ID. 
*   @param frame The frame with which to initialize the map view.
*   @param mapID The Mapbox map ID string, typically in the format `<username>.map-<mapname>`.
*   @param centerCoordinate The map center coordinate.
*   @param zoomLevel The map zoom level.
*   @param handler A block to be performed upon map load completion. An image of the map, including markers, is passed as an argument to the block in the event that you wish to use it elsewhere. The handler will be called on the main dispatch queue.
*   @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler;

@end
