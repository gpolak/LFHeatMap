//
// RMDBMapSource.m
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

// RMDBMap source is an implementation of an sqlite tile source which is 
// can be used as an offline map store. 
//
// The implementation expects two tables in the database:
//
// table "preferences" - contains the map meta data as name/value pairs
//
//    SQL: create table preferences(name text primary key, value text)
//
//    The preferences table must at least contain the following
//    values for the tile source to function properly.
//
//      * map.minZoom           - minimum supported zoom level
//      * map.maxZoom           - maximum supported zoom level
//      * map.tileSideLength    - tile size in pixels
// 
//    Optionally it can contain the following values
// 
//    Coverage area:
//      * map.coverage.topLeft.latitude
//      * map.coverage.topLeft.longitude
//      * map.coverage.bottomRight.latitude
//      * map.coverage.bottomRight.longitude
//      * map.coverage.center.latitude
//      * map.coverage.center.longitude
//
//    Attribution:
//      * map.shortName
//      * map.shortAttribution
//      * map.longDescription
//      * map.longAttribution
//
// table "tiles" - contains the tile images
//
//    SQL: create table tiles(tilekey integer primary key, image blob)
//
//    The tile images are stored in the "image" column as a blob. 
//    The primary key of the table is the "tilekey" which is computed
//    with the RMTileKey function (found in RMTile.h)
//
//    uint64_t RMTileKey(RMTile tile);
//    

#import "RMDBMapSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMFractalTileProjection.h"
#import "FMDB.h"

#pragma mark --- begin constants ----

// mandatory preference keys
#define kMinZoomKey @"map.minZoom"
#define kMaxZoomKey @"map.maxZoom"
#define kTileSideLengthKey @"map.tileSideLength"

// optional preference keys for the coverage area
#define kCoverageTopLeftLatitudeKey @"map.coverage.topLeft.latitude"
#define kCoverageTopLeftLongitudeKey @"map.coverage.topLeft.longitude"
#define kCoverageBottomRightLatitudeKey @"map.coverage.bottomRight.latitude"
#define kCoverageBottomRightLongitudeKey @"map.coverage.bottomRight.longitude"
#define kCoverageCenterLatitudeKey @"map.coverage.center.latitude"
#define kCoverageCenterLongitudeKey @"map.coverage.center.longitude"

// optional preference keys for the attribution
#define kShortNameKey @"map.shortName"
#define kLongDescriptionKey @"map.longDescription"
#define kShortAttributionKey @"map.shortAttribution"
#define kLongAttributionKey @"map.longAttribution"

#pragma mark --- end constants ----

@interface RMDBMapSource (Preferences)

- (NSString *)getPreferenceAsString:(NSString *)name;
- (float)getPreferenceAsFloat:(NSString *)name;
- (int)getPreferenceAsInt:(NSString *)name;

@end

#pragma mark -

@implementation RMDBMapSource
{
    FMDatabaseQueue *_queue;

    // coverage area
    CLLocationCoordinate2D _topLeft;
    CLLocationCoordinate2D _bottomRight;
    CLLocationCoordinate2D _center;

    NSString *_uniqueTilecacheKey;
    NSUInteger _tileSideLength;
}

- (id)initWithPath:(NSString *)path
{
	if (!(self = [super init]))
        return nil;

    _uniqueTilecacheKey = [[path lastPathComponent] stringByDeletingPathExtension];

    _queue = [FMDatabaseQueue databaseQueueWithPath:path];

    if ( ! _queue)
    {
        RMLog(@"Error opening db map source %@", path);
        return nil;
    }

    [_queue inDatabase:^(FMDatabase *db) {
        [db setShouldCacheStatements:YES];

        // Debug mode
        // [db setTraceExecution:YES];
    }];

    RMLog(@"Opening db map source %@", path);

    // get the tile side length
    _tileSideLength = [self getPreferenceAsInt:kTileSideLengthKey];

    // get the supported zoom levels
    self.minZoom = [self getPreferenceAsFloat:kMinZoomKey];
    self.maxZoom = [self getPreferenceAsFloat:kMaxZoomKey];

    // get the coverage area
    _topLeft.latitude = [self getPreferenceAsFloat:kCoverageTopLeftLatitudeKey];
    _topLeft.longitude = [self getPreferenceAsFloat:kCoverageTopLeftLongitudeKey];
    _bottomRight.latitude = [self getPreferenceAsFloat:kCoverageBottomRightLatitudeKey];
    _bottomRight.longitude = [self getPreferenceAsFloat:kCoverageBottomRightLongitudeKey];
    _center.latitude = [self getPreferenceAsFloat:kCoverageCenterLatitudeKey];
    _center.longitude = [self getPreferenceAsFloat:kCoverageCenterLongitudeKey];

    RMLog(@"Tile size: %lu pixel", (unsigned long)self.tileSideLength);
    RMLog(@"Supported zoom range: %.0f - %.0f", self.minZoom, self.maxZoom);
    RMLog(@"Coverage area: (%2.6f,%2.6f) x (%2.6f,%2.6f)",
          _topLeft.latitude,
          _topLeft.longitude,
          _bottomRight.latitude,
          _bottomRight.longitude);
    RMLog(@"Center: (%2.6f,%2.6f)",
          _center.latitude,
          _center.longitude);

	return self;
}

- (CLLocationCoordinate2D)topLeftOfCoverage
{
    return _topLeft;
}

- (CLLocationCoordinate2D)bottomRightOfCoverage
{
    return _bottomRight;
}

- (CLLocationCoordinate2D)centerOfCoverage
{
    return _center;
}

#pragma mark RMTileSource methods

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];

    if (self.isCacheable)
    {
        image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];

        if (image)
            return image;
    }

    // get the unique key for the tile
    NSNumber *key = [NSNumber numberWithLongLong:RMTileKey(tile)];

    [_queue inDatabase:^(FMDatabase *db)
    {
        // fetch the image from the db
        FMResultSet *result = [db executeQuery:@"SELECT image FROM tiles WHERE tilekey = ?", key];

        if ([db hadError])
            NSLog(@"DB error %d on line %d: %@", [db lastErrorCode], __LINE__, [db lastErrorMessage]);

        if ([result next])
            image = [[UIImage alloc] initWithData:[result dataForColumnIndex:0]];
        else
            image = [RMTileImage missingTile];

        [result close];
    }];

    if (image && self.isCacheable)
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];

	return image;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    CLLocationCoordinate2D southWest, northEast;
    southWest.latitude = _bottomRight.latitude;
    southWest.longitude = _topLeft.longitude;
    northEast.latitude = _topLeft.latitude;
    northEast.longitude = _bottomRight.longitude;

    RMSphericalTrapezium bbox;
    bbox.southWest = southWest;
    bbox.northEast = northEast;

    return bbox;
}

- (NSUInteger)tileSideLength
{
    return _tileSideLength;
}

- (NSString *)uniqueTilecacheKey
{
    return _uniqueTilecacheKey;
}

- (NSString *)shortName
{
	return [self getPreferenceAsString:kShortNameKey];
}

- (NSString *)longDescription
{
	return [self getPreferenceAsString:kLongDescriptionKey];
}

- (NSString *)shortAttribution
{
	return [self getPreferenceAsString:kShortAttributionKey];
}

- (NSString *)longAttribution
{
	return [self getPreferenceAsString:kLongAttributionKey];
}

#pragma mark preference methods

- (NSString *)getPreferenceAsString:(NSString*)name
{
	__block NSString* value = nil;

    [_queue inDatabase:^(FMDatabase *db)
     {
        FMResultSet *result = [db executeQuery:@"select value from preferences where name = ?", name];

        if ([result next])
            value = [result stringForColumn:@"value"];

        [result close];
     }];

	return value;
}

- (float)getPreferenceAsFloat:(NSString *)name
{
	NSString *value = [self getPreferenceAsString:name];
	return (value == nil) ? INT_MIN : [value floatValue];
}

- (int)getPreferenceAsInt:(NSString *)name
{
	NSString* value = [self getPreferenceAsString:name];
	return (value == nil) ? INT_MIN : [value intValue];
}

@end
