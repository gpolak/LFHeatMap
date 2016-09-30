//
// RMAbstractWebMapSource.m
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

#import "RMAbstractWebMapSource.h"

#import "RMTileCache.h"
#import "RMConfiguration.h"

#define HTTP_404_NOT_FOUND 404

@implementation RMAbstractWebMapSource

@synthesize retryCount, requestTimeoutSeconds;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    self.retryCount = RMAbstractWebMapSourceDefaultRetryCount;
    self.requestTimeoutSeconds = RMAbstractWebMapSourceDefaultWaitSeconds;

    return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"URLForTile: invoked on RMAbstractWebMapSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSArray *)URLsForTile:(RMTile)tile
{
    return [NSArray arrayWithObjects:[self URLForTile:tile], nil];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];

    // Return NSNull here so that the RMMapTiledLayerView will try to
    // fetch another tile if missingTilesDepth > 0
    if ( ! [self tileSourceHasTile:tile])
        return (UIImage *)[NSNull null];

    if (self.isCacheable)
    {
        image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];

        if (image)
            return image;
    }

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
    });

    NSArray *URLs = [self URLsForTile:tile];

    if ([URLs count] == 0)
    {
        return nil;
    }
    else if ([URLs count] > 1)
    {
        // fill up collection array with placeholders
        //
        NSMutableArray *tilesData = [NSMutableArray arrayWithCapacity:[URLs count]];

        for (NSUInteger p = 0; p < [URLs count]; ++p)
            [tilesData addObject:[NSNull null]];

        dispatch_group_t fetchGroup = dispatch_group_create();

        for (NSUInteger u = 0; u < [URLs count]; ++u)
        {
            NSURL *currentURL = [URLs objectAtIndex:u];

            dispatch_group_async(fetchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
            {
                NSData *tileData = nil;

                for (NSUInteger try = 0; tileData == nil && try < self.retryCount; ++try)
                {
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:currentURL];
                    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
                    [request setTimeoutInterval:(self.requestTimeoutSeconds / (CGFloat)self.retryCount)];
                    tileData = [NSURLConnection sendBrandedSynchronousRequest:request returningResponse:nil error:nil];
                }

                if (tileData)
                {
                    @synchronized (self)
                    {
                        // safely put into collection array in proper order
                        //
                        [tilesData replaceObjectAtIndex:u withObject:tileData];
                    };
                }
            });
        }

        // wait for whole group of fetches (with retries) to finish, then clean up
        //
        dispatch_group_wait(fetchGroup, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * self.requestTimeoutSeconds));
#if ! OS_OBJECT_USE_OBJC
        dispatch_release(fetchGroup);
#endif

        // composite the collected images together
        //
        for (NSData *tileData in tilesData)
        {
            if (tileData && [tileData isKindOfClass:[NSData class]] && [tileData length])
            {
                if (image != nil)
                {
                    UIGraphicsBeginImageContext(image.size);
                    [image drawAtPoint:CGPointMake(0,0)];
                    [[UIImage imageWithData:tileData] drawAtPoint:CGPointMake(0,0)];

                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                else
                {
                    image = [UIImage imageWithData:tileData];
                }
            }
        }
    }
    else
    {
        for (NSUInteger try = 0; image == nil && try < self.retryCount; ++try)
        {
            NSHTTPURLResponse *response = nil;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[URLs objectAtIndex:0]];
            [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            [request setTimeoutInterval:(self.requestTimeoutSeconds / (CGFloat)self.retryCount)];
            image = [UIImage imageWithData:[NSURLConnection sendBrandedSynchronousRequest:request returningResponse:&response error:nil]];

            if (response.statusCode == HTTP_404_NOT_FOUND)
                break;
        }
    }

    if (image && self.isCacheable)
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRetrieved object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
    });

    return image;
}

@end
