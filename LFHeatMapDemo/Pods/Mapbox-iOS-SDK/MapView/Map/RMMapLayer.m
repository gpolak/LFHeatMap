//
//  RMMapLayer.m
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

#import "RMMapLayer.h"
#import "RMPixel.h"
#import "RMAnnotation.h"
#import "RMMapView.h"
#import "RMMarker.h"

@interface RMMapView (PrivateMethods)

- (void)annotation:(RMAnnotation *)annotation didChangeDragState:(RMMapLayerDragState)newState fromOldState:(RMMapLayerDragState)oldState;

@end

#pragma mark -

@implementation RMMapLayer

@synthesize annotation;
@synthesize projectedLocation;
@synthesize dragState=_dragState;
@synthesize userInfo;
@synthesize canShowCallout=_canShowCallout;
@synthesize calloutOffset;
@synthesize leftCalloutAccessoryView;
@synthesize rightCalloutAccessoryView;

- (id)init
{
	if (!(self = [super init]))
		return nil;

    self.annotation = nil;
    self.calloutOffset = CGPointZero;

	return self;
}

- (id)initWithLayer:(id)layer
{
    if (!(self = [super initWithLayer:layer]))
        return nil;

    self.annotation = nil;
    self.userInfo = nil;
    self.calloutOffset = CGPointZero;

    return self;
}

- (void)setCanShowCallout:(BOOL)canShowCallout
{
    if (canShowCallout)
    {
        NSAssert([self isKindOfClass:[RMMarker class]],  @"Callouts are not supported on non-marker annotation layers");
        NSAssert( ! self.annotation.isClusterAnnotation, @"Callouts are not supported on cluster annotation layers");
    }

    _canShowCallout = canShowCallout;
}

- (void)setPosition:(CGPoint)position animated:(BOOL)animated
{
    [self setPosition:position];
}

- (void)setDragState:(RMMapLayerDragState)dragState
{
    [self setDragState:dragState animated:NO];
}

- (void)setDragState:(RMMapLayerDragState)dragState animated:(BOOL)animated
{
    RMMapLayerDragState oldDragState = _dragState;

    if (dragState == RMMapLayerDragStateStarting)
    {
        _dragState = RMMapLayerDragStateDragging;
    }
    else if (dragState == RMMapLayerDragStateDragging)
    {
        _dragState = RMMapLayerDragStateDragging;
    }
    else if (dragState == RMMapLayerDragStateCanceling || dragState == RMMapLayerDragStateEnding)
    {
        _dragState = RMMapLayerDragStateNone;
    }
    else if (dragState == RMMapLayerDragStateNone)
    {
        _dragState = RMMapLayerDragStateNone;
    }

    if (_dragState != oldDragState)
        [self.annotation.mapView annotation:self.annotation didChangeDragState:_dragState fromOldState:oldDragState];
}

/// return nil for certain animation keys to block core animation
//- (id <CAAction>)actionForKey:(NSString *)key
//{
//    if ([key isEqualToString:@"position"] || [key isEqualToString:@"bounds"])
//        return nil;
//    else
//        return [super actionForKey:key];
//}

@end
