//
//  RMCompositeSource.h
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

#import "RMAbstractMercatorTileSource.h"

/** RMCompositeSource combines two or more other tile sources, compositing them into a single image per tile and caching that composited result to the tile cache.
*
*   RMCompositeSource can have better performance for instances of fully opaque tiles that are layered above other tiles in the tile source stacking order. It will determine if a tile is opaque and stop iteration of tile sources below it early as a result, since they would be obscured anyway. */
@interface RMCompositeSource : RMAbstractMercatorTileSource

/** @name Creating Tile Sources */

/** Initialize a compositing tile source.
*
*   @param tileSources An array of tile sources to be composited.
*   @param tileCacheKey A tile cache key for storage of composited result tiles. 
*   @return An initialized compositing tile source. */
- (id)initWithTileSources:(NSArray *)tileSources tileCacheKey:(NSString *)tileCacheKey;

/** @name Querying Tile Source Information */

/** An array of tile sources being composited. */
@property (nonatomic, weak, readonly) NSArray *tileSources;

@end
