//
//  RMMBTilesSource.h
//
//  Created by Justin R. Miller on 6/18/10.
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

#import <Foundation/Foundation.h>

#import "RMTileSource.h"

@class FMDatabaseQueue;

#define kMBTilesDefaultTileSize 256
#define kMBTilesDefaultMinTileZoom 0
#define kMBTilesDefaultMaxTileZoom 22
#define kMBTilesDefaultLatLonBoundingBox ((RMSphericalTrapezium){.northEast = {.latitude = 90, .longitude = 180}, .southWest = {.latitude = -90, .longitude = -180}})

/** An RMMBTilesSource provides for a fast, offline-capable set of map tile images served from a local database. [MBTiles](https://www.mapbox.com/foundations/an-open-platform/#mbtiles) is an open standard for map tile image transport. */
@interface RMMBTilesSource : NSObject <RMTileSource>
{
    FMDatabaseQueue *queue;
}

/** @name Creating Tile Sources */

/** Initialize and return a newly allocated MBTiles tile source based on a given bundle resource with the extension `.mbtiles`. 
*
*   @param name The name of the resource file. If name is an empty string or `nil`, uses the first file encountered with the extension `.mbtiles`. 
*   @return An initialized MBTiles tile source. */
- (id)initWithTileSetResource:(NSString *)name;

/** Initialize and return a newly allocated MBTiles tile source based on a given bundle resource.
*   @param name The name of the resource file. If name is an empty string or `nil`, uses the first file encountered of the supplied type.
*   @param extension If extension is an empty string or `nil`, the extension is assumed not to exist and the file is the first file encountered that exactly matches name. 
*   @return An initialized MBTiles tile source. */
- (id)initWithTileSetResource:(NSString *)name ofType:(NSString *)extension;

/** Initialize and return a newly allocated MBTiles tile source based on a given local database URL.
*   @param tileSetURL Local file path URL to an MBTiles file.
*   @return An initialized MBTiles tile source. */
- (id)initWithTileSetURL:(NSURL *)tileSetURL;

/** @name Querying Tile Source Information */

/** Any available HTML-formatted map legend data for the tile source, suitable for display in a `UIWebView`. */
- (NSString *)legend;

/** A suggested starting center coordinate for the map layer. */
- (CLLocationCoordinate2D)centerCoordinate;

/** A suggested starting center zoom level for the map layer. */
- (float)centerZoom;

/** Returns YES if the tile source provides full-world coverage; otherwise, returns NO. */
- (BOOL)coversFullWorld;

@end
