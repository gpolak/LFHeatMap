//
//  RMConfiguration.h
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

#import <UIKit/UIKit.h>

/** The RMConfiguration object is a shared instance of the configuration for the library. */
@interface RMConfiguration : NSObject

/** @name Accessing the Configuration */

/** Access the shared instance of the configuration.
*   @return The shared configuration instance. */
+ (instancetype)sharedInstance;

/** Access the shared instance of the configuration. 
*   @return The shared configuration instance. */
+ (instancetype)configuration DEPRECATED_MSG_ATTRIBUTE("use +[RMConfiguration sharedInstance]");

- (RMConfiguration *)initWithPath:(NSString *)path;

/** @name Authorizing Access */

/** A Mapbox API access token. Obtain an access token on your [Mapbox account page](https://www.mapbox.com/account/apps/). */
@property (nonatomic, retain) NSString *accessToken;

/** @name Cache Configuration */

/** Access the disk- and memory-based cache configuration. 
*   @return A dictionary containing the cache configuration. */
- (NSDictionary *)cacheConfiguration;

/** @name Using a Custom User Agent */

/** Access and change the global user agent for HTTP requests using the library.
*
*   If unset, defaults to `Mapbox iOS SDK` followed by generic hardware model and software version information.
*
*   Example: `MyMapApp/1.2` */
@property (nonatomic, retain) NSString *userAgent;

@end

#pragma mark -

@interface NSURLConnection (RMUserAgent)

+ (NSData *)sendBrandedSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end

#pragma mark -

@interface NSData (RMUserAgent)

+ (instancetype)brandedDataWithContentsOfURL:(NSURL *)aURL;

@end

#pragma mark -

@interface NSString (RMUserAgent)

+ (instancetype)brandedStringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)enc error:(NSError **)error;

@end
