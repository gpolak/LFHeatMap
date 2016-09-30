//
//  RMConfiguration.m
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

#import "RMConfiguration.h"

static RMConfiguration *RMConfigurationSharedInstance = nil;

@implementation NSURLConnection (RMUserAgent)

+ (NSData *)sendBrandedSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:request.URL
                                                              cachePolicy:request.cachePolicy
                                                          timeoutInterval:request.timeoutInterval];

    [newRequest setValue:[[RMConfiguration sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];

    return [NSURLConnection sendSynchronousRequest:newRequest returningResponse:response error:error];
}

@end

#pragma mark -

@implementation NSData (RMUserAgent)

+ (instancetype)brandedDataWithContentsOfURL:(NSURL *)aURL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aURL];

    [request setValue:[[RMConfiguration sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];

    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

@end

#pragma mark -

@implementation NSString (RMUserAgent)

+ (instancetype)brandedStringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)enc error:(NSError **)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setValue:[[RMConfiguration sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];

    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:error];

    if ( ! returnData)
        return nil;

    return [[[self class] alloc] initWithData:returnData encoding:enc];
}

@end

#pragma mark -

@implementation RMConfiguration
{
    id _propertyList;
}

@synthesize userAgent=_userAgent;
@synthesize accessToken=_accessToken;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RMConfigurationSharedInstance = [[RMConfiguration alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"routeme" ofType:@"plist"]];
    });

    return RMConfigurationSharedInstance;
}

+ (instancetype)configuration
{
    return [[self class] sharedInstance];
}

- (RMConfiguration *)initWithPath:(NSString *)path
{
    if (!(self = [super init]))
        return nil;

    _userAgent = [NSString stringWithFormat:@"Mapbox iOS SDK (%@/%@)", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];

    if (path == nil)
    {
        _propertyList = nil;
        return self;
    }

    RMLog(@"reading route-me configuration from %@", path);

    NSError *error = nil;
    NSData *plistData = [NSData dataWithContentsOfFile:path];

    _propertyList = [NSPropertyListSerialization propertyListWithData:plistData
                                                              options:NSPropertyListImmutable
                                                               format:NULL
                                                                error:&error];

    if ( ! _propertyList)
    {
        RMLog(@"problem reading route-me configuration from %@: %@", path, error);
    }

    return self;
}

- (NSString *)accessToken
{
    NSAssert(_accessToken, @"An access token is required in order to use the Mapbox API. Obtain a token on your Mapbox account page at https://www.mapbox.com/account/apps/.");

    return _accessToken;
}

- (NSDictionary *)cacheConfiguration
{
    if (_propertyList == nil)
        return nil;

    return [_propertyList objectForKey:@"caches"];
}

@end
