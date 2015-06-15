///
//  RMCircle.m
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

#import "RMCircle.h"
#import "RMProjection.h"
#import "RMMapView.h"

#define kDefaultLineWidth 2.0
#define kDefaultLineColor [UIColor blackColor]
#define kDefaultFillColor [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25]

@interface RMCircle ()

- (void)updateCirclePathAnimated:(BOOL)animated;

@end

#pragma mark -

@implementation RMCircle

@synthesize shapeLayer;
@synthesize lineColor;
@synthesize fillColor;
@synthesize radiusInMeters;
@synthesize lineWidthInPixels;

- (id)initWithView:(RMMapView *)aMapView radiusInMeters:(CGFloat)newRadiusInMeters
{
    if (!(self = [super init]))
        return nil;

    shapeLayer = [CAShapeLayer new];
    [self addSublayer:shapeLayer];

    mapView = aMapView;
    radiusInMeters = newRadiusInMeters;

    lineWidthInPixels = kDefaultLineWidth;
    lineColor = kDefaultLineColor;
    fillColor = kDefaultFillColor;

    scaleLineWidth = NO;

    circlePath = NULL;
    [self updateCirclePathAnimated:NO];

    self.masksToBounds = NO;

    return self;
}

- (void)dealloc
{
    CGPathRelease(circlePath); circlePath = NULL;
}

#pragma mark -

- (void)updateCirclePathAnimated:(BOOL)animated
{
    CGPathRelease(circlePath); circlePath = NULL;

    CGMutablePathRef newPath = CGPathCreateMutable();

    CGFloat latRadians = [[mapView projection] projectedPointToCoordinate:projectedLocation].latitude * M_PI / 180.0f;
    CGFloat pixelRadius = radiusInMeters / cos(latRadians) / [mapView metersPerPixel];
    //	DLog(@"Pixel Radius: %f", pixelRadius);

    CGRect rectangle = CGRectMake(self.position.x - pixelRadius,
                                  self.position.y - pixelRadius,
                                  (pixelRadius * 2),
                                  (pixelRadius * 2));

    CGFloat offset = floorf(-lineWidthInPixels / 2.0f) - 2;
    CGRect newBoundsRect = CGRectInset(rectangle, offset, offset);

    [self setBounds:newBoundsRect];

    //	DLog(@"Circle Rectangle: %f, %f, %f, %f", rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height);
    //	DLog(@"Bounds Rectangle: %f, %f, %f, %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);

    CGPathAddEllipseInRect(newPath, NULL, rectangle);
    circlePath = newPath;

    // animate the path change if we're in an animation block
    //
    if (animated)
    {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];

        pathAnimation.duration  = [CATransaction animationDuration];
        pathAnimation.fromValue = [NSValue valueWithPointer:self.shapeLayer.path];
        pathAnimation.toValue   = [NSValue valueWithPointer:newPath];

        [self.shapeLayer addAnimation:pathAnimation forKey:@"animatePath"];
    }

    [self.shapeLayer setPath:newPath];
    [self.shapeLayer setFillColor:[fillColor CGColor]];
    [self.shapeLayer setStrokeColor:[lineColor CGColor]];
    [self.shapeLayer setLineWidth:lineWidthInPixels];

    if (self.fillPatternImage)
        self.shapeLayer.fillColor = [[UIColor colorWithPatternImage:self.fillPatternImage] CGColor];
}

#pragma mark - Accessors

- (BOOL)containsPoint:(CGPoint)thePoint
{
    BOOL containsPoint = NO;

    if ([self.fillColor isEqual:[UIColor clearColor]])
    {
        // if shape is not filled with a color, do a simple "point on path" test
        //
        UIGraphicsBeginImageContext(self.bounds.size);
        CGContextAddPath(UIGraphicsGetCurrentContext(), shapeLayer.path);
        containsPoint = CGContextPathContainsPoint(UIGraphicsGetCurrentContext(), thePoint, kCGPathStroke);
        UIGraphicsEndImageContext();
    }
    else
    {
        // else do a "path contains point" test
        //
        containsPoint = CGPathContainsPoint(shapeLayer.path, nil, thePoint, [shapeLayer.fillRule isEqualToString:kCAFillRuleEvenOdd]);
    }

    return containsPoint;
}

- (void)setLineColor:(UIColor *)newLineColor
{
    if (lineColor != newLineColor)
    {
        lineColor = newLineColor;
        [self updateCirclePathAnimated:NO];
    }
}

- (void)setFillColor:(UIColor *)newFillColor
{
    if (fillColor != newFillColor)
    {
        fillColor = newFillColor;
        [self updateCirclePathAnimated:NO];
    }
}

- (void)setFillPatternImage:(UIImage *)fillPatternImage
{
    if (fillPatternImage)
        self.fillColor = nil;

    if (_fillPatternImage != fillPatternImage)
    {
        _fillPatternImage = fillPatternImage;
        [self updateCirclePathAnimated:NO];
    }
}

- (void)setRadiusInMeters:(CGFloat)newRadiusInMeters
{
    radiusInMeters = newRadiusInMeters;
    [self updateCirclePathAnimated:NO];
}

- (void)setLineWidthInPixels:(CGFloat)newLineWidthInPixels
{
    lineWidthInPixels = newLineWidthInPixels;
    [self updateCirclePathAnimated:NO];
}

- (void)setPosition:(CGPoint)position animated:(BOOL)animated
{
    [self setPosition:position];

    [self updateCirclePathAnimated:animated];
}

@end
