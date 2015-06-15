//
//  RMInteractiveSource.h
//
//  Created by Justin R. Miller on 6/22/11.
//  Copyright 2012-2013 Mapbox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of Mapbox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Based on the UTFGrid specification: https://github.com/mapbox/utfgrid-spec
//

#import "RMMapView.h"
#import "RMMBTilesSource.h"
#import "RMMapboxSource.h"

typedef enum : NSUInteger {
    RMInteractiveSourceOutputTypeTeaser = 0,
    RMInteractiveSourceOutputTypeFull   = 1,
} RMInteractiveSourceOutputType;

/** Developers can import RMInteractiveSource in order to enable embedded interactivity in their RMMapView, RMMBTilesSource, and RMMapboxSource objects. Interactivity is based on the UTFGrid specification, which is a space-efficient way to encode many arbitrary values for pixel coordinates at every zoom level, allowing later retrieval based on user events on those coordinates. For example, the user touching a pixel in Spain could trigger retrieval of Spain's flag image for display. 
*
*   Interactive map views adopt the RMInteractiveMapView protocol.
*
*   Interactivity currently supports two types of output, teaser and full. These two types are ideal for master/detail interfaces or for showing a MapKit-style detail-toggling point callout. */
@protocol RMInteractiveMapView

@required

/** @name Querying Interactivity */

/** Returns YES if a map view supports interactivity features given its current tile sources. */
- (BOOL)supportsInteractivity;

/** Returns the HTML-formatted output for a given point on a given map view.
*   @param outputType The type of feature info desired.
*   @param point A point in the map view.
*   @return The formatted feature output. */
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point;

@end

#pragma mark -

@interface RMMapView (RMInteractiveSource) <RMInteractiveMapView>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point;

@end

#pragma mark -

/** Developers can import RMInteractiveSource in order to enable embedded interactivity in their RMMapView, RMMBTilesSource, and RMMapboxSource objects. Interactivity is based on the [UTFGrid specification](https://github.com/mapbox/utfgrid-spec) and is best described by [this web demo](https://mapbox.com/demo/visiblemap/).
*
*   Interactive tile sources adopt the RMInteractiveSource protocol.
*
*   Interactivity currently supports two types of output, teaser and full. These two types are ideal for master/detail interfaces or for showing a MapKit-style detail-toggling point callout. */
@protocol RMInteractiveSource

@required

/** @name Querying Interactivity */

/** Returns YES if a tile source supports interactivity features. */
- (BOOL)supportsInteractivity;

/** Returns the HTML-formatted output for a given point on a given map view, considering the currently active interactive tile source.
*   @param outputType The type of feature info desired.
*   @param point A point in the map view.
*   @param mapView The map view being interacted with.
*   @return The formatted feature output. */
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMMBTilesSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMMapboxSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end
