//
//  RMInteractiveSource.m
//
//  Created by Justin R. Miller on 6/22/11.
//  Copyright 2012-2013 Mapbox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of Mapbox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RMInteractiveSource.h"

#import "RMConfiguration.h"

#import "FMDB.h"

#import "GRMustache.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include "zlib.h"

@protocol RMInteractiveSourcePrivate <RMInteractiveSource>

// This is the stuff that interactive tile sources need to do, but 
// that you don't interact with in a public way.

@required

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterTemplate;

@end

#pragma mark RMMapView

@interface RMMapView (RMInteractiveSourcePrivate) <RMInteractiveSourcePrivate>

- (id <RMTileSource, RMInteractiveSource>)interactiveTileSource;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point;
- (NSString *)interactivityFormatterTemplate;

@end

@implementation RMMapView (RMInteractiveSource)

- (id <RMTileSource, RMInteractiveSource>)interactiveTileSource
{
    id <RMTileSource, RMInteractiveSource>interactiveTileSource = nil;
    
    // currently, we iterate top-down and return the first interactive source
    //
    for (id <RMTileSource>source in [[self.tileSources reverseObjectEnumerator] allObjects])
    {
        if (([source isKindOfClass:[RMMBTilesSource class]] || [source isKindOfClass:[RMMapboxSource class]]) &&
            [source conformsToProtocol:@protocol(RMInteractiveSource)]                                        &&
            [(id <RMInteractiveSource>)source supportsInteractivity])
        {
            interactiveTileSource = (id <RMTileSource, RMInteractiveSource>)source;
            
            break;
        }
    }
    
    return interactiveTileSource;
}

- (BOOL)supportsInteractivity
{
    return ([self interactiveTileSource] != nil);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point
{
    return [(id <RMInteractiveSourcePrivate>)[self interactiveTileSource] interactivityDictionaryForPoint:point inMapView:self];
}

- (NSString *)interactivityFormatterTemplate
{
    return [(id <RMInteractiveSourcePrivate>)[self interactiveTileSource] interactivityFormatterTemplate];
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point
{
    return [(id <RMInteractiveSourcePrivate>)[self interactiveTileSource] formattedOutputOfType:outputType forPoint:point inMapView:self];
}

@end

#pragma mark - Utilities

RMTilePoint RMInteractiveSourceNormalizedTilePointForMapView(CGPoint point, RMMapView *mapView);

RMTilePoint RMInteractiveSourceNormalizedTilePointForMapView(CGPoint point, RMMapView *mapView)
{
    // This function figures out which RMTile a given point falls on and where
    // in that tile the point is for a given map view. This is required because 
    // tiles get stitched together on render and touches are no longer 
    // correlated to tiles, unlike on websites where the tile is still an 
    // actual tile image.
    
    // get map scroll view
    //
    UIScrollView *scrollView = [mapView valueForKey:@"mapScrollView"];
    
    // get closest whole zoom
    //
    int tileZoom = (int)(roundf(mapView.zoom));
    
    // get displayed fractional zoom factor
    //
    float factor = scrollView.contentSize.width / (powf(2, tileZoom) * 256);
    
    // get point in even-zoom space
    //
    float evenX = (scrollView.contentOffset.x + point.x) / factor;
    float evenY = (scrollView.contentOffset.y + point.y) / factor;
    
    // normalize for the tile touched
    //
    int normalizedX = (int)evenX % 256;
    int normalizedY = (int)evenY % 256;
    
    // determine lat & lon of touch
    //
    CLLocationCoordinate2D touchLocation = [mapView pixelToCoordinate:point];
    
    // use lat & lon to determine tile (per http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
    //
    int tileX = (int)(floor((touchLocation.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
    int tileY = (int)(floor((1.0 - log(tan(touchLocation.latitude * M_PI / 180.0) + 1.0 / \
                                       cos(touchLocation.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
    
    // flip y for TMS and all MBTiles
    //
    id <RMTileSource>interactiveSource = [mapView interactiveTileSource];
    
    if (([interactiveSource isKindOfClass:[RMMapboxSource class]] && [((RMMapboxSource *)interactiveSource).infoDictionary objectForKey:@"scheme"] && [[((RMMapboxSource *)interactiveSource).infoDictionary objectForKey:@"scheme"] isEqual:@"tms"]) || [interactiveSource isKindOfClass:[RMMBTilesSource class]])
    {
        tileY = pow(2.0, tileZoom) - tileY - 1.0;
    }
    
    RMTile tile = {
        .zoom = tileZoom,
        .x    = tileX,
        .y    = tileY,
    };
    
    RMTilePoint tilePoint;
    
    tilePoint.tile   = tile;
    tilePoint.offset = CGPointMake(normalizedX, normalizedY);
    
    return tilePoint;
}

@interface RMInteractiveSource : NSObject

// These are routines common to all interactive tile source types, 
// made handy as class methods for convenience.

+ (NSString *)keyNameForPoint:(CGPoint)point inGrid:(NSDictionary *)grid;
+ (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)type forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

@implementation RMInteractiveSource

+ (NSString *)keyNameForPoint:(CGPoint)point inGrid:(NSDictionary *)grid
{
    NSString *keyName = nil;
    
    if ([grid objectForKey:@"grid"] && [grid objectForKey:@"keys"])
    {
        NSArray *rows = [grid objectForKey:@"grid"];
        NSArray *keys = [grid objectForKey:@"keys"];
        
        if (rows && [rows isKindOfClass:[NSArray class]] && keys && [keys isKindOfClass:[NSArray class]])
        {
            if ([rows count] > 0)
            {
                // get grid coordinates per https://github.com/mapbox/mbtiles-spec/blob/master/1.1/utfgrid.md
                //
                int factor = 256 / [rows count];
                int row    = point.y / factor;
                int col    = point.x / factor;
                
                if (row < [rows count])
                {
                    NSString *line = [rows objectAtIndex:row];
                    
                    if (col < [line length])
                    {
                        unichar theChar = [line characterAtIndex:col];
                        unsigned short decoded = theChar;
                        
                        if (decoded >= 93)
                            decoded--;
                        
                        if (decoded >=35)
                            decoded--;
                        
                        decoded = decoded - 32;
                        
                        if (decoded < [keys count])
                            keyName = [keys objectAtIndex:decoded];
                    }
                }
            }
        }
    }
    
    return keyName;
}

+ (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    NSString *formattedOutput = nil;
    
    id <RMTileSource, RMInteractiveSource>source = [mapView interactiveTileSource];
    
    NSDictionary *interactivityDictionary = [(id <RMInteractiveSourcePrivate>)source interactivityDictionaryForPoint:point inMapView:mapView];
    
    if (interactivityDictionary)
    {
        // As of UTFGrid 1.2, JavaScript formatters are no longer supported. We 
        // prefer Mustache-based templating instead for security reasons.
        //
        // More on Mustache: http://mustache.github.com
        //
        NSString *formatterTemplate = [(id <RMInteractiveSourcePrivate>)source interactivityFormatterTemplate];

        if (formatterTemplate)
        {
            NSMutableDictionary *infoObject = [NSJSONSerialization JSONObjectWithData:[[interactivityDictionary objectForKey:@"keyJSON"] dataUsingEncoding:NSUTF8StringEncoding]
                                                                              options:NSJSONReadingMutableContainers
                                                                                error:nil];

#ifdef DEBUG
            [GRMustache preventNSUndefinedKeyExceptionAttack];
#endif

            switch (outputType)
            {
                case RMInteractiveSourceOutputTypeTeaser:
                {
                    [infoObject setValue:[NSNumber numberWithBool:YES] forKey:@"__teaser__"];
                    
                    formattedOutput = [GRMustacheTemplate renderObject:infoObject fromString:formatterTemplate error:NULL];

                    break;
                }
                case RMInteractiveSourceOutputTypeFull:
                default:
                {
                    [infoObject setValue:[NSNumber numberWithBool:YES] forKey:@"__full__"];
                    
                    formattedOutput = [GRMustacheTemplate renderObject:infoObject fromString:formatterTemplate error:NULL];

                    break;
                }
            }
        }
    }
    
    return formattedOutput;
}

@end

// This is a category for dealing with gzip-deflated data
// over the wire or in MBTiles sources. 

@interface NSData (RMInteractiveSource)

- (NSData *)gzipInflate;

@end

@implementation NSData (RMInteractiveSource)

- (NSData *)gzipInflate
{
    // from http://cocoadev.com/index.pl?NSDataCategory
    //
    if ([self length] == 0) return self;
    
    NSUInteger full_length = [self length];
    NSUInteger half_length = [self length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[self bytes];
    strm.avail_in = (unsigned int)[self length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

@end

#pragma mark - MBTiles

@interface RMMBTilesSource (RMInteractiveSourcePrivate) <RMInteractiveSourcePrivate>

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterTemplate;

@end

@implementation RMMBTilesSource (RMInteractiveSource)

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@, zooms %i-%i, %@", 
               [self class],
               [self shortName], 
               (int)[self minZoom], 
               (int)[self maxZoom], 
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    if ([self interactivityFormatterTemplate])
        return YES;
    
    return NO;
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
{
    RMTilePoint tilePoint = RMInteractiveSourceNormalizedTilePointForMapView(point, mapView);
    
    __block NSData *gridData = nil;
    
    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select grid from grids where zoom_level = ? and tile_column = ? and tile_row = ?", 
                                   [NSNumber numberWithShort:tilePoint.tile.zoom], 
                                   [NSNumber numberWithUnsignedInt:tilePoint.tile.x], 
                                   [NSNumber numberWithUnsignedInt:tilePoint.tile.y]];
        
        if ( ! [db hadError])
        {
            [results next];
            
            if ([results hasAnotherRow])
                gridData = [results dataForColumnIndex:0];
        }
        
        [results close];
    }];
    
    if (gridData)
    {
        NSData *inflatedData = [gridData gzipInflate];
        NSString *gridString = [[NSString alloc] initWithData:inflatedData encoding:NSUTF8StringEncoding];
        
        id grid = [NSJSONSerialization JSONObjectWithData:[gridString dataUsingEncoding:NSUTF8StringEncoding]
                                                  options:0
                                                    error:nil];
        
        if (grid && [grid isKindOfClass:[NSDictionary class]])
        {
            NSString *keyName = [RMInteractiveSource keyNameForPoint:tilePoint.offset inGrid:grid];
            
            if (keyName)
            {
                // get JSON for this grid point
                //
                __block NSString *jsonString = nil;
                
                [queue inDatabase:^(FMDatabase *db)
                {
                    FMResultSet *results = [db executeQuery:@"select key_json from grid_data where zoom_level = ? and tile_column = ? and tile_row = ? and key_name = ?", 
                                               [NSNumber numberWithShort:tilePoint.tile.zoom],
                                               [NSNumber numberWithShort:tilePoint.tile.x],
                                               [NSNumber numberWithShort:tilePoint.tile.y],
                                               keyName];
                    
                    if ( ! [db hadError])
                    {
                        [results next];
                    
                        if ([results hasAnotherRow])
                            jsonString = [results stringForColumn:@"key_json"];
                    }
                    
                    [results close];
                }];
                
                if (jsonString)
                {
                    return [NSDictionary dictionaryWithObjectsAndKeys:keyName,    @"keyName",
                                                                      jsonString, @"keyJSON", 
                                                                      nil];
                }
            }
        }
    }
    
    return nil;    
}

- (NSString *)interactivityFormatterTemplate
{
    __block NSString *template = nil;
    
    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'template'"];
        
        if ( ! [db hadError])
        {
            [results next];
        
            if ([results hasAnotherRow])
                template = [results stringForColumn:@"value"];
        }
        
        [results close];
    }];
    
    return ([template length] ? template : nil);
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    if ([self supportsInteractivity])
        return [RMInteractiveSource formattedOutputOfType:outputType forPoint:point inMapView:mapView];
    
    return nil;
}

@end

#pragma mark - Mapbox

@interface RMMapboxSource (RMInteractiveSourcePrivate) <RMInteractiveSourcePrivate>

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterTemplate;

@end

@implementation RMMapboxSource (RMInteractiveSource)

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@, zooms %i-%i, %@", 
               [self class],
               [self shortName], 
               (int)[self minZoom], 
               (int)[self maxZoom], 
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    if ([self interactivityFormatterTemplate])
        return YES;
    
    return NO;
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
{
    NSString *gridURLString = nil;
    
    if ([self.infoDictionary objectForKey:@"grids"] && [[self.infoDictionary objectForKey:@"grids"] isKindOfClass:[NSArray class]])
        gridURLString = [[self.infoDictionary objectForKey:@"grids"] objectAtIndex:0];
    else
        gridURLString = [self.infoDictionary objectForKey:@"gridURL"];
    
    if ([gridURLString length])
    {
        RMTilePoint tilePoint = RMInteractiveSourceNormalizedTilePointForMapView(point, mapView);
        
        NSInteger zoom = tilePoint.tile.zoom;
        NSInteger x    = tilePoint.tile.x;
        NSInteger y    = tilePoint.tile.y;
        
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{z}" withString:[[NSNumber numberWithInteger:zoom] stringValue]];
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{x}" withString:[[NSNumber numberWithInteger:x]    stringValue]];
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{y}" withString:[[NSNumber numberWithInteger:y]    stringValue]];

        // ensure JSONP format
        //
        if (NSEqualRanges([gridURLString rangeOfString:@"callback=grid"], NSMakeRange(NSNotFound, 0)))
        {
            if ([[NSURL URLWithString:gridURLString] query])
            {
                gridURLString = [gridURLString stringByAppendingString:@"&callback=grid"];
            }
            else
            {
                gridURLString = [gridURLString stringByAppendingString:@"?callback=grid"];
            }
        }

        // get the data for this tile
        //
        NSData *gridData = [NSData brandedDataWithContentsOfURL:[NSURL URLWithString:gridURLString]];
        
        if (gridData)
        {
            NSMutableString *gridString = [[NSMutableString alloc] initWithData:gridData encoding:NSUTF8StringEncoding];
            
            // remove JSONP 'grid(' and ');' bits
            //
            if ([gridString hasPrefix:@"grid("])
            {
                [gridString replaceCharactersInRange:NSMakeRange(0, 5)                       withString:@""];
                [gridString replaceCharactersInRange:NSMakeRange([gridString length] - 2, 2) withString:@""];
            }
            
            id grid = [NSJSONSerialization JSONObjectWithData:[gridString dataUsingEncoding:NSUTF8StringEncoding]
                                                      options:0
                                                        error:nil];
            
            if (grid && [grid isKindOfClass:[NSDictionary class]])
            {
                NSString *keyName = [RMInteractiveSource keyNameForPoint:tilePoint.offset inGrid:grid];
                
                if (keyName)
                {
                    NSDictionary *data = [grid objectForKey:@"data"];
                    
                    if (data && [data objectForKey:keyName])
                    {
                        NSData   *jsonData   = [NSJSONSerialization dataWithJSONObject:[data objectForKey:keyName] options:0 error:nil];
                        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        
                        return [NSDictionary dictionaryWithObjectsAndKeys:keyName,    @"keyName",
                                                                          jsonString, @"keyJSON",
                                                                          nil];
                    }
                }
            }
        }
    }
    
    return nil;    
}

- (NSString *)interactivityFormatterTemplate
{
    if ([self.infoDictionary objectForKey:@"template"] && [[self.infoDictionary objectForKey:@"template"] length])
        return [self.infoDictionary objectForKey:@"template"];
    
    return nil;
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    if ([self supportsInteractivity])
        return [RMInteractiveSource formattedOutputOfType:outputType forPoint:point inMapView:mapView];
    
    return nil;
}

@end
