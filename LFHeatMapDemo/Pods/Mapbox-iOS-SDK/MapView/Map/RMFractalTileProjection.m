//
//  RMFractalTileProjection.m
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

#import "RMFractalTileProjection.h"

#import <math.h>

@implementation RMFractalTileProjection
{
    // Maximum and minimum zoom for which our tile server stores images
    NSUInteger _maxZoom, _minZoom;

    // projected bounds of the planet, in meters
    RMProjectedRect _planetBounds;

    // Normally 256px. This class assumes tiles are square.
    NSUInteger _tileSideLength;

    // The deal is, we have a scale which stores how many mercator gradiants per pixel
    // in the image.
    // If you run the maths, scale = bounds.width/(2^zoom * tileSideLength)
    // or if you want, z = log(bounds.width/tileSideLength) - log(s)
    // So here we'll cache the first term for efficiency.
    // I'm using width arbitrarily - I'm not sure what the effect of using the other term is when they're not the same.
    double _scaleFactor;
}

@synthesize maxZoom = _maxZoom, minZoom = _minZoom;
@synthesize tileSideLength = _tileSideLength;
@synthesize planetBounds = _planetBounds;

- (id)initFromProjection:(RMProjection *)projection tileSideLength:(NSUInteger)aTileSideLength maxZoom:(NSUInteger)aMaxZoom minZoom:(NSUInteger)aMinZoom
{
    if (!(self = [super init]))
        return nil;

    // We don't care about the rest of the projection... just the bounds is important.
    _planetBounds = [projection planetBounds];

    if (_planetBounds.size.width == 0.0f || _planetBounds.size.height == 0.0f)
    {
        @throw [NSException exceptionWithName:@"RMUnknownBoundsException"
                                       reason:@"RMFractalTileProjection was initialised with a projection with unknown bounds"
                                     userInfo:nil];
    }

    _tileSideLength = aTileSideLength;
    _maxZoom = aMaxZoom;
    _minZoom = aMinZoom;

    _scaleFactor = log2(_planetBounds.size.width / _tileSideLength);

    return self;
}

- (void)setTileSideLength:(NSUInteger)aTileSideLength
{
    _tileSideLength = aTileSideLength;

    _scaleFactor = log2(_planetBounds.size.width / _tileSideLength);
}

- (void)setMinZoom:(NSUInteger)aMinZoom
{
    _minZoom = aMinZoom;
}

- (void)setMaxZoom:(NSUInteger)aMaxZoom
{
    _maxZoom = aMaxZoom;
}

- (float)normaliseZoom:(float)zoom
{
    float normalised_zoom = roundf(zoom);

    if (normalised_zoom > _maxZoom)
        normalised_zoom = _maxZoom;
    if (normalised_zoom < _minZoom)
        normalised_zoom = _minZoom;

    return normalised_zoom;
}

- (float)limitFromNormalisedZoom:(float)zoom
{
    return exp2f(zoom);
}

- (RMTile)normaliseTile:(RMTile)tile
{
    // The mask contains a 1 for every valid x-coordinate bit.
    uint32_t mask = 1;

    for (int i = 0; i < tile.zoom; i++)
        mask <<= 1;

    mask -= 1;
    tile.x &= mask;

    // If the tile's y coordinate is off the screen
    if (tile.y & (~mask))
        return RMTileDummy();

    return tile;
}

- (RMProjectedPoint)constrainPointHorizontally:(RMProjectedPoint)aPoint
{
    while (aPoint.x < _planetBounds.origin.x)
        aPoint.x += _planetBounds.size.width;

    while (aPoint.x > (_planetBounds.origin.x + _planetBounds.size.width))
        aPoint.x -= _planetBounds.size.width;

    return aPoint;
}

- (RMTilePoint)projectInternal:(RMProjectedPoint)aPoint normalisedZoom:(float)zoom limit:(float)limit
{
    RMTilePoint tile;
    RMProjectedPoint newPoint = [self constrainPointHorizontally:aPoint];

    double x = (newPoint.x - _planetBounds.origin.x) / _planetBounds.size.width * limit;

    // Unfortunately, y is indexed from the bottom left.. hence we have to translate it.
    double y = (double)limit * ((_planetBounds.origin.y - newPoint.y) / _planetBounds.size.height + 1);

    tile.tile.x = (uint32_t)x;
    tile.tile.y = (uint32_t)y;
    tile.tile.zoom = zoom;
    tile.offset.x = (float)x - tile.tile.x;
    tile.offset.y = (float)y - tile.tile.y;

    return tile;
}

- (RMTilePoint)project:(RMProjectedPoint)aPoint atZoom:(float)zoom
{
    float normalised_zoom = [self normaliseZoom:zoom];
    float limit = [self limitFromNormalisedZoom:normalised_zoom];

    return [self projectInternal:aPoint normalisedZoom:normalised_zoom limit:limit];
}

- (RMTileRect)projectRect:(RMProjectedRect)aRect atZoom:(float)zoom
{
    float normalised_zoom = [self normaliseZoom:zoom];
    float limit = [self limitFromNormalisedZoom:normalised_zoom];

    RMTileRect tileRect;
    // The origin for projectInternal will have to be the top left instead of the bottom left.
    RMProjectedPoint topLeft = aRect.origin;
    topLeft.y += aRect.size.height;
    tileRect.origin = [self projectInternal:topLeft normalisedZoom:normalised_zoom limit:limit];

    tileRect.size.width = aRect.size.width / _planetBounds.size.width * limit;
    tileRect.size.height = aRect.size.height / _planetBounds.size.height * limit;

    return tileRect;
}

- (RMTilePoint)project:(RMProjectedPoint)aPoint atScale:(float)scale
{
    return [self project:aPoint atZoom:[self calculateZoomFromScale:scale]];
}

- (RMTileRect)projectRect:(RMProjectedRect)aRect atScale:(float)scale
{
    return [self projectRect:aRect atZoom:[self calculateZoomFromScale:scale]];
}

- (float)calculateZoomFromScale:(float)scale
{
    // zoom = log2(bounds.width/tileSideLength) - log2(s)
    return _scaleFactor - log2(scale);
}

- (float)calculateNormalisedZoomFromScale:(float)scale
{
    return [self normaliseZoom:[self calculateZoomFromScale:scale]];
}

- (float)calculateScaleFromZoom:(float)zoom
{
    return _planetBounds.size.width / _tileSideLength / exp2(zoom);
}

@end
