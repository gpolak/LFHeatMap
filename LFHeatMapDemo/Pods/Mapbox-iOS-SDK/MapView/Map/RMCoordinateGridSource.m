//
//  RMCoordinateGridSource.m
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

#import "RMCoordinateGridSource.h"

#import "RMTileCache.h"

#define kTileSidePadding 25.0 // px

static double coordinateGridSpacing[19] = {
    45.0, // 0
    45.0, // 1
    45.0, // 2
    10.0, // 3
    5.0, // 4
    5.0, // 5
    2.0, // 6
    1.0, // 7
    1.0, // 8
    0.5, // 9
    0.25, // 10
    (1.0 / 60.0) * 5.0, // 11
    (1.0 / 60.0) * 3.0, // 12
    (1.0 / 60.0) * 2.0, // 13
    (1.0 / 60.0), // 14
    (1.0 / 60.0), // 15
    (1.0 / 60.0), // 16
    (1.0 / 60.0), // 17
    (1.0 / 60.0), // 18
};

static double coordinateGridSpacingDecimal[19] = {
    45.0, // 0
    45.0, // 1
    45.0, // 2
    10.0, // 3
     5.0, // 4
     5.0, // 5
     2.0, // 6
     1.0, // 7
     1.0, // 8
     0.5, // 9
    0.25, // 10
    0.10, // 11
    0.05, // 12
    0.05, // 13
    0.01, // 14
    0.01, // 15
    0.01, // 16
    0.01, // 17
    0.01, // 18
};

@implementation RMCoordinateGridSource

@synthesize gridColor = _gridColor;
@synthesize gridLineWidth = _gridLineWidth;
@synthesize gridLabelInterval = _gridLabelInterval;
@synthesize gridMode = _gridMode;
@synthesize minorLabelColor = _minorLabelColor;
@synthesize minorLabelFont = _minorLabelFont;
@synthesize majorLabelColor = _majorLabelColor;
@synthesize majorLabelFont = _majorLabelFont;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    self.minZoom = 5;
    self.maxZoom = 17;

    self.opaque = NO;

    self.gridColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    self.gridLineWidth = 2.0;
    self.gridLabelInterval = 1;

    self.gridMode = GridModeGeographicDecimal;
    self.minorLabelColor = self.majorLabelColor = [UIColor colorWithWhite:0.1 alpha:0.7];
    self.minorLabelFont = [UIFont boldSystemFontOfSize:14.0];
    self.majorLabelFont = [UIFont boldSystemFontOfSize:11.0];

    return self;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    if (tile.zoom < 0 || tile.zoom > 18)
        return nil;

    UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];

    if (image)
        return image;

    // Implementation

    RMProjectedRect planetBounds = self.projection.planetBounds;

    double scale = (1<<tile.zoom);
    double tileMetersPerPixel = planetBounds.size.width / (self.tileSideLength * scale);
    double paddedTileSideLength = self.tileSideLength + (2.0 * kTileSidePadding);

    CGPoint bottomLeft = CGPointMake((tile.x * self.tileSideLength) - kTileSidePadding,
                                     ((scale - tile.y - 1) * self.tileSideLength) - kTileSidePadding);

    RMProjectedRect normalizedProjectedRect;
    normalizedProjectedRect.origin.x = (bottomLeft.x * tileMetersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedRect.origin.y = (bottomLeft.y * tileMetersPerPixel) - fabs(planetBounds.origin.y);
    normalizedProjectedRect.size.width = paddedTileSideLength * tileMetersPerPixel;
    normalizedProjectedRect.size.height = paddedTileSideLength * tileMetersPerPixel;

    CLLocationCoordinate2D southWest = [self.projection projectedPointToCoordinate:
                                        RMProjectedPointMake(normalizedProjectedRect.origin.x,
                                                             normalizedProjectedRect.origin.y)];
    CLLocationCoordinate2D northEast = [self.projection projectedPointToCoordinate:
                                        RMProjectedPointMake(normalizedProjectedRect.origin.x + normalizedProjectedRect.size.width,
                                                             normalizedProjectedRect.origin.y + normalizedProjectedRect.size.height)];

    double gridSpacing;

    switch (self.gridMode)
    {
        case GridModeGeographic: {
            gridSpacing = coordinateGridSpacing[tile.zoom];
            break;
        }
        case GridModeGeographicDecimal:
        case GridModeUTM:
        default: {
            gridSpacing = coordinateGridSpacingDecimal[tile.zoom];
            break;
        }
    }

    double coordinatesLatitudeSpan = northEast.latitude - southWest.latitude,
           coordinatesLongitudeSpan = northEast.longitude - southWest.longitude;
    double bottom = floor(southWest.latitude / gridSpacing) * gridSpacing,
           top = floor(northEast.latitude / gridSpacing) * gridSpacing;
    double left = ceil(southWest.longitude / gridSpacing) * gridSpacing,
           right = ceil(northEast.longitude / gridSpacing) * gridSpacing;

    // Draw the tile

	UIGraphicsBeginImageContext(CGSizeMake(paddedTileSideLength, paddedTileSideLength));
	CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextSetLineWidth(context, self.gridLineWidth);

    // Grid lines

    for (double row = top; row >= bottom; row -= gridSpacing)
    {
        CGFloat yCoordinate = paddedTileSideLength - (((row - southWest.latitude) / coordinatesLatitudeSpan) * paddedTileSideLength);
        CGContextMoveToPoint(context, 0.0, yCoordinate);
        CGContextAddLineToPoint(context, paddedTileSideLength, yCoordinate);
    }

    for (double column = left; column <= right; column += gridSpacing)
    {
        CGFloat xCoordinate = ((column - southWest.longitude) / coordinatesLongitudeSpan) * paddedTileSideLength;
        CGContextMoveToPoint(context, xCoordinate, 0.0);
        CGContextAddLineToPoint(context, xCoordinate, paddedTileSideLength);
    }

    CGContextStrokePath(context);

    // Labels

    for (double row = top; row >= bottom; row -= gridSpacing)
    {
        if (self.gridLabelInterval > 1 && fmod(round(row / gridSpacing), (double)self.gridLabelInterval) != 0)
            continue;

        CGFloat yCoordinate = paddedTileSideLength - (((row - southWest.latitude) / coordinatesLatitudeSpan) * paddedTileSideLength);

        for (double column = (left - (gridSpacing/2.0)); column <= (right + (gridSpacing / 2.0)); column += gridSpacing)
        {
            CGFloat xCoordinate = ((column - southWest.longitude) / coordinatesLongitudeSpan) * paddedTileSideLength;

            NSString *label1 = nil, *label2 = nil;
            double degrees = (row > 0.0 ? floor(row) : ceil(row));
            double fraction = (row > 0.0 ? row - floor(row) : ceil(row) - row);

            switch (self.gridMode)
            {
                case GridModeGeographic: {
                    label1 = [NSString stringWithFormat:@"%.0f˚", degrees];
                    label2 = [NSString stringWithFormat:@"%02.0f'", fraction * 60.0];
                    break;
                }
                case GridModeGeographicDecimal:
                case GridModeUTM:
                default: {
                    label1 = [NSString stringWithFormat:@"%.0f", degrees];
                    label2 = [NSString stringWithFormat:@"%02.0f", fraction * 100.0];
                }
            }

            // potential problem: some of these functions are not thread safe, so the app will crash
            // if any other thread uses these functions outside of the @synchronized
            @synchronized (self)
            {
                CGSize label1Size = [label1 sizeWithFont:self.majorLabelFont];
                CGSize label2Size = [label2 sizeWithFont:self.minorLabelFont];

                CGFloat upperBorder = yCoordinate - MAX((label1Size.height / 2.0), (label2Size.height / 2.0));
                CGRect labelBackgroundRect = CGRectMake(xCoordinate - label1Size.width - 3.0, upperBorder - 1.0, label1Size.width + label2Size.width + 8.0, MAX(label1Size.height, label2Size.height) + 2.0);

                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                UIRectFill(labelBackgroundRect);

                CGContextSetFillColorWithColor(context, self.majorLabelColor.CGColor);
                [label1 drawAtPoint:CGPointMake(xCoordinate - label1Size.width - 1.0, upperBorder) withFont:self.majorLabelFont];

                CGContextSetFillColorWithColor(context, self.minorLabelColor.CGColor);
                [label2 drawAtPoint:CGPointMake(xCoordinate + 1.0, upperBorder) withFont:self.minorLabelFont];
            }
        }
    }

    for (double column=left; column<=right; column += gridSpacing)
    {
        if (self.gridLabelInterval > 1 && fmod(round(column / gridSpacing), (double)self.gridLabelInterval) != 0)
            continue;

        CGFloat xCoordinate = ((column - southWest.longitude) / coordinatesLongitudeSpan) * paddedTileSideLength;

        for (double row = (top + (gridSpacing/2.0)); row >= (bottom - (gridSpacing/2.0)); row -= gridSpacing)
        {
            CGFloat yCoordinate = paddedTileSideLength - (((row - southWest.latitude) / coordinatesLatitudeSpan) * paddedTileSideLength);

            NSString *label1 = nil, *label2 = nil;
            double degrees = (column > 0.0 ? floor(column) : ceil(column));
            double fraction = (column > 0.0 ? column - floor(column) : ceil(column) - column);

            switch (self.gridMode)
            {
                case GridModeGeographic: {
                    label1 = [NSString stringWithFormat:@"%.0f˚", degrees];
                    label2 = [NSString stringWithFormat:@"%02.0f'", fraction * 60.0];
                    break;
                }
                case GridModeGeographicDecimal:
                case GridModeUTM:
                default: {
                    label1 = [NSString stringWithFormat:@"%.0f", degrees];
                    label2 = [NSString stringWithFormat:@"%02.0f", fraction * 100.0];
                }
            }

            @synchronized (self)
            {
                CGSize label1Size = [label1 sizeWithFont:self.majorLabelFont];
                CGSize label2Size = [label2 sizeWithFont:self.minorLabelFont];

                CGFloat upperBorder = yCoordinate - MAX((label1Size.height / 2.0), (label2Size.height / 2.0));
                CGRect labelBackgroundRect = CGRectMake(xCoordinate - label1Size.width - 3.0, upperBorder - 1.0, label1Size.width + label2Size.width + 8.0, MAX(label1Size.height, label2Size.height) + 2.0);

                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                UIRectFill(labelBackgroundRect);

                CGContextSetFillColorWithColor(context, self.majorLabelColor.CGColor);
                [label1 drawAtPoint:CGPointMake(xCoordinate - label1Size.width - 1.0, upperBorder) withFont:self.majorLabelFont];

                CGContextSetFillColorWithColor(context, self.minorLabelColor.CGColor);
                [label2 drawAtPoint:CGPointMake(xCoordinate + 1.0, upperBorder) withFont:self.minorLabelFont];
            }
        }
    }

    // Image

    image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(kTileSidePadding, kTileSidePadding, self.tileSideLength, self.tileSideLength));
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    if (image)
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];

	return image;
}

- (NSString *)uniqueTilecacheKey
{
    NSString *tileCacheKey = nil;

    switch (self.gridMode)
    {
        case GridModeGeographic: {
            tileCacheKey = @"RMCoordinateGridGeographic";
            break;
        }
        case GridModeGeographicDecimal:
        {
            tileCacheKey = @"RMCoordinateGridDecimal";
            break;
        }
        case GridModeUTM: {
            tileCacheKey = @"RMCoordinateGridUTM";
            break;
        }
    }

    if ( ! tileCacheKey)
        tileCacheKey = @"RMCoordinateGrid";

    return tileCacheKey;
}

- (NSString *)shortName
{
	return @"Coordinate grid";
}

- (NSString *)longDescription
{
	return [self shortName];
}

- (NSString *)shortAttribution
{
	return @"n/a";
}

- (NSString *)longAttribution
{
	return @"n/a";
}

@end
