//
//  RMPointAnnotation.m
//  MapView
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

#import "RMPointAnnotation.h"

#import "RMMarker.h"
#import "RMMapView.h"

@implementation RMPointAnnotation

- (void)setLayer:(RMMapLayer *)newLayer
{
    if ( ! newLayer)
        [super setLayer:nil];
    else
        RMLog(@"Setting a custom layer on an %@ is a no-op", [self class]);
}

- (RMMapLayer *)layer
{
    if ( ! [super layer])
    {
        RMMarker *marker = [[RMMarker alloc] initWithMapboxMarkerImage:nil tintColor:(RMPostVersion7 ? self.mapView.tintColor : nil)];

        marker.canShowCallout = YES;

        super.layer = marker;
    }

    return [super layer];
}

- (void)setImage:(UIImage *)image
{
    [(RMMarker *)[self layer] replaceUIImage:image];
}

- (UIImage *)image
{
    return [UIImage imageWithCGImage:(CGImageRef)[self layer].contents];
}

@end
