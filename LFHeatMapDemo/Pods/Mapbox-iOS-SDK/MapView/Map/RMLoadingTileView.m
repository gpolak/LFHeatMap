//
//  RMTileLoadingView.m
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

#import "RMLoadingTileView.h"

#import "RMMapView.h"

@implementation RMLoadingTileView
{
    UIView *_contentView;
}

@synthesize mapZooming=_mapZooming;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width * 3, frame.size.height * 3)];
        [self addSubview:_contentView];

        [self setMapZooming:NO];

        self.userInteractionEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
    }
    
    return self;
}

- (void)setMapZooming:(BOOL)zooming
{
    if (zooming)
    {
        _contentView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        _contentView.backgroundColor = [UIColor colorWithPatternImage:[RMMapView resourceImageNamed:(RMPostVersion6 ? @"LoadingTile6.png" : @"LoadingTile.png")]];
        
        _contentView.frame = CGRectMake(0, 0, self.frame.size.width * 3, self.frame.size.height * 3);
        self.contentSize = _contentView.bounds.size;
        self.contentOffset = CGPointMake(self.frame.size.width, self.frame.size.height);
    }
    
    _mapZooming = zooming;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    CGPoint newContentOffset = contentOffset;
    
    if (newContentOffset.x > 2 * self.contentSize.width / 3)
    {
        newContentOffset.x = self.bounds.size.width;
    }
    else if (newContentOffset.x < self.contentSize.width / 3)
    {
        newContentOffset.x = self.bounds.size.width * 2;
    }

    if (newContentOffset.y > 2 * self.contentSize.height / 3)
    {
        newContentOffset.y = self.bounds.size.height;
    }
    else if (newContentOffset.y < self.contentSize.height / 3)
    {
        newContentOffset.y = self.bounds.size.height * 2;
    }

    [super setContentOffset:newContentOffset];
}

@end
