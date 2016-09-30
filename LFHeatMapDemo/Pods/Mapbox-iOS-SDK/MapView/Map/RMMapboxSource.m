//
//  RMMapboxSource.m
//
//  Created by Justin R. Miller on 5/17/11.
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

#import "RMMapboxSource.h"

#import "RMMapView.h"
#import "RMPointAnnotation.h"
#import "RMConfiguration.h"

@interface RMMapboxSource ()

@property (nonatomic, strong) NSDictionary *infoDictionary;
@property (nonatomic, strong) NSString *tileJSON;
@property (nonatomic, strong) NSString *uniqueTilecacheKey;

@end

#pragma mark -

@implementation RMMapboxSource

@synthesize infoDictionary=_infoDictionary, tileJSON=_tileJSON, imageQuality=_imageQuality, dataQueue=_dataQueue, uniqueTilecacheKey=_uniqueTilecacheKey;

- (id)init
{
    return [self initWithMapID:kMapboxPlaceholderMapID];
}

- (id)initWithMapID:(NSString *)mapID
{
    return [self initWithMapID:mapID enablingDataOnMapView:nil];
}

- (id)initWithTileJSON:(NSString *)tileJSON
{
    return [self initWithTileJSON:tileJSON enablingDataOnMapView:nil];
}

- (id)initWithTileJSON:(NSString *)tileJSON enablingDataOnMapView:(RMMapView *)mapView
{
    if (self = [super init])
    {
        _dataQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);

        _infoDictionary = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[tileJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:0
                                                                            error:nil];
        if ( ! _infoDictionary)
            return nil;

        _tileJSON = tileJSON;

        if ([_infoDictionary[@"id"] hasPrefix:@"examples."])
            RMLog(@"Using watermarked example map ID %@. Please go to https://mapbox.com and create your own map style.", _infoDictionary[@"id"]);

        _uniqueTilecacheKey = [NSString stringWithFormat:@"Mapbox-%@%@%@", _infoDictionary[@"id"], (_infoDictionary[@"version"] ? [@"-" stringByAppendingString:_infoDictionary[@"version"]] : @""),
            ([RMMapboxSource isUsingLargeTiles] ? @"-512" : @"")];

        id dataObject = nil;
        
        if (mapView && (dataObject = _infoDictionary[@"data"]) && dataObject)
        {
            dispatch_async(_dataQueue, ^(void)
            {
                if ([dataObject isKindOfClass:[NSArray class]] && [[dataObject objectAtIndex:0] isKindOfClass:[NSString class]])
                {
                    NSURL *dataURL = [NSURL URLWithString:[dataObject objectAtIndex:0]];
                    
                    NSMutableString *jsonString = nil;
                    
                    if (dataURL && (jsonString = [NSMutableString brandedStringWithContentsOfURL:dataURL encoding:NSUTF8StringEncoding error:nil]) && jsonString)
                    {
                        if ([jsonString hasPrefix:@"grid("])
                        {
                            [jsonString replaceCharactersInRange:NSMakeRange(0, 5)                       withString:@""];
                            [jsonString replaceCharactersInRange:NSMakeRange([jsonString length] - 2, 2) withString:@""];
                        }
                        
                        id jsonObject = nil;
                        
                        if ((jsonObject = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]) && [jsonObject isKindOfClass:[NSDictionary class]])
                        {
                            for (NSDictionary *feature in jsonObject[@"features"])
                            {
                                if ([feature[@"geometry"][@"type"] isEqualToString:@"Point"])
                                {
                                    NSDictionary *properties = feature[@"properties"];

                                    CLLocationCoordinate2D coordinate = {
                                        .longitude = [feature[@"geometry"][@"coordinates"][0] floatValue],
                                        .latitude  = [feature[@"geometry"][@"coordinates"][1] floatValue]
                                    };

                                    RMAnnotation *annotation = nil;

                                    if ([mapView.delegate respondsToSelector:@selector(mapView:layerForAnnotation:)])
                                        annotation = [RMAnnotation annotationWithMapView:mapView coordinate:coordinate andTitle:properties[@"title"]];
                                    else
                                        annotation = [RMPointAnnotation annotationWithMapView:mapView coordinate:coordinate andTitle:properties[@"title"]];

                                    annotation.userInfo = properties;

                                    dispatch_async(dispatch_get_main_queue(), ^(void)
                                    {
                                        [mapView addAnnotation:annotation];
                                    });
                                }
                            }
                        }
                    }
                }
            });            
        }
    }
    
    return self;
}

- (id)initWithReferenceURL:(NSURL *)referenceURL
{
    return [self initWithReferenceURL:referenceURL enablingDataOnMapView:nil];
}

- (id)initWithReferenceURL:(NSURL *)referenceURL enablingDataOnMapView:(RMMapView *)mapView
{
    id dataObject = nil;
    
    if ([[referenceURL pathExtension] isEqualToString:@"jsonp"])
    {
        referenceURL = [NSURL URLWithString:[[referenceURL absoluteString] stringByReplacingOccurrencesOfString:@".jsonp"
                                                                                                     withString:@".json"
                                                                                                        options:NSAnchoredSearch & NSBackwardsSearch
                                                                                                          range:NSMakeRange(0, [[referenceURL absoluteString] length])]];
    }
    
    if ([[referenceURL pathExtension] isEqualToString:@"json"] && (dataObject = [NSString brandedStringWithContentsOfURL:referenceURL encoding:NSUTF8StringEncoding error:nil]) && dataObject)
    {
        return [self initWithTileJSON:dataObject enablingDataOnMapView:mapView];
    }

    return nil;
}

- (id)initWithMapID:(NSString *)mapID enablingDataOnMapView:(RMMapView *)mapView
{
    return [self initWithReferenceURL:[self canonicalURLForMapID:mapID] enablingDataOnMapView:mapView];
}

- (void)dealloc
{
#if ! OS_OBJECT_USE_OBJC
    if (_dataQueue)
        dispatch_release(_dataQueue);
#endif
}

#pragma mark 

- (NSURL *)canonicalURLForMapID:(NSString *)mapID
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.tiles.mapbox.com/v4/%@.json?secure%@", mapID,
                [@"&access_token=" stringByAppendingString:[[RMConfiguration sharedInstance] accessToken]]]];
}

- (NSURL *)tileJSONURL
{
    return [self canonicalURLForMapID:self.infoDictionary[@"id"]];
}

- (NSURL *)URLForTile:(RMTile)tile
{
    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = tile.y;

    if (self.infoDictionary[@"scheme"] && [self.infoDictionary[@"scheme"] isEqual:@"tms"])
        y = pow(2, zoom) - tile.y - 1;

    NSString *tileURLString = nil;

    if (self.infoDictionary[@"tiles"])
        tileURLString = self.infoDictionary[@"tiles"][0];

    else
        tileURLString = self.infoDictionary[@"tileURL"];

    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{z}" withString:[[NSNumber numberWithInteger:zoom] stringValue]];
    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{x}" withString:[[NSNumber numberWithInteger:x]    stringValue]];
    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{y}" withString:[[NSNumber numberWithInteger:y]    stringValue]];

    if ([[UIScreen mainScreen] scale] > 1.0)
        tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"];

    if (_imageQuality != RMMapboxSourceQualityFull)
    {
        NSString *qualityExtension = nil;

        switch (_imageQuality)
        {
            case RMMapboxSourceQualityPNG32:
            {
                qualityExtension = @".png32";
                break;
            }
            case RMMapboxSourceQualityPNG64:
            {
                qualityExtension = @".png64";
                break;
            }
            case RMMapboxSourceQualityPNG128:
            {
                qualityExtension = @".png128";
                break;
            }
            case RMMapboxSourceQualityPNG256:
            {
                qualityExtension = @".png256";
                break;
            }
            case RMMapboxSourceQualityJPEG70:
            {
                qualityExtension = @".jpg70";
                break;
            }
            case RMMapboxSourceQualityJPEG80:
            {
                qualityExtension = @".jpg80";
                break;
            }
            case RMMapboxSourceQualityJPEG90:
            {
                qualityExtension = @".jpg90";
                break;
            }
            case RMMapboxSourceQualityFull:
            default:
            {
                qualityExtension = @".png";
                break;
            }
        }

        tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@".png"
                                                                 withString:qualityExtension
                                                                    options:NSAnchoredSearch | NSBackwardsSearch
                                                                      range:NSMakeRange(0, [tileURLString length])];
    }

	return [NSURL URLWithString:tileURLString];
}

- (float)minZoom
{
    return [self.infoDictionary[@"minzoom"] floatValue];
}

- (float)maxZoom
{
    return [self.infoDictionary[@"maxzoom"] floatValue];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    id bounds = self.infoDictionary[@"bounds"];

    NSArray *parts = nil;

    if ([bounds isKindOfClass:[NSArray class]])
        parts = bounds;

    else
        parts = [bounds componentsSeparatedByString:@","];

    if ([parts count] == 4)
    {
        RMSphericalTrapezium bounds = {
            .southWest = {
                .longitude = [[parts objectAtIndex:0] doubleValue],
                .latitude  = [[parts objectAtIndex:1] doubleValue],
            },
            .northEast = {
                .longitude = [[parts objectAtIndex:2] doubleValue],
                .latitude  = [[parts objectAtIndex:3] doubleValue],
            },
        };

        return bounds;
    }

    return kMapboxDefaultLatLonBoundingBox;
}

- (BOOL)coversFullWorld
{
    RMSphericalTrapezium ownBounds     = [self latitudeLongitudeBoundingBox];
    RMSphericalTrapezium defaultBounds = kMapboxDefaultLatLonBoundingBox;

    if (ownBounds.southWest.longitude <= defaultBounds.southWest.longitude + 10 && 
        ownBounds.northEast.longitude >= defaultBounds.northEast.longitude - 10)
        return YES;

    return NO;
}

- (NSString *)legend
{
    return self.infoDictionary[@"legend"];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    if (self.infoDictionary[@"center"])
    {
        return CLLocationCoordinate2DMake([self.infoDictionary[@"center"][1] doubleValue],
                                          [self.infoDictionary[@"center"][0] doubleValue]);
    }
    
    return CLLocationCoordinate2DMake(0, 0);
}

- (float)centerZoom
{
    if (self.infoDictionary[@"center"])
    {
        return [self.infoDictionary[@"center"][2] floatValue];
    }
    
    return roundf(([self maxZoom] + [self minZoom]) / 2);
}

+ (BOOL)isUsingLargeTiles
{
    return ([[RMConfiguration sharedInstance] accessToken] && [[UIScreen mainScreen] scale] > 1.0);
}

- (NSString *)uniqueTilecacheKey
{
    return _uniqueTilecacheKey;
}

- (NSUInteger)tileSideLength
{
    return ([RMMapboxSource isUsingLargeTiles] ? 512 : kMapboxDefaultTileSize);
}

- (NSString *)shortName
{
	return self.infoDictionary[@"name"];
}

- (NSString *)longDescription
{
	return self.infoDictionary[@"description"];
}

- (NSString *)shortAttribution
{
	return self.infoDictionary[@"attribution"];
}

- (NSString *)longAttribution
{
	return [self shortAttribution];
}

@end
