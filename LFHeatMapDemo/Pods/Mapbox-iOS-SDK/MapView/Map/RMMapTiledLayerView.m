//
//  RMMapTiledLayerView.m
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

#import "RMMapTiledLayerView.h"

#import "RMMapView.h"
#import "RMTileSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMMBTilesSource.h"
#import "RMDBMapSource.h"
#import "RMAbstractWebMapSource.h"
#import "RMDatabaseCache.h"

#define IS_VALID_TILE_IMAGE(image) (image != nil && [image isKindOfClass:[UIImage class]])

@implementation RMMapTiledLayerView
{
    __weak RMMapView *_mapView;
    id <RMTileSource> _tileSource;
}

@synthesize useSnapshotRenderer = _useSnapshotRenderer;
@synthesize tileSource = _tileSource;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (CATiledLayer *)tiledLayer
{  
    return (CATiledLayer *)self.layer;
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView forTileSource:(id <RMTileSource>)aTileSource
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.opaque = NO;

    _mapView = aMapView;
    _tileSource = aTileSource;

    self.useSnapshotRenderer = NO;

    CATiledLayer *tiledLayer = [self tiledLayer];
    size_t levelsOf2xMagnification = _mapView.tileSourcesMaxZoom;
    if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0) levelsOf2xMagnification += 1;
    tiledLayer.levelsOfDetail = levelsOf2xMagnification;
    tiledLayer.levelsOfDetailBias = levelsOf2xMagnification;

    return self;
}

- (void)dealloc
{
    [_tileSource cancelAllDownloads];
    self.layer.contents = nil;
     _mapView = nil;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = 1.0f;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGRect rect   = CGContextGetClipBoundingBox(context);
    CGRect bounds = self.bounds;
    short zoom    = log2(bounds.size.width / rect.size.width);

//    NSLog(@"drawLayer: {{%f,%f},{%f,%f}}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    if (self.useSnapshotRenderer)
    {
        zoom = (short)ceilf(_mapView.adjustedZoomForRetinaDisplay);
        CGFloat rectSize = bounds.size.width / powf(2.0, (float)zoom);

        int x1 = floor(rect.origin.x / rectSize),
            x2 = floor((rect.origin.x + rect.size.width) / rectSize),
            y1 = floor(fabs(rect.origin.y / rectSize)),
            y2 = floor(fabs((rect.origin.y + rect.size.height) / rectSize));

//        NSLog(@"Tiles from x1:%d, y1:%d to x2:%d, y2:%d @ zoom %d", x1, y1, x2, y2, zoom);

        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            UIGraphicsPushContext(context);

            for (int x=x1; x<=x2; ++x)
            {
                for (int y=y1; y<=y2; ++y)
                {
                    UIImage *tileImage = [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]];

                    if (IS_VALID_TILE_IMAGE(tileImage))
                        [tileImage drawInRect:CGRectMake(x * rectSize, y * rectSize, rectSize, rectSize)];
                }
            }

            UIGraphicsPopContext();
        }
    }
    else
    {
        int x = floor(rect.origin.x / rect.size.width),
            y = floor(fabs(rect.origin.y / rect.size.height));

        if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
        {
            zoom--;
            x >>= 1;
            y >>= 1;
        }

//        NSLog(@"Tile @ x:%d, y:%d, zoom:%d", x, y, zoom);

        UIGraphicsPushContext(context);

        UIImage *tileImage = nil;

        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            RMDatabaseCache *databaseCache = nil;

            for (RMTileCache *componentCache in _mapView.tileCache.tileCaches)
                if ([componentCache isKindOfClass:[RMDatabaseCache class]])
                    databaseCache = (RMDatabaseCache *)componentCache;

            if ( ! [_tileSource isKindOfClass:[RMAbstractWebMapSource class]] || ! databaseCache || ! databaseCache.capacity)
            {
                // for non-web tiles, query the source directly since trivial blocking
                //
                tileImage = [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]];
            }
            else
            {
                // for non-local tiles, consult cache directly first (if possible)
                //
                if (_tileSource.isCacheable)
                    tileImage = [[_mapView tileCache] cachedImage:RMTileMake(x, y, zoom) withCacheKey:[_tileSource uniqueTilecacheKey]];

                if ( ! tileImage)
                {
                    // fire off an asynchronous retrieval
                    //
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                    {
                        // ensure only one request for a URL at a time
                        //
                        @synchronized ([(RMAbstractWebMapSource *)_tileSource URLsForTile:RMTileMake(x, y, zoom)])
                        {
                            // this will return quicker if cached since above attempt, else block on fetch
                            //
                            if (_tileSource.isCacheable && [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]])
                            {
                                dispatch_async(dispatch_get_main_queue(), ^(void)
                                {
                                    // do it all again for this tile, next time synchronously from cache
                                    //
                                    [self.layer setNeedsDisplayInRect:rect];
                                });
                            }
                        }
                    });
                }
            }
        }

        if ( ! tileImage)
        {
            if (_mapView.missingTilesDepth == 0)
            {
                tileImage = [RMTileImage errorTile];
            }
            else
            {
                NSUInteger currentTileDepth = 1, currentZoom = zoom - currentTileDepth;

                // tries to return lower zoom level tiles if a tile cannot be found
                while ( !tileImage && currentZoom >= _tileSource.minZoom && currentTileDepth <= _mapView.missingTilesDepth)
                {
                    float nextX = x / powf(2.0, (float)currentTileDepth),
                          nextY = y / powf(2.0, (float)currentTileDepth);
                    float nextTileX = floor(nextX),
                          nextTileY = floor(nextY);

                    tileImage = [_tileSource imageForTile:RMTileMake((int)nextTileX, (int)nextTileY, currentZoom) inCache:[_mapView tileCache]];

                    if (IS_VALID_TILE_IMAGE(tileImage))
                    {
                        // crop
                        float cropSize = 1.0 / powf(2.0, (float)currentTileDepth);

                        CGRect cropBounds = CGRectMake(tileImage.size.width * (nextX - nextTileX),
                                                       tileImage.size.height * (nextY - nextTileY),
                                                       tileImage.size.width * cropSize,
                                                       tileImage.size.height * cropSize);

                        CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                        tileImage = [UIImage imageWithCGImage:imageRef];
                        CGImageRelease(imageRef);

                        break;
                    }
                    else
                    {
                        tileImage = nil;
                    }

                    currentTileDepth++;
                    currentZoom = zoom - currentTileDepth;
                }
            }
        }

        if (IS_VALID_TILE_IMAGE(tileImage))
        {
            if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
            {
                // Crop the image
                float xCrop = (floor(rect.origin.x / rect.size.width) / 2.0) - x;
                float yCrop = (floor(rect.origin.y / rect.size.height) / 2.0) - y;

                CGRect cropBounds = CGRectMake(tileImage.size.width * xCrop,
                                               tileImage.size.height * yCrop,
                                               tileImage.size.width * 0.5,
                                               tileImage.size.height * 0.5);

                CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                tileImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }

            if (_mapView.debugTiles)
            {
                UIGraphicsBeginImageContext(tileImage.size);

                CGContextRef debugContext = UIGraphicsGetCurrentContext();

                CGRect debugRect = CGRectMake(0, 0, tileImage.size.width, tileImage.size.height);

                [tileImage drawInRect:debugRect];

                UIFont *font = [UIFont systemFontOfSize:32.0];

                CGContextSetStrokeColorWithColor(debugContext, [UIColor whiteColor].CGColor);
                CGContextSetLineWidth(debugContext, 2.0);
                CGContextSetShadowWithColor(debugContext, CGSizeMake(0.0, 0.0), 5.0, [UIColor blackColor].CGColor);

                CGContextStrokeRect(debugContext, debugRect);

                CGContextSetFillColorWithColor(debugContext, [UIColor whiteColor].CGColor);

                NSString *debugString = [NSString stringWithFormat:@"Zoom %d", zoom];
                CGSize debugSize1 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0, debugSize1.width, debugSize1.height) withFont:font];

                debugString = [NSString stringWithFormat:@"(%d, %d)", x, y];
                CGSize debugSize2 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0 + debugSize1.height + 5.0, debugSize2.width, debugSize2.height) withFont:font];

                tileImage = UIGraphicsGetImageFromCurrentImageContext();

                UIGraphicsEndImageContext();
            }

            [tileImage drawInRect:rect];
        }
        else
        {
//            NSLog(@"Invalid image for {%d,%d} @ %d", x, y, zoom);
        }

        UIGraphicsPopContext();
    }
}

@end
