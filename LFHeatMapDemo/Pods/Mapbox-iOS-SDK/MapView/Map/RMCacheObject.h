//
//  RMCacheObject.h
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

#import "RMTile.h"

/** An RMCacheObject is a representation of a tile cache for use with the RMMemoryCache in-memory cache storage. While RMDatabaseCache uses a disk-based database backing store, RMMemoryCache maintains first-class objects in memory for use later. */
@interface RMCacheObject : NSObject

/** @name Managing Cache Objects */

/** The object to be cached, typically a UIImage. */
@property (nonatomic, readonly) id cachedObject;

/** The unique identifier for the cache. */
@property (nonatomic, readonly) NSString *cacheKey;

/** The tile key for the cache object. */
@property (nonatomic, readonly) RMTile tile;

/** The freshness timestamp for the cache object. */
@property (nonatomic, readonly) NSDate *timestamp;

/** Creates and returns a cache object for a given key and object to store in a given cache.
*   @param anObject The object to cache, typically a UIImage.
*   @param aTile The tile key for the object.
*   @param aCacheKey The unique identifier for the cache.
*   @return A newly created cache object. */
+ (instancetype)cacheObject:(id)anObject forTile:(RMTile)aTile withCacheKey:(NSString *)aCacheKey;

/** Initializes and returns a newly allocated cache object for a given key and object to store in a given cache.
*   @param anObject The object to cache, typically a UIImage.
*   @param tile The tile key for the object.
*   @param aCacheKey The unique identifier for the cache.
*   @return An initialized cache object. */
- (id)initWithObject:(id)anObject forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey;

/** Updates the timestamp on a cache object to indicate freshness. Objects with older timestamps get deleted first when space is needed. */
- (void)touch;

@end
