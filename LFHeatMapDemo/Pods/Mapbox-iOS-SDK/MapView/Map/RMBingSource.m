//
//  RMBingSource.m
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

#import "RMBingSource.h"

#import "RMConfiguration.h"

@implementation RMBingSource
{
    NSString *_mapsKey;
    NSString *_imageURLString;
    NSString *_uniqueTilecacheKey;
    RMBingImagerySet _imagerySet;
}

- (id)initWithMapsKey:(NSString *)mapsKey
{
    return [self initWithMapsKey:mapsKey forImagerySet:RMBingImagerySetRoad];
}

- (id)initWithMapsKey:(NSString *)mapsKey forImagerySet:(RMBingImagerySet)imagerySet;
{
    if (self = [super init])
    {
        _mapsKey = mapsKey;

        _imagerySet = imagerySet;

        _uniqueTilecacheKey = [NSString stringWithFormat:@"Bing%lu", (unsigned long)_imagerySet];

        self.minZoom = 1;
        self.maxZoom = 21;

        return self;
    }

    return nil;
}

- (NSURL *)URLForTile:(RMTile)tile
{
    if ( ! _imageURLString)
    {
        NSString *imagerySetString = nil;

        if (_imagerySet == RMBingImagerySetAerial)
            imagerySetString = @"Aerial";
        else if (_imagerySet == RMBingImagerySetAerialWithLabels)
            imagerySetString = @"AerialWithLabels";
        else
            imagerySetString = @"Road";

        NSURL *metadataURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://dev.virtualearth.net/REST/v1/Imagery/Metadata/%@?key=%@", imagerySetString, _mapsKey]];

        NSData *metadataData = [NSData brandedDataWithContentsOfURL:metadataURL];

        if ( ! metadataData)
            return nil;

        id metadata = [NSJSONSerialization JSONObjectWithData:metadataData options:0 error:NULL];

        if (metadata && [metadata isKindOfClass:[NSDictionary class]] && [[metadata objectForKey:@"statusCode"] intValue] == 200)
        {
            NSDictionary *resources = [[[[(NSDictionary *)metadata objectForKey:@"resourceSets"] objectAtIndex:0] objectForKey:@"resources"] objectAtIndex:0];

            _imageURLString = [[[resources objectForKey:@"imageUrl"] stringByReplacingOccurrencesOfString:@"{subdomain}"
                                                                                               withString:[[resources objectForKey:@"imageUrlSubdomains"] objectAtIndex:0]] copy];
        }
    }

    if ( ! _imageURLString)
        return nil;

    NSMutableString *tileURLString = [NSMutableString stringWithString:_imageURLString];

    [tileURLString replaceOccurrencesOfString:@"{culture}" withString:@"en" options:0 range:NSMakeRange(0, [tileURLString length])];

    NSMutableString *quadKey = [NSMutableString string];

    for (int i = tile.zoom; i > 0; i--)
    {
        int digit = 0;

        int mask = 1 << (i - 1);

        if ((tile.x & mask) != 0)
            digit++;

        if ((tile.y & mask) != 0)
        {
            digit++;
            digit++;
        }

        [quadKey appendString:[NSString stringWithFormat:@"%i", digit]];
    }

    [tileURLString replaceOccurrencesOfString:@"{quadkey}" withString:quadKey options:0 range:NSMakeRange(0, [tileURLString length])];

    return [NSURL URLWithString:tileURLString];
}

- (NSString *)uniqueTilecacheKey
{
	return _uniqueTilecacheKey;
}

- (NSString *)shortName
{
	return @"Bing";
}

- (NSString *)longDescription
{
	return @"Microsoft Bing Maps";
}

- (NSString *)shortAttribution
{
	return @"Copyright © 2013 Microsoft";
}

- (NSString *)longAttribution
{
	return @"Copyright © 2013 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.";
}

@end
