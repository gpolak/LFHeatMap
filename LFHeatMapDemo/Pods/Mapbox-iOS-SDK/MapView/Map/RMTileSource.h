//
//  RMTileSource.h
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

#import "RMTile.h"
#import "RMFoundation.h"
#import "RMGlobalConstants.h"

#define RMTileRequested @"RMTileRequested"
#define RMTileRetrieved @"RMTileRetrieved"

@class RMFractalTileProjection, RMTileCache, RMProjection, RMTileImage, RMTileCache;

@protocol RMMercatorToTileProjection;

#pragma mark -

/** The RMTileSource protocol describes the general interface for map tile sources. Whether retrieved from network sources or provided locally, tile sources must provide some specific minimum properties. */
@protocol RMTileSource <NSObject>

/** @name Configuring the Supported Zoom Levels */

/** The minimum zoom level supported by the tile source. */
@property (nonatomic, assign) float minZoom;

/** The maximum zoom level supported by the tile source. */
@property (nonatomic, assign) float maxZoom;

/** A Boolean value indicating whether the tiles from this source should be cached. */
@property (nonatomic, assign, getter=isCacheable) BOOL cacheable;

/** A Boolean value indicating whether the tiles from this source are opaque. Setting this correctly is important when using RMCompositeSource so that alpha transparency can be preserved when compositing tile images. */
@property (nonatomic, assign, getter=isOpaque) BOOL opaque;

@property (nonatomic, readonly) RMFractalTileProjection *mercatorToTileProjection;
@property (nonatomic, readonly) RMProjection *projection;

/** @name Querying the Bounds */

/** The bounding box that the tile source provides coverage for. */
@property (nonatomic, readonly) RMSphericalTrapezium latitudeLongitudeBoundingBox;

/** @name Configuring Caching */

/** A unique string representing the tile source in the cache in order to distinguish it from other tile sources. */
@property (nonatomic, readonly) NSString *uniqueTilecacheKey;

/** @name Configuring Tile Size */

/** The number of pixels along the side of a tile image for this source. */
@property (nonatomic, readonly) NSUInteger tileSideLength;

/** @name Configuring Descriptive Properties */

/** A short version of the tile source's name. */
@property (nonatomic, readonly) NSString *shortName;

/** An extended version of the tile source's description. */
@property (nonatomic, readonly) NSString *longDescription;

/** A short version of the tile source's attribution string. */
@property (nonatomic, readonly) NSString *shortAttribution;

/** An extended version of the tile source's attribution string. */
@property (nonatomic, readonly) NSString *longAttribution;

#pragma mark -

/** @name Supplying Tile Images */

/** Provide an image for a given tile location using a given cache.
*   @param tile The map tile in question.
*   @param tileCache A tile cache to check first when providing the image.
*   @return An image to display. */
- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache;

/** Check if the tile source can provide the requested tile.
 *  @param tile The map tile in question.
 *  @return A Boolean value indicating whether the tile source can provide the requested tile. */
- (BOOL)tileSourceHasTile:(RMTile)tile;

- (void)cancelAllDownloads;

- (void)didReceiveMemoryWarning;

@end
