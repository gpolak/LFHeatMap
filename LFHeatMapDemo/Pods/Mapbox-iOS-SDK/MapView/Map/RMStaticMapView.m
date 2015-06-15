//
//  RMStaticMapView.m
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import "RMStaticMapView.h"

#import "RMAnnotation.h"
#import "RMMapboxSource.h"
#import "RMMarker.h"

#define kMapboxDefaultCenter CLLocationCoordinate2DMake(MAXFLOAT, MAXFLOAT)
#define kMapboxDefaultZoom   -1.0f

@interface RMStaticMapView ()

- (void)performInitializationWithMapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler;

@end

#pragma mark -

@implementation RMStaticMapView
{
    __weak RMStaticMapView *_weakSelf;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame mapID:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:kMapboxDefaultCenter zoomLevel:kMapboxDefaultZoom completionHandler:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID completionHandler:(void (^)(UIImage *))handler
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:kMapboxDefaultCenter zoomLevel:kMapboxDefaultZoom completionHandler:handler];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:centerCoordinate zoomLevel:zoomLevel completionHandler:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    [self performInitializationWithMapID:mapID centerCoordinate:centerCoordinate zoomLevel:zoomLevel completionHandler:handler];

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder]))
        return nil;

    [self performInitializationWithMapID:nil centerCoordinate:kMapboxDefaultCenter zoomLevel:kMapboxDefaultZoom completionHandler:nil];

    return self;
}

- (void)performInitializationWithMapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler
{
    RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:(mapID ? mapID : kMapboxPlaceholderMapID) enablingDataOnMapView:self];

    self.tileSource = tileSource;

    if ( ! CLLocationCoordinate2DIsValid(centerCoordinate))
        centerCoordinate = [tileSource centerCoordinate];

    [self setCenterCoordinate:centerCoordinate animated:NO];

    if (zoomLevel < 0)
        zoomLevel = [tileSource centerZoom];

    [self setZoom:zoomLevel];

    self.backgroundColor = [UIColor colorWithPatternImage:[RMMapView resourceImageNamed:@"LoadingTile.png"]];

    self.hideAttribution = YES;

    self.showsUserLocation = NO;

    self.userInteractionEnabled = NO;

    if (handler)
    {
        _weakSelf = self;

        dispatch_async(tileSource.dataQueue, ^(void)
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void)
            {
                UIImage *image = [_weakSelf takeSnapshot];

                handler(image);
            });
        });
    }
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    annotation.layer = [[RMMarker alloc] initWithMapboxMarkerImage:[annotation.userInfo objectForKey:@"marker-symbol"]
                                                      tintColorHex:[annotation.userInfo objectForKey:@"marker-color"]
                                                        sizeString:[annotation.userInfo objectForKey:@"marker-size"]];

    [super addAnnotation:annotation];
}

@end
