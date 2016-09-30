//
// RMAbstractWebMapSource.h
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

#import "RMAbstractMercatorTileSource.h"
#import "RMProjection.h"

#define RMAbstractWebMapSourceDefaultRetryCount  3
#define RMAbstractWebMapSourceDefaultWaitSeconds 15.0

/** Abstract class representing a network-based location for retrieving map tiles for display. Developers can create subclasses in order to provide custom web addresses for tile downloads. */
@interface RMAbstractWebMapSource : RMAbstractMercatorTileSource

/** @name Configuring Network Behavior */

/** The number of times to retry downloads of a given tile image. */
@property (nonatomic, assign) NSUInteger retryCount;

/** The network timeout for each attempt to download a tile image. */
@property (nonatomic, assign) NSTimeInterval requestTimeoutSeconds;

/** @name Providing Tile Images */

/** Provide the URL for a given tile.
    @param tile A specific map tile.
    @return A URL to a tile image to download. */
- (NSURL *)URLForTile:(RMTile)tile;

/** Provide multiple URLs for a given tile. Each URL is fetched in turn and composited together before placement on the map. URLs are ordered from the bottom layer to the top layer.
    @param tile A specific map tile.
    @return An array of tile URLs to download, listed bottom to top. */
- (NSArray *)URLsForTile:(RMTile)tile;

@end
