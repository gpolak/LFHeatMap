//
//  RMTileSourcesContainer.m
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

#import "RMTileSourcesContainer.h"

#import "RMCompositeSource.h"

@implementation RMTileSourcesContainer
{
    NSMutableArray *_tileSources;
    NSRecursiveLock *_tileSourcesLock;

    RMProjection *_projection;
    RMFractalTileProjection *_mercatorToTileProjection;

    RMSphericalTrapezium _latitudeLongitudeBoundingBox;

    float _minZoom, _maxZoom;
    NSUInteger _tileSideLength;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;

    _tileSources = [NSMutableArray new];
    _tileSourcesLock = [NSRecursiveLock new];

    _projection = nil;
    _mercatorToTileProjection = nil;

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {.latitude = 90.0, .longitude = 180.0},
        .southWest = {.latitude = -90.0, .longitude = -180.0}
    });

    _minZoom = kRMTileSourcesContainerMaxZoom;
    _maxZoom = kRMTileSourcesContainerMinZoom;
    _tileSideLength = 0;

    return self;
}

#pragma mark -

- (void)setBoundingBoxFromTilesources
{
    [_tileSourcesLock lock];

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {.latitude = 90.0, .longitude = 180.0},
        .southWest = {.latitude = -90.0, .longitude = -180.0}
    });

    for (id <RMTileSource>tileSource in _tileSources)
    {
        RMSphericalTrapezium newLatitudeLongitudeBoundingBox = [tileSource latitudeLongitudeBoundingBox];

        _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
            .northEast = {
                .latitude = MIN(_latitudeLongitudeBoundingBox.northEast.latitude, newLatitudeLongitudeBoundingBox.northEast.latitude),
                .longitude = MIN(_latitudeLongitudeBoundingBox.northEast.longitude, newLatitudeLongitudeBoundingBox.northEast.longitude)},
            .southWest = {
                .latitude = MAX(_latitudeLongitudeBoundingBox.southWest.latitude, newLatitudeLongitudeBoundingBox.southWest.latitude),
                .longitude = MAX(_latitudeLongitudeBoundingBox.southWest.longitude, newLatitudeLongitudeBoundingBox.southWest.longitude)
            }
        });
    }

    [_tileSourcesLock unlock];
}

#pragma mark -

- (NSArray *)tileSources
{
    NSArray *tileSources = nil;

    [_tileSourcesLock lock];
    tileSources = [_tileSources copy];
    [_tileSourcesLock unlock];

    return tileSources;
}

- (id <RMTileSource>)tileSourceForUniqueTilecacheKey:(NSString *)uniqueTilecacheKey
{
    if (!uniqueTilecacheKey)
        return nil;

    id result = nil;

    [_tileSourcesLock lock];

    NSMutableArray *tileSources = [NSMutableArray arrayWithArray:_tileSources];

    while ([tileSources count])
    {
        id <RMTileSource> currentTileSource = [tileSources objectAtIndex:0];
        [tileSources removeObjectAtIndex:0];

        if ([currentTileSource isKindOfClass:[RMCompositeSource class]])
        {
            [tileSources addObjectsFromArray:[(RMCompositeSource *)currentTileSource tileSources]];
        }
        else if ([[currentTileSource uniqueTilecacheKey] isEqualToString:uniqueTilecacheKey])
        {
            result = currentTileSource;
            break;
        }
    }

    [_tileSourcesLock unlock];

    return result;
}

- (BOOL)setTileSource:(id <RMTileSource>)tileSource
{
    BOOL result;

    [_tileSourcesLock lock];

    [self removeAllTileSources];
    result = [self addTileSource:tileSource];

    [_tileSourcesLock unlock];

    return result;
}

- (BOOL)setTileSources:(NSArray *)tileSources
{
    BOOL result = YES;

    [_tileSourcesLock lock];

    [self removeAllTileSources];

    for (id <RMTileSource> tileSource in tileSources)
        result &= [self addTileSource:tileSource];

    [_tileSourcesLock unlock];

    return result;
}

- (BOOL)addTileSource:(id <RMTileSource>)tileSource
{
    return [self addTileSource:tileSource atIndex:-1];
}

- (BOOL)addTileSource:(id<RMTileSource>)tileSource atIndex:(NSUInteger)index
{
    if ( ! tileSource)
        return NO;
    
    [_tileSourcesLock lock];

    RMProjection *newProjection = [tileSource projection];
    RMFractalTileProjection *newFractalTileProjection = [tileSource mercatorToTileProjection];

    if ( ! _projection)
    {
        _projection = newProjection;
    }
    else if (_projection != newProjection)
    {
        NSLog(@"The tilesource '%@' has a different projection than the tilesource container", [tileSource shortName]);
        [_tileSourcesLock unlock];
        return NO;
    }

    if ( ! _mercatorToTileProjection)
        _mercatorToTileProjection = newFractalTileProjection;

    // minZoom and maxZoom are the min and max values of all tile sources, so that individual tilesources
    // could have a smaller zoom level range
    self.minZoom = MIN(_minZoom, [tileSource minZoom]);
    self.maxZoom = MAX(_maxZoom, [tileSource maxZoom]);

    if (_tileSideLength == 0)
    {
        _tileSideLength = [tileSource tileSideLength];
    }
    else if (_tileSideLength != [tileSource tileSideLength])
    {
        NSLog(@"The tilesource '%@' has a different tile side length than the tilesource container", [tileSource shortName]);
        [_tileSourcesLock unlock];
        return NO;
    }

    RMSphericalTrapezium newLatitudeLongitudeBoundingBox = [tileSource latitudeLongitudeBoundingBox];

    double minX1 = _latitudeLongitudeBoundingBox.southWest.longitude;
    double minX2 = newLatitudeLongitudeBoundingBox.southWest.longitude;
    double maxX1 = _latitudeLongitudeBoundingBox.northEast.longitude;
    double maxX2 = newLatitudeLongitudeBoundingBox.northEast.longitude;

    double minY1 = _latitudeLongitudeBoundingBox.southWest.latitude;
    double minY2 = newLatitudeLongitudeBoundingBox.southWest.latitude;
    double maxY1 = _latitudeLongitudeBoundingBox.northEast.latitude;
    double maxY2 = newLatitudeLongitudeBoundingBox.northEast.latitude;

    BOOL intersects = (((minX1 <= minX2 && minX2 <= maxX1) || (minX2 <= minX1 && minX1 <= maxX2)) &&
                       ((minY1 <= minY2 && minY2 <= maxY1) || (minY2 <= minY1 && minY1 <= maxY2)));

    if ( ! intersects)
    {
        NSLog(@"The bounding box from tilesource '%@' doesn't intersect with the tilesource containers' bounding box", [tileSource shortName]);
        [_tileSourcesLock unlock];
        return NO;
    }

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {
            .latitude = MIN(_latitudeLongitudeBoundingBox.northEast.latitude, newLatitudeLongitudeBoundingBox.northEast.latitude),
            .longitude = MIN(_latitudeLongitudeBoundingBox.northEast.longitude, newLatitudeLongitudeBoundingBox.northEast.longitude)},
        .southWest = {
            .latitude = MAX(_latitudeLongitudeBoundingBox.southWest.latitude, newLatitudeLongitudeBoundingBox.southWest.latitude),
            .longitude = MAX(_latitudeLongitudeBoundingBox.southWest.longitude, newLatitudeLongitudeBoundingBox.southWest.longitude)
        }
    });

    if (index >= [_tileSources count])
        [_tileSources addObject:tileSource];
    else
        [_tileSources insertObject:tileSource atIndex:index];

    [_tileSourcesLock unlock];

    RMLog(@"Added the tilesource '%@' to the container", [tileSource shortName]);

    return YES;
}

- (void)removeTileSource:(id <RMTileSource>)tileSource
{
    [tileSource cancelAllDownloads];

    [_tileSourcesLock lock];

    [_tileSources removeObject:tileSource];

    RMLog(@"Removed the tilesource '%@' from the container", [tileSource shortName]);

    if ([_tileSources count] == 0)
        [self removeAllTileSources]; // cleanup
    else
        [self setBoundingBoxFromTilesources];

    [_tileSourcesLock unlock];
}

- (void)removeTileSourceAtIndex:(NSUInteger)index
{
    [_tileSourcesLock lock];

    if (index >= [_tileSources count])
    {
        [_tileSourcesLock unlock];
        return;
    }

    id <RMTileSource> tileSource = [_tileSources objectAtIndex:index];
    [tileSource cancelAllDownloads];
    [_tileSources removeObject:tileSource];

    RMLog(@"Removed the tilesource '%@' from the container", [tileSource shortName]);

    if ([_tileSources count] == 0)
        [self removeAllTileSources]; // cleanup
    else
        [self setBoundingBoxFromTilesources];

    [_tileSourcesLock unlock];
}

- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex)
        return;

    [_tileSourcesLock lock];

    if (fromIndex >= [_tileSources count])
    {
        [_tileSourcesLock unlock];
        return;
    }

    id tileSource = [_tileSources objectAtIndex:fromIndex];
    [_tileSources removeObjectAtIndex:fromIndex];

    if (toIndex >= [_tileSources count])
        [_tileSources addObject:tileSource];
    else
        [_tileSources insertObject:tileSource atIndex:toIndex];

    [_tileSourcesLock unlock];
}

- (void)removeAllTileSources
{
    [_tileSourcesLock lock];

    [self cancelAllDownloads];
    [_tileSources removeAllObjects];

     _projection = nil;
     _mercatorToTileProjection = nil;

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {.latitude = 90.0, .longitude = 180.0},
        .southWest = {.latitude = -90.0, .longitude = -180.0}
    });

    _minZoom = kRMTileSourcesContainerMaxZoom;
    _maxZoom = kRMTileSourcesContainerMinZoom;
    _tileSideLength = 0;

    [_tileSourcesLock unlock];
}

- (void)cancelAllDownloads
{
    [_tileSourcesLock lock];

    for (id <RMTileSource>tileSource in _tileSources)
        [tileSource cancelAllDownloads];

    [_tileSourcesLock unlock];
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    return _mercatorToTileProjection;
}

- (RMProjection *)projection
{
    return _projection;
}

- (float)minZoom
{
    return _minZoom;
}

- (void)setMinZoom:(float)minZoom
{
    if (minZoom < kRMTileSourcesContainerMinZoom)
        minZoom = kRMTileSourcesContainerMinZoom;

    _minZoom = minZoom;
}

- (float)maxZoom
{
    return _maxZoom;
}

- (void)setMaxZoom:(float)maxZoom
{
    if (maxZoom > kRMTileSourcesContainerMaxZoom)
        maxZoom = kRMTileSourcesContainerMaxZoom;

    _maxZoom = maxZoom;
}

- (NSUInteger)tileSideLength
{
    return _tileSideLength;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return _latitudeLongitudeBoundingBox;
}

- (void)didReceiveMemoryWarning
{
    [_tileSourcesLock lock];

    for (id <RMTileSource>tileSource in _tileSources)
        [tileSource didReceiveMemoryWarning];

    [_tileSourcesLock unlock];
}

@end
