//
//  RMTileCache.h
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
#import "RMTileSource.h"
#import "RMCacheObject.h"

@class RMTileImage, RMMemoryCache;

typedef enum : short {
	RMCachePurgeStrategyLRU,
	RMCachePurgeStrategyFIFO,
} RMCachePurgeStrategy;

#pragma mark -

/** The RMTileCache protocol describes behaviors that tile caches should implement. */
@protocol RMTileCache <NSObject>

/** @name Querying the Cache */

/** Returns an image from the cache if it exists. 
*   @param tile A desired RMTile.
*   @param cacheKey The key representing a certain cache.
*   @return An image of the tile that can be used to draw a portion of the map. */
- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)cacheKey;

/** Returns an image from the cache if it exists.
*   @param tile A desired RMTile.
*   @param cacheKey The key representing a certain cache.
*   @param shouldBypassMemoryCache Whether to only consult disk-based caches.
*   @return An image of the tile that can be used to draw a portion of the map. */
- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)cacheKey bypassingMemoryCache:(BOOL)shouldBypassMemoryCache;

- (void)didReceiveMemoryWarning;

@optional

/** @name Adding to the Cache */

/** Adds a tile image to the specified cache.
*   @param image A tile image to be cached.
*   @param tile The RMTile describing the map location of the image.
*   @param cacheKey The key representing a certain cache. */
- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)cacheKey;

/** Adds tile image data to the specified cache, bypassing the memory cache and only writing to disk. This is useful for instances where many tiles are downloaded directly to disk for later use offline.
*   @param data The tile image data to be cached.
*   @param tile The RMTile describing the map location of the image.
*   @param cacheKey The key representing a certain cache. */
- (void)addDiskCachedImageData:(NSData *)data forTile:(RMTile)tile withCacheKey:(NSString *)cacheKey;

/** @name Clearing the Cache */

/** Removes all tile images from a cache. */
- (void)removeAllCachedImages;
- (void)removeAllCachedImagesForCacheKey:(NSString *)cacheKey;

@end

#pragma mark -

/** The RMTileCacheBackgroundDelegate protocol is for receiving notifications about background tile cache download operations. 
*
*   These callbacks are not guaranteed to be received on the main thread, so if you intend to do work in the user interface, you should properly enqueue such jobs on the main thread. */
@protocol RMTileCacheBackgroundDelegate <NSObject>

@optional

/** Sent when the background caching operation begins.
*   @param tileCache The tile cache. 
*   @param tileCount The total number of tiles required for coverage of the desired geographic area. 
*   @param tileSource The tile source providing the tiles. */
- (void)tileCache:(RMTileCache *)tileCache didBeginBackgroundCacheWithCount:(NSUInteger)tileCount forTileSource:(id <RMTileSource>)tileSource;

/** Sent upon caching of each tile in a background cache operation.
*   @param tileCache The tile cache. 
*   @param tile A structure representing the tile in question. 
*   @param tileIndex The index of the tile in question, beginning with `1` and ending with totalTileCount. 
*   @param totalTileCount The total number of of tiles required for coverage of the desired geographic area. */
- (void)tileCache:(RMTileCache *)tileCache didBackgroundCacheTile:(RMTile)tile withIndex:(NSUInteger)tileIndex ofTotalTileCount:(NSUInteger)totalTileCount;

/** Sent upon error when trying to cache a tile in a background cache operation. 
*   @param tileCache The tile cache.
*   @param error The error received.
*   @param tile A structure representing the tile in question. */
- (void)tileCache:(RMTileCache *)tileCache didReceiveError:(NSError *)error whenCachingTile:(RMTile)tile;

/** Sent when all tiles have completed downloading and caching. 
*   @param tileCache The tile cache. */
- (void)tileCacheDidFinishBackgroundCache:(RMTileCache *)tileCache;

/** Sent when the cache download operation has completed cancellation and the cache object is safe to dispose of. 
*   @param tileCache The tile cache. */
- (void)tileCacheDidCancelBackgroundCache:(RMTileCache *)tileCache;

@end

#pragma mark -

/** An RMTileCache object manages memory-based and disk-based caches for map tiles that have been retrieved from the network. 
*
*   An RMMapView has one RMTileCache across all tile sources, which is further divided according to each tile source's uniqueTilecacheKey property in order to keep tiles separate in the cache.
*
*   An RMTileCache is a key component of offline map use. All tile requests pass through the tile cache and are served from cache if available, avoiding network operation. If tiles exist in cache already, a tile source that is instantiated when offline will still be able to serve tile imagery to the map renderer for areas that have been previously cached. This can occur either from normal map use, since all tiles are cached after being retrieved, or from proactive caching ahead of time using the beginBackgroundCacheForTileSource:southWest:northEast:minZoom:maxZoom: method. 
*
*   @see [RMDatabaseCache initUsingCacheDir:] */
@interface RMTileCache : NSObject <RMTileCache>

/** @name Initializing a Cache Manager */

/** Initializes and returns a newly allocated cache object with specified expiry period.
*
*   If the `init` method is used to initialize a cache instead, a period of `0` is used. In that case, time-based expiration of tiles is not performed, but rather the cached tile count is used instead.
*
*   @param period A period of time after which tiles should be expunged from the cache.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithExpiryPeriod:(NSTimeInterval)period;

/** @name Identifying Cache Objects */

/** Return an identifying hash number for the specified tile.
*
*   @param tile A tile image to hash.
*   @return A unique number for the specified tile. */
+ (NSNumber *)tileHash:(RMTile)tile;

/** @name Adding Caches to the Cache Manager */

/** Adds a given cache to the cache management system.
*
*   @param cache A memory-based or disk-based cache. */
- (void)addCache:(id <RMTileCache>)cache;
- (void)insertCache:(id <RMTileCache>)cache atIndex:(NSUInteger)index;

/** The list of caches managed by a cache manager. This could include memory-based, disk-based, or other types of caches. */
@property (nonatomic, readonly, strong) NSArray *tileCaches;

- (void)didReceiveMemoryWarning;

/** @name Background Downloading */

/** A delegate to notify of background tile cache download operations. */
@property (nonatomic, weak) id <RMTileCacheBackgroundDelegate>backgroundCacheDelegate;

/** Whether or not the tile cache is currently background caching. */
@property (nonatomic, readonly, assign) BOOL isBackgroundCaching;

/** Tells the tile cache to begin background caching. Progress during the caching operation can be observed by implementing the RMTileCacheBackgroundDelegate protocol.
*   @param tileSource The tile source from which to retrieve tiles.
*   @param southWest The southwest corner of the geographic area to cache.
*   @param northEast The northeast corner of the geographic area to cache. 
*   @param minZoom The minimum zoom level to cache. 
*   @param maxZoom The maximum zoom level to cache. */
- (void)beginBackgroundCacheForTileSource:(id <RMTileSource>)tileSource southWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast minZoom:(NSUInteger)minZoom maxZoom:(NSUInteger)maxZoom;

/** Cancel any background caching. 
*
*   This method returns immediately so as to not block the calling thread. If you wish to be notified of the actual cancellation completion, implement the tileCacheDidCancelBackgroundCache: delegate method. */
- (void)cancelBackgroundCache;

/** A count of the number of tiles that would be downloaded in a background tile cache download operation.
*   @param southWest The southwest corner of the geographic area to cache.
*   @param northEast The northeast corner of the geographic area to cache.
*   @param minZoom The minimum zoom level to cache.
*   @param maxZoom The maximum zoom level to cache.
*   @return The number of tiles representing the coverage area. */
- (NSUInteger)tileCountForSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast minZoom:(NSUInteger)minZoom maxZoom:(NSUInteger)maxZoom;

@end
