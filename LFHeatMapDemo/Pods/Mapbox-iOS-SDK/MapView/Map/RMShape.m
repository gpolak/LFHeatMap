///
//  RMShape.m
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

#import "RMShape.h"
#import "RMPixel.h"
#import "RMProjection.h"
#import "RMMapView.h"
#import "RMAnnotation.h"

@implementation RMShape
{
    BOOL isFirstPoint, ignorePathUpdates;
    float lastScale;

    CGRect nonClippedBounds;
    CGRect previousBounds;

    CAShapeLayer *shapeLayer;
    UIBezierPath *bezierPath;

    NSMutableArray *points;

    __weak RMMapView *mapView;
}

@synthesize scaleLineWidth;
@synthesize lineDashLengths;
@synthesize scaleLineDash;
@synthesize shadowBlur;
@synthesize shadowOffset;
@synthesize enableShadow;
@synthesize pathBoundingBox;

#define kDefaultLineWidth 2.0

- (id)initWithView:(RMMapView *)aMapView
{
    if (!(self = [super init]))
        return nil;

    mapView = aMapView;

    bezierPath = [UIBezierPath new];
    lineWidth = kDefaultLineWidth;
    ignorePathUpdates = NO;

    shapeLayer = [CAShapeLayer new];
    shapeLayer.rasterizationScale = [[UIScreen mainScreen] scale];
    shapeLayer.lineWidth = lineWidth;
    shapeLayer.lineCap = kCALineCapButt;
    shapeLayer.lineJoin = kCALineJoinMiter;
    shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.shadowRadius = 0.0;
    shapeLayer.shadowOpacity = 0.0;
    shapeLayer.shadowOffset = CGSizeMake(0, 0);
    [self addSublayer:shapeLayer];

    pathBoundingBox = CGRectZero;
    nonClippedBounds = CGRectZero;
    previousBounds = CGRectZero;
    lastScale = 0.0;

    self.masksToBounds = NO;

    scaleLineWidth = NO;
    scaleLineDash = NO;
    isFirstPoint = YES;

    points = [NSMutableArray array];

    [(id)self setValue:[[UIScreen mainScreen] valueForKey:@"scale"] forKey:@"contentsScale"];

    return self;
}

- (id <CAAction>)actionForKey:(NSString *)key
{
    return nil;
}

#pragma mark -

- (void)recalculateGeometryAnimated:(BOOL)animated
{
    if (ignorePathUpdates)
        return;

    float scale = 1.0f / [mapView metersPerPixel];

    // we have to calculate the scaledLineWidth even if scalling did not change
    // as the lineWidth might have changed
    float scaledLineWidth;

    if (scaleLineWidth)
        scaledLineWidth = lineWidth * scale;
    else
        scaledLineWidth = lineWidth;

    shapeLayer.lineWidth = scaledLineWidth;

    if (self.fillPatternImage)
        shapeLayer.fillColor = [[UIColor colorWithPatternImage:self.fillPatternImage] CGColor];

    if (lineDashLengths)
    {
        if (scaleLineDash)
        {
            NSMutableArray *scaledLineDashLengths = [NSMutableArray array];

            for (NSNumber *lineDashLength in lineDashLengths)
            {
                [scaledLineDashLengths addObject:[NSNumber numberWithFloat:lineDashLength.floatValue * scale]];
            }

            shapeLayer.lineDashPattern = scaledLineDashLengths;
        }
        else
        {
            shapeLayer.lineDashPattern = lineDashLengths;
        }
    }

    // we are about to overwrite nonClippedBounds, therefore we save the old value
    CGRect previousNonClippedBounds = nonClippedBounds;

    if (scale != lastScale)
    {
        lastScale = scale;

        CGAffineTransform scaling = CGAffineTransformMakeScale(scale, scale);
        UIBezierPath *scaledPath = [bezierPath copy];
        [scaledPath applyTransform:scaling];

        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.repeatCount = 0;
            animation.autoreverses = NO;
            animation.fromValue = (id) shapeLayer.path;
            animation.toValue = (id) scaledPath.CGPath;
            [shapeLayer addAnimation:animation forKey:@"animatePath"];
        }

        shapeLayer.path = scaledPath.CGPath;

        // calculate the bounds of the scaled path
        CGRect boundsInMercators = scaledPath.bounds;
        nonClippedBounds = CGRectInset(boundsInMercators, -scaledLineWidth - (2 * shapeLayer.shadowRadius), -scaledLineWidth - (2 * shapeLayer.shadowRadius));
    }

    // if the path is not scaled, nonClippedBounds stay the same as in the previous invokation

    // Clip bound rect to screen bounds.
    // If bounds are not clipped, they won't display when you zoom in too much.

    CGRect screenBounds = [mapView bounds];

    // we start with the non-clipped bounds and clip them
    CGRect clippedBounds = nonClippedBounds;

    float offset;
    const float outset = 150.0f; // provides a buffer off screen edges for when path is scaled or moved

    CGPoint newPosition = self.annotation.position;

//    RMLog(@"x:%f y:%f screen bounds: %f %f %f %f", newPosition.x, newPosition.y,  screenBounds.origin.x, screenBounds.origin.y, screenBounds.size.width, screenBounds.size.height);

    // Clip top
    offset = newPosition.y + clippedBounds.origin.y - screenBounds.origin.y + outset;
    if (offset < 0.0f)
    {
        clippedBounds.origin.y -= offset;
        clippedBounds.size.height += offset;
    }

    // Clip left
    offset = newPosition.x + clippedBounds.origin.x - screenBounds.origin.x + outset;
    if (offset < 0.0f)
    {
        clippedBounds.origin.x -= offset;
        clippedBounds.size.width += offset;
    }

    // Clip bottom
    offset = newPosition.y + clippedBounds.origin.y + clippedBounds.size.height - screenBounds.origin.y - screenBounds.size.height - outset;
    if (offset > 0.0f)
    {
        clippedBounds.size.height -= offset;
    }

    // Clip right
    offset = newPosition.x + clippedBounds.origin.x + clippedBounds.size.width - screenBounds.origin.x - screenBounds.size.width - outset;
    if (offset > 0.0f)
    {
        clippedBounds.size.width -= offset;
    }

    if (animated)
    {
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        positionAnimation.repeatCount = 0;
        positionAnimation.autoreverses = NO;
        positionAnimation.fromValue = [NSValue valueWithCGPoint:self.position];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPosition];
        [self addAnimation:positionAnimation forKey:@"animatePosition"];
    }

    super.position = newPosition;

    // bounds are animated non-clipped but set with clipping

    CGPoint previousNonClippedAnchorPoint = CGPointMake(-previousNonClippedBounds.origin.x / previousNonClippedBounds.size.width,
                                                        -previousNonClippedBounds.origin.y / previousNonClippedBounds.size.height);
    CGPoint nonClippedAnchorPoint = CGPointMake(-nonClippedBounds.origin.x / nonClippedBounds.size.width,
                                                -nonClippedBounds.origin.y / nonClippedBounds.size.height);
    CGPoint clippedAnchorPoint = CGPointMake(-clippedBounds.origin.x / clippedBounds.size.width,
                                             -clippedBounds.origin.y / clippedBounds.size.height);

    if (animated)
    {
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        boundsAnimation.repeatCount = 0;
        boundsAnimation.autoreverses = NO;
        boundsAnimation.fromValue = [NSValue valueWithCGRect:previousNonClippedBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:nonClippedBounds];
        [self addAnimation:boundsAnimation forKey:@"animateBounds"];
    }

    self.bounds = clippedBounds;
    previousBounds = clippedBounds;

    // anchorPoint is animated non-clipped but set with clipping
    if (animated)
    {
        CABasicAnimation *anchorPointAnimation = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
        anchorPointAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anchorPointAnimation.repeatCount = 0;
        anchorPointAnimation.autoreverses = NO;
        anchorPointAnimation.fromValue = [NSValue valueWithCGPoint:previousNonClippedAnchorPoint];
        anchorPointAnimation.toValue = [NSValue valueWithCGPoint:nonClippedAnchorPoint];
        [self addAnimation:anchorPointAnimation forKey:@"animateAnchorPoint"];
    }

    self.anchorPoint = clippedAnchorPoint;

    if (self.annotation && [points count])
    {
        self.annotation.coordinate = ((CLLocation *)[points objectAtIndex:0]).coordinate;
        [self.annotation setBoundingBoxFromLocations:points];
    }
}

#pragma mark -


- (void)addCurveToProjectedPoint:(RMProjectedPoint)point controlPoint1:(RMProjectedPoint)controlPoint1 controlPoint2:(RMProjectedPoint)controlPoint2 withDrawing:(BOOL)isDrawing
{
    [points addObject:[[CLLocation alloc] initWithLatitude:[mapView projectedPointToCoordinate:point].latitude longitude:[mapView projectedPointToCoordinate:point].longitude]];

    if (isFirstPoint)
    {
        isFirstPoint = FALSE;
        projectedLocation = point;

        self.position = [mapView projectedPointToPixel:projectedLocation];

        [bezierPath moveToPoint:CGPointMake(0.0f, 0.0f)];
    }
    else
    {
        point.x = point.x - projectedLocation.x;
        point.y = point.y - projectedLocation.y;

        if (isDrawing)
        {
            if (controlPoint1.x == (double)INFINITY && controlPoint2.x == (double)INFINITY)
            {
                [bezierPath addLineToPoint:CGPointMake(point.x, -point.y)];
            }
            else if (controlPoint2.x == (double)INFINITY)
            {
                controlPoint1.x = controlPoint1.x - projectedLocation.x;
                controlPoint1.y = controlPoint1.y - projectedLocation.y;

                [bezierPath addQuadCurveToPoint:CGPointMake(point.x, -point.y)
                                   controlPoint:CGPointMake(controlPoint1.x, -controlPoint1.y)];
            }
            else
            {
                controlPoint1.x = controlPoint1.x - projectedLocation.x;
                controlPoint1.y = controlPoint1.y - projectedLocation.y;
                controlPoint2.x = controlPoint2.x - projectedLocation.x;
                controlPoint2.y = controlPoint2.y - projectedLocation.y;

                [bezierPath addCurveToPoint:CGPointMake(point.x, -point.y)
                              controlPoint1:CGPointMake(controlPoint1.x, -controlPoint1.y)
                              controlPoint2:CGPointMake(controlPoint2.x, -controlPoint2.y)];
            }
        }
        else
        {
            [bezierPath moveToPoint:CGPointMake(point.x, -point.y)];
        }

        lastScale = 0.0;
        [self recalculateGeometryAnimated:NO];
    }

    [self setNeedsDisplay];
}

- (void)moveToProjectedPoint:(RMProjectedPoint)projectedPoint
{
    [self addCurveToProjectedPoint:projectedPoint
                     controlPoint1:RMProjectedPointMake((double)INFINITY, (double)INFINITY)
                     controlPoint2:RMProjectedPointMake((double)INFINITY, (double)INFINITY)
                       withDrawing:NO];
}

- (void)moveToScreenPoint:(CGPoint)point
{
    RMProjectedPoint mercator = [mapView pixelToProjectedPoint:point];
    [self moveToProjectedPoint:mercator];
}

- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate
{
    RMProjectedPoint mercator = [[mapView projection] coordinateToProjectedPoint:coordinate];
    [self moveToProjectedPoint:mercator];
}

- (void)addLineToProjectedPoint:(RMProjectedPoint)projectedPoint
{
    [self addCurveToProjectedPoint:projectedPoint
                     controlPoint1:RMProjectedPointMake((double)INFINITY, (double)INFINITY)
                     controlPoint2:RMProjectedPointMake((double)INFINITY, (double)INFINITY)
                       withDrawing:YES];
}

- (void)addLineToScreenPoint:(CGPoint)point
{
    RMProjectedPoint mercator = [mapView pixelToProjectedPoint:point];
    [self addLineToProjectedPoint:mercator];
}

- (void)addLineToCoordinate:(CLLocationCoordinate2D)coordinate
{
    RMProjectedPoint mercator = [[mapView projection] coordinateToProjectedPoint:coordinate];
    [self addLineToProjectedPoint:mercator];
}

- (void)addCurveToCoordinate:(CLLocationCoordinate2D)coordinate controlCoordinate1:(CLLocationCoordinate2D)controlCoordinate1 controlCoordinate2:(CLLocationCoordinate2D)controlCoordinate2
{
    RMProjectedPoint projectedPoint = [[mapView projection] coordinateToProjectedPoint:coordinate];

    RMProjectedPoint controlProjectedPoint1 = [[mapView projection] coordinateToProjectedPoint:controlCoordinate1];
    RMProjectedPoint controlProjectedPoint2 = [[mapView projection] coordinateToProjectedPoint:controlCoordinate2];

    [self addCurveToProjectedPoint:projectedPoint
            controlProjectedPoint1:controlProjectedPoint1
            controlProjectedPoint2:controlProjectedPoint2];
}

- (void)addQuadCurveToCoordinate:(CLLocationCoordinate2D)coordinate controlCoordinate:(CLLocationCoordinate2D)controlCoordinate
{
    RMProjectedPoint projectedPoint = [[mapView projection] coordinateToProjectedPoint:coordinate];

    RMProjectedPoint controlProjectedPoint = [[mapView projection] coordinateToProjectedPoint:controlCoordinate];

    [self addQuadCurveToProjectedPoint:projectedPoint
                 controlProjectedPoint:controlProjectedPoint];
}

- (void)addCurveToProjectedPoint:(RMProjectedPoint)projectedPoint controlProjectedPoint1:(RMProjectedPoint)controlProjectedPoint1 controlProjectedPoint2:(RMProjectedPoint)controlProjectedPoint2
{
    [self addCurveToProjectedPoint:projectedPoint
                     controlPoint1:controlProjectedPoint1
                     controlPoint2:controlProjectedPoint2
                       withDrawing:YES];
}

- (void)addQuadCurveToProjectedPoint:(RMProjectedPoint)projectedPoint controlProjectedPoint:(RMProjectedPoint)controlProjectedPoint
{
    [self addCurveToProjectedPoint:projectedPoint
                     controlPoint1:controlProjectedPoint
                     controlPoint2:RMProjectedPointMake((double)INFINITY, (double)INFINITY)
                       withDrawing:YES];
}

- (void)performBatchOperations:(void (^)(RMShape *aShape))block
{
    ignorePathUpdates = YES;
    block(self);
    ignorePathUpdates = NO;

    lastScale = 0.0;
    [self recalculateGeometryAnimated:NO];
}

#pragma mark - Accessors

- (BOOL)containsPoint:(CGPoint)thePoint
{
    BOOL containsPoint = NO;

    if ([self.fillColor isEqual:[UIColor clearColor]])
    {
        // if shape is not filled with a color, do a simple "point on path" test
        //
        if (self.additionalTouchPadding)
        {
            CGPathRef tapTargetPath = CGPathCreateCopyByStrokingPath(shapeLayer.path, nil, fmaxf(self.additionalTouchPadding, shapeLayer.lineWidth), 0, 0, 0);

            if (tapTargetPath)
            {
                containsPoint = [[UIBezierPath bezierPathWithCGPath:tapTargetPath] containsPoint:thePoint];

                CGPathRelease(tapTargetPath);
            }
        }
        else
        {
            UIGraphicsBeginImageContext(self.bounds.size);
            CGContextAddPath(UIGraphicsGetCurrentContext(), shapeLayer.path);
            containsPoint = CGContextPathContainsPoint(UIGraphicsGetCurrentContext(), thePoint, kCGPathStroke);
            UIGraphicsEndImageContext();
        }
    }
    else
    {
        // else do a "path contains point" test
        //
        containsPoint = CGPathContainsPoint(shapeLayer.path, nil, thePoint, [shapeLayer.fillRule isEqualToString:kCAFillRuleEvenOdd]);
    }

    return containsPoint;
}

- (void)closePath
{
    if ([points count])
        [self addLineToCoordinate:((CLLocation *)[points objectAtIndex:0]).coordinate];
}

- (float)lineWidth
{
    return lineWidth;
}

- (void)setLineWidth:(float)newLineWidth
{
    lineWidth = newLineWidth;

    lastScale = 0.0;
    [self recalculateGeometryAnimated:NO];
}

- (NSString *)lineCap
{
    return shapeLayer.lineCap;
}

- (void)setLineCap:(NSString *)newLineCap
{
    shapeLayer.lineCap = newLineCap;
    [self setNeedsDisplay];
}

- (NSString *)lineJoin
{
    return shapeLayer.lineJoin;
}

- (void)setLineJoin:(NSString *)newLineJoin
{
    shapeLayer.lineJoin = newLineJoin;
    [self setNeedsDisplay];
}

- (UIColor *)lineColor
{
    return [UIColor colorWithCGColor:shapeLayer.strokeColor];
}

- (void)setLineColor:(UIColor *)aLineColor
{
    if (shapeLayer.strokeColor != aLineColor.CGColor)
    {
        shapeLayer.strokeColor = aLineColor.CGColor;
        [self setNeedsDisplay];
    }
}

- (UIColor *)fillColor
{
    return [UIColor colorWithCGColor:shapeLayer.fillColor];
}

- (void)setFillColor:(UIColor *)aFillColor
{
    if (shapeLayer.fillColor != aFillColor.CGColor)
    {
        shapeLayer.fillColor = aFillColor.CGColor;
        [self setNeedsDisplay];
    }
}

- (void)setFillPatternImage:(UIImage *)fillPatternImage
{
    if (fillPatternImage)
        self.fillColor = nil;

    if (_fillPatternImage != fillPatternImage)
    {
        _fillPatternImage = fillPatternImage;
        [self recalculateGeometryAnimated:NO];
    }
}

- (CGFloat)shadowBlur
{
    return shapeLayer.shadowRadius;
}

- (void)setShadowBlur:(CGFloat)blur
{
    shapeLayer.shadowRadius = blur;
    [self setNeedsDisplay];
}

- (CGSize)shadowOffset
{
    return shapeLayer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)offset
{
    shapeLayer.shadowOffset = offset;
    [self setNeedsDisplay];
}

- (BOOL)enableShadow
{
    return (shapeLayer.shadowOpacity > 0);
}

- (void)setEnableShadow:(BOOL)flag
{
    shapeLayer.shadowOpacity   = (flag ? 1.0 : 0.0);
    shapeLayer.shouldRasterize = ! flag;
    [self setNeedsDisplay];
}

- (NSString *)fillRule
{
    return shapeLayer.fillRule;
}

- (void)setFillRule:(NSString *)fillRule
{
    shapeLayer.fillRule = fillRule;
}

- (CGFloat)lineDashPhase
{
    return shapeLayer.lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)dashPhase
{
    shapeLayer.lineDashPhase = dashPhase;
}

- (void)setPosition:(CGPoint)newPosition animated:(BOOL)animated
{
    if (CGPointEqualToPoint(newPosition, super.position) && CGRectEqualToRect(self.bounds, previousBounds))
        return;

    [self recalculateGeometryAnimated:animated];
}

- (void)setAnnotation:(RMAnnotation *)newAnnotation
{
    if (newAnnotation)
    {
        super.annotation = newAnnotation;
        [self recalculateGeometryAnimated:NO];
    }
}

@end
