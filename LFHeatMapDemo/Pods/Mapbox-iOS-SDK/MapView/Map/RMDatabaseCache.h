//
//  RMDatabaseCache.h
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

#import <UIKit/UIKit.h>
#import "RMTileCache.h"

/** An RMDatabaseCache object represents disk-based caching of map tile images. This cache is meant for longer-term storage than RMMemoryCache, potentially for long periods of time, allowing completely offline use of map view.
*
*   @warning The database cache is currently based on [SQLite](http://www.sqlite.org), a lightweight, cross-platform, file-based relational database system. The schema is independent of and unrelated to the [MBTiles](http://mbtiles.org) file format or the RMMBTilesSource tile source. */
@interface RMDatabaseCache : NSObject <RMTileCache>

/** @name Getting the Database Path */

/** The path to the SQLite database on disk that backs the cache. */
@property (nonatomic, strong) NSString *databasePath;

+ (NSString *)dbPathUsingCacheDir:(BOOL)useCacheDir;

/** @name Initializing Database Caches */

/** Initializes and returns a newly allocated database cache object at the given disk path.
*   @param path The path to use for the database backing.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithDatabase:(NSString *)path;

/** Initializes and returns a newly allocated database cache object.
*   @param useCacheDir If YES, use the temporary cache space for the application, meaning that the cache files can be removed when the system deems it necessary to free up space. If NO, use the application's document storage space, meaning that the cache will not be automatically removed and will be backed up during device backups. The default value is NO.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initUsingCacheDir:(BOOL)useCacheDir;

/** @name Configuring Cache Behavior */

/** Set the cache purge strategy to use for the database.
*   @param theStrategy The cache strategy to use. */
- (void)setPurgeStrategy:(RMCachePurgeStrategy)theStrategy;

/** Set the maximum tile count allowed in the database.
*   @param theCapacity The number of tiles to allow to accumulate in the database before purging begins. */
- (void)setCapacity:(NSUInteger)theCapacity;

/** The capacity, in number of tiles, that the database cache can hold. */
@property (nonatomic, readonly, assign) NSUInteger capacity;

/** Set the minimum number of tiles to purge when clearing space in the cache.
*   @param thePurgeMinimum The number of tiles to delete at the time the cache is purged. */
- (void)setMinimalPurge:(NSUInteger)thePurgeMinimum;

/** Set the expiry period for cache purging.
*   @param theExpiryPeriod The amount of time to elapse before a tile should be removed from the cache. If set to zero, tile count-based purging will be used instead of time-based. */
- (void)setExpiryPeriod:(NSTimeInterval)theExpiryPeriod;

/** The current file size of the database cache on disk. */
- (unsigned long long)fileSize;

@end
