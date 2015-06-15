//
//  RMMemoryCache.h
//
// Copyright (c) 2008-2009, Route-Me Contributors
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
#import "RMTileCache.h"

/** An RMMemoryCache object represents memory-based caching of map tile images. Since memory is constrained in the iOS environment, this cache is relatively small, but useful for increasing performance. */
@interface RMMemoryCache : NSObject <RMTileCache>

/** @name Initializing Memory Caches */

/** Initializes and returns a newly allocated memory cache object with the specified tile count capacity.
*   @param aCapacity The maximum number of tiles to be held in the cache.
*   @return An initialized memory cache object or `nil` if the object couldn't be created. */
- (id)initWithCapacity:(NSUInteger)aCapacity;

/** @name Cache Capacity */

/** The capacity, in number of tiles, that the memory cache can hold. */
@property (nonatomic, readonly, assign) NSUInteger capacity;

/** @name Making Space in the Cache */

/** Remove the least-recently used image from the cache if the cache is at or over capacity. This removes a single image from the cache. */
- (void)makeSpaceInCache;

@end
