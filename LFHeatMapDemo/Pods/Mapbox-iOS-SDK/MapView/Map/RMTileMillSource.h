//
//  RMTileMillSource.h
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

#import "RMGenericMapSource.h"

/** An RMTileMillSource is used to display map tiles from a live, running instance of [TileMill](https://mapbox.com/tilemill). All instances of TileMill automatically include an HTTP server, allowing network access outside of the application. This tile source allows for an easier development cycle between map editing and testing in an iOS application. */
@interface RMTileMillSource : RMGenericMapSource

/** @name Creating Tile Sources */

/** Initialize and return a newly allocated TileMill tile source based on a given map name. This assumes that TileMill is running on the local development computer (e.g., `localhost`), which will not work from an iOS device but will work in the iOS Simulator.
*   @param mapName The name of the map in TileMill, substituting dashes for spaces.
*   @param tileCacheKey A unique cache string to use for this tile source's tiles in the tile cache. 
*   @param minZoom The minimum zoom level supported by the map.
*   @param maxZoom The maximum zoom level supported by the map.
*   @return An initialized TileMill tile source. */
- (id)initWithMapName:(NSString *)mapName tileCacheKey:(NSString *)tileCacheKey minZoom:(float)minZoom maxZoom:(float)maxZoom;

/** Initialize and return a newly allocated TileMill tile source based on a given host and map name. This is ideal for testing on an actual iOS device if the network name or address of the computer running TileMill is passed as the `host` parameter. 
*   @param host The hostname or IP address of the computer running TileMill. 
*   @param mapName The name of the map in TileMill, substituting dashes for spaces.
*   @param tileCacheKey A unique cache string to use for this tile source's tiles in the tile cache.
*   @param minZoom The minimum zoom level supported by the map.
*   @param maxZoom The maximum zoom level supported by the map.
*   @return An initialized TileMill tile source. */
- (id)initWithHost:(NSString *)host mapName:(NSString *)mapName tileCacheKey:(NSString *)tileCacheKey minZoom:(float)minZoom maxZoom:(float)maxZoom;

@end
