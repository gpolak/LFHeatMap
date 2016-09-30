//
//  RMAbstractMercatorTileSource.m
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
#import "RMTileImage.h"
#import "RMFractalTileProjection.h"
#import "RMProjection.h"

@implementation RMAbstractMercatorTileSource
{
    RMFractalTileProjection *_tileProjection;
}

@synthesize minZoom = _minZoom, maxZoom = _maxZoom, cacheable = _cacheable, opaque = _opaque;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    _tileProjection = nil;

    // http://wiki.openstreetmap.org/index.php/FAQ#What_is_the_map_scale_for_a_particular_zoom_level_of_the_map.3F
    self.minZoom = kDefaultMinTileZoom;
    self.maxZoom = kDefaultMaxTileZoom;

    self.cacheable = YES;
    self.opaque = YES;

    return self;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return kDefaultLatLonBoundingBox;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"imageForTile:inCache: invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}    

- (BOOL)tileSourceHasTile:(RMTile)tile
{
    return YES;
}

- (void)cancelAllDownloads
{
}

- (RMProjection *)projection
{
    return [RMProjection googleProjection];
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    if ( ! _tileProjection)
    {
        _tileProjection = [[RMFractalTileProjection alloc] initFromProjection:self.projection
                                                               tileSideLength:self.tileSideLength
                                                                      maxZoom:self.maxZoom
                                                                      minZoom:self.minZoom];
    }

    return _tileProjection;
}

- (void)didReceiveMemoryWarning
{
    LogMethod();
}

#pragma mark -

- (NSUInteger)tileSideLength
{
    return kDefaultTileSize;
}

- (NSString *)uniqueTilecacheKey
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"uniqueTilecacheKey invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)shortName
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortName invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)longDescription
{
	return [self shortName];
}

- (NSString *)shortAttribution
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortAttribution invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)longAttribution
{
	return [self shortAttribution];
}

@end

