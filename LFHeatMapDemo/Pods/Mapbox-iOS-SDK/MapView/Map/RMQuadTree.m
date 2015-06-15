//
//  RMQuadTree.m
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

#import "RMQuadTree.h"
#import "RMAnnotation.h"
#import "RMProjection.h"
#import "RMMapView.h"

#pragma mark -
#pragma mark RMQuadTreeNode implementation

#define kMinimumQuadTreeElementWidth 200.0 // projected meters
#define kMaxAnnotationsPerLeaf 4
#define kMinPixelDistanceForLeafClustering 100.0

@interface RMAnnotation (RMQuadTree)

@property (nonatomic, assign) BOOL isClusterAnnotation;

@end

@interface RMQuadTreeNode ()

- (id)initWithMapView:(RMMapView *)aMapView forParent:(RMQuadTreeNode *)aParentNode inBoundingBox:(RMProjectedRect)aBoundingBox;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox
                     toMutableArray:(NSMutableArray *)someArray
           createClusterAnnotations:(BOOL)createClusterAnnotations
           withProjectedClusterSize:(RMProjectedSize)clusterSize
      andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                  findGravityCenter:(BOOL)findGravityCenter;

- (void)removeUpwardsAllCachedClusterAnnotations;

- (void)precreateQuadTreeInBounds:(RMProjectedRect)quadTreeBounds withDepth:(NSUInteger)quadTreeDepth;

@end

@implementation RMQuadTreeNode
{
    RMProjectedRect _boundingBox, _northWestBoundingBox, _northEastBoundingBox, _southWestBoundingBox, _southEastBoundingBox;
    NSMutableArray *_annotations;
    __weak RMQuadTreeNode *_parentNode;
    RMQuadTreeNode *_northWest, *_northEast, *_southWest, *_southEast;
    RMQuadTreeNodeType _nodeType;
    __weak RMMapView *_mapView;

    RMAnnotation *_cachedClusterAnnotation;
    NSArray *_cachedClusterEnclosedAnnotations;
    NSMutableArray *_cachedEnclosedAnnotations, *_cachedUnclusteredAnnotations;
}

@synthesize nodeType = _nodeType;
@synthesize boundingBox = _boundingBox;
@synthesize northWestBoundingBox = _northWestBoundingBox, northEastBoundingBox = _northEastBoundingBox;
@synthesize southWestBoundingBox = _southWestBoundingBox, southEastBoundingBox = _southEastBoundingBox;
@synthesize parentNode = _parentNode;
@synthesize northWest = _northWest, northEast = _northEast;
@synthesize southWest = _southWest, southEast = _southEast;

- (id)initWithMapView:(RMMapView *)aMapView forParent:(RMQuadTreeNode *)aParentNode inBoundingBox:(RMProjectedRect)aBoundingBox
{
    if (!(self = [super init]))
        return nil;

//    RMLog(@"New quadtree node at {(%.0f,%.0f),(%.0f,%.0f)}", aBoundingBox.origin.easting, aBoundingBox.origin.northing, aBoundingBox.size.width, aBoundingBox.size.height);

    _mapView = aMapView;
    _parentNode = aParentNode;
    _northWest = _northEast = _southWest = _southEast = nil;
    _annotations = [NSMutableArray new];
    _boundingBox = aBoundingBox;
    _cachedClusterAnnotation = nil;
    _cachedClusterEnclosedAnnotations = nil;
    _cachedEnclosedAnnotations = _cachedUnclusteredAnnotations = nil;

    double halfWidth = _boundingBox.size.width / 2.0, halfHeight = _boundingBox.size.height / 2.0;
    _northWestBoundingBox = RMProjectedRectMake(_boundingBox.origin.x, _boundingBox.origin.y + halfHeight, halfWidth, halfHeight);
    _northEastBoundingBox = RMProjectedRectMake(_boundingBox.origin.x + halfWidth, _boundingBox.origin.y + halfHeight, halfWidth, halfHeight);
    _southWestBoundingBox = RMProjectedRectMake(_boundingBox.origin.x, _boundingBox.origin.y, halfWidth, halfHeight);
    _southEastBoundingBox = RMProjectedRectMake(_boundingBox.origin.x + halfWidth, _boundingBox.origin.y, halfWidth, halfHeight);

    _nodeType = nodeTypeLeaf;

    return self;
}

- (void)dealloc
{
    _mapView = nil;

    @synchronized (_cachedClusterAnnotation)
    {
         _cachedClusterEnclosedAnnotations = nil;
         _cachedClusterAnnotation = nil;
    }

    @synchronized (_annotations)
    {
        for (RMAnnotation *annotation in _annotations)
        {
            annotation.quadTreeNode = nil;
        }
    }
}

- (NSArray *)annotations
{
    NSArray *immutableAnnotations = nil;

    @synchronized (_annotations)
    {
        immutableAnnotations = [NSArray arrayWithArray:_annotations];
    }

    return immutableAnnotations;
}

- (void)addAnnotationToChildNodes:(RMAnnotation *)annotation
{
    RMProjectedRect projectedRect = annotation.projectedBoundingBox;

    if (RMProjectedRectContainsProjectedRect(_northWestBoundingBox, projectedRect))
    {
        if (!_northWest)
            _northWest = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_northWestBoundingBox];

        [_northWest addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(_northEastBoundingBox, projectedRect))
    {
        if (!_northEast)
            _northEast = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_northEastBoundingBox];

        [_northEast addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(_southWestBoundingBox, projectedRect))
    {
        if (!_southWest)
            _southWest = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_southWestBoundingBox];

        [_southWest addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(_southEastBoundingBox, projectedRect))
    {
        if (!_southEast)
            _southEast = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_southEastBoundingBox];

        [_southEast addAnnotation:annotation];
    }
    else
    {
        @synchronized (_annotations)
        {
            [_annotations addObject:annotation];
        }

        annotation.quadTreeNode = self;
        [self removeUpwardsAllCachedClusterAnnotations];
    }
}

- (void)precreateQuadTreeInBounds:(RMProjectedRect)quadTreeBounds withDepth:(NSUInteger)quadTreeDepth
{
    if (quadTreeDepth == 0 || _boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0))
        return;

//    RMLog(@"node in {%.0f,%.0f},{%.0f,%.0f} depth %d", boundingBox.origin.x, boundingBox.origin.y, boundingBox.size.width, boundingBox.size.height, quadTreeDepth);

    @synchronized (_cachedClusterAnnotation)
    {
         _cachedClusterEnclosedAnnotations = nil;
         _cachedClusterAnnotation = nil;
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, _northWestBoundingBox))
    {
        if (!_northWest)
            _northWest = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_northWestBoundingBox];

        [_northWest precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, _northEastBoundingBox))
    {
        if (!_northEast)
            _northEast = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_northEastBoundingBox];

        [_northEast precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, _southWestBoundingBox))
    {
        if (!_southWest)
            _southWest = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_southWestBoundingBox];

        [_southWest precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, _southEastBoundingBox))
    {
        if (!_southEast)
            _southEast = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:self inBoundingBox:_southEastBoundingBox];

        [_southEast precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (_nodeType == nodeTypeLeaf && [_annotations count])
    {
        NSArray *immutableAnnotations = nil;

        @synchronized (_annotations)
        {
            immutableAnnotations = [NSArray arrayWithArray:_annotations];
            [_annotations removeAllObjects];
        }

        for (RMAnnotation *annotationToMove in immutableAnnotations)
        {
            [self addAnnotationToChildNodes:annotationToMove];
        }
    }

    _nodeType = nodeTypeNode;
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    if (_nodeType == nodeTypeLeaf)
    {
        @synchronized (_annotations)
        {
            [_annotations addObject:annotation];
        }

        annotation.quadTreeNode = self;

        if ([_annotations count] <= kMaxAnnotationsPerLeaf || _boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0))
        {
            [self removeUpwardsAllCachedClusterAnnotations];
            return;
        }

        _nodeType = nodeTypeNode;

        // problem: all annotations that cross two quadrants will always be re-added here, which
        // might be a problem depending on kMaxAnnotationsPerLeaf

        NSArray *immutableAnnotations = nil;

        @synchronized (_annotations)
        {
            immutableAnnotations = [NSArray arrayWithArray:_annotations];
            [_annotations removeAllObjects];
        }

        for (RMAnnotation *annotationToMove in immutableAnnotations)
        {
            [self addAnnotationToChildNodes:annotationToMove];
        }

        return;
    }

    [self addAnnotationToChildNodes:annotation];
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    if (!annotation.quadTreeNode)
        return;

    annotation.quadTreeNode = nil;

    @synchronized (_annotations)
    {
        [_annotations removeObject:annotation];
    }

    [self removeUpwardsAllCachedClusterAnnotations];
}

- (void)annotationDidChangeBoundingBox:(RMAnnotation *)annotation
{
    if (RMProjectedRectContainsProjectedRect(_boundingBox, annotation.projectedBoundingBox))
        return;

    [self removeAnnotation:annotation];

    RMQuadTreeNode *nextParentNode = self;

    while ((nextParentNode = [nextParentNode parentNode]))
    {
        if (RMProjectedRectContainsProjectedRect(nextParentNode.boundingBox, annotation.projectedBoundingBox))
        {
            [nextParentNode addAnnotationToChildNodes:annotation];
            break;
        }
    }
}

- (NSArray *)enclosedAnnotations
{
    if (!_cachedEnclosedAnnotations)
    {
        _cachedEnclosedAnnotations = [[NSMutableArray alloc] initWithArray:self.annotations];
        if (_northWest) [_cachedEnclosedAnnotations addObjectsFromArray:_northWest.enclosedAnnotations];
        if (_northEast) [_cachedEnclosedAnnotations addObjectsFromArray:_northEast.enclosedAnnotations];
        if (_southWest) [_cachedEnclosedAnnotations addObjectsFromArray:_southWest.enclosedAnnotations];
        if (_southEast) [_cachedEnclosedAnnotations addObjectsFromArray:_southEast.enclosedAnnotations];
    }

    return _cachedEnclosedAnnotations;
}

- (NSArray *)unclusteredAnnotations
{
    if (!_cachedUnclusteredAnnotations)
    {
        _cachedUnclusteredAnnotations = [NSMutableArray new];

        @synchronized (_annotations)
        {
            for (RMAnnotation *annotation in _annotations)
            {
                if (!annotation.clusteringEnabled)
                    [_cachedUnclusteredAnnotations addObject:annotation];
            }
        }

        if (_northWest) [_cachedUnclusteredAnnotations addObjectsFromArray:[_northWest unclusteredAnnotations]];
        if (_northEast) [_cachedUnclusteredAnnotations addObjectsFromArray:[_northEast unclusteredAnnotations]];
        if (_southWest) [_cachedUnclusteredAnnotations addObjectsFromArray:[_southWest unclusteredAnnotations]];
        if (_southEast) [_cachedUnclusteredAnnotations addObjectsFromArray:[_southEast unclusteredAnnotations]];
    }

    return _cachedUnclusteredAnnotations;
}

- (NSArray *)enclosedWithoutUnclusteredAnnotations
{
    NSArray *unclusteredAnnotations = self.unclusteredAnnotations;
    if (!unclusteredAnnotations || [unclusteredAnnotations count] == 0)
        return self.enclosedAnnotations;

    NSMutableArray *enclosedAnnotations = [NSMutableArray arrayWithArray:self.enclosedAnnotations];
    [enclosedAnnotations removeObjectsInArray:unclusteredAnnotations];

    return enclosedAnnotations;
}

- (RMAnnotation *)clusterAnnotation
{
    return _cachedClusterAnnotation;
}

- (NSArray *)clusteredAnnotations
{
    NSArray *clusteredAnnotations = nil;

    @synchronized (_cachedClusterAnnotation)
    {
        clusteredAnnotations = [NSArray arrayWithArray:_cachedClusterEnclosedAnnotations];
    }

    return clusteredAnnotations;
}

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox
                     toMutableArray:(NSMutableArray *)someArray
           createClusterAnnotations:(BOOL)createClusterAnnotations
           withProjectedClusterSize:(RMProjectedSize)clusterSize
      andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                  findGravityCenter:(BOOL)findGravityCenter
{
    if (createClusterAnnotations)
    {
        double halfWidth     = _boundingBox.size.width / 2.0;
        BOOL forceClustering = (_boundingBox.size.width >= clusterSize.width && halfWidth < clusterSize.width);

        NSArray *enclosedAnnotations = nil;

        // Leaf clustering
        if (forceClustering == NO && _nodeType == nodeTypeLeaf && [_annotations count] > 1)
        {
            NSMutableArray *annotationsToCheck = [NSMutableArray arrayWithArray:[self enclosedWithoutUnclusteredAnnotations]];

            for (NSInteger i=[annotationsToCheck count]-1; i>0; --i)
            {
                BOOL mustBeClustered = NO;
                RMAnnotation *currentAnnotation = [annotationsToCheck objectAtIndex:i];

                for (NSInteger j=i-1; j>=0; --j)
                {
                    RMAnnotation *secondAnnotation = [annotationsToCheck objectAtIndex:j];

                    // This is of course not very accurate but is good enough for this use case
                    double distance = RMEuclideanDistanceBetweenProjectedPoints(currentAnnotation.projectedLocation, secondAnnotation.projectedLocation) / _mapView.metersPerPixel;
                    if (distance < kMinPixelDistanceForLeafClustering)
                    {
                        mustBeClustered = YES;
                        break;
                    }
                }

                if (!mustBeClustered)
                {
                    [someArray addObject:currentAnnotation];
                    [annotationsToCheck removeObjectAtIndex:i];
                }
            }

            forceClustering = ([annotationsToCheck count] > 0);

            if (forceClustering)
            {
                @synchronized (_cachedClusterAnnotation)
                {
                     _cachedClusterEnclosedAnnotations = nil;
                     _cachedClusterAnnotation = nil;
                }

                enclosedAnnotations = [NSArray arrayWithArray:annotationsToCheck];
            }
        }

        if (forceClustering)
        {
            if (!enclosedAnnotations)
                enclosedAnnotations = [self enclosedWithoutUnclusteredAnnotations];

            @synchronized (_cachedClusterAnnotation)
            {
                if (_cachedClusterAnnotation && [enclosedAnnotations count] != [_cachedClusterEnclosedAnnotations count])
                {
                     _cachedClusterEnclosedAnnotations = nil;
                     _cachedClusterAnnotation = nil;
                }
            }

            if (!_cachedClusterAnnotation)
            {
                NSUInteger enclosedAnnotationsCount = [enclosedAnnotations count];

                if (enclosedAnnotationsCount < 2)
                {
                    @synchronized (_annotations)
                    {
                        [someArray addObjectsFromArray:enclosedAnnotations];
                        [someArray addObjectsFromArray:[self unclusteredAnnotations]];
                    }

                    return;
                }

                RMProjectedPoint clusterMarkerPosition;

                if (findGravityCenter)
                {
                    double averageX = 0.0, averageY = 0.0;

                    for (RMAnnotation *annotation in enclosedAnnotations)
                    {
                        averageX += annotation.projectedLocation.x;
                        averageY += annotation.projectedLocation.y;
                    }

                    averageX /= (double)enclosedAnnotationsCount;
                    averageY /= (double)enclosedAnnotationsCount;

                    double halfClusterMarkerWidth = clusterMarkerSize.width / 2.0,
                           halfClusterMarkerHeight = clusterMarkerSize.height / 2.0;

                    if (averageX - halfClusterMarkerWidth < _boundingBox.origin.x)
                        averageX = _boundingBox.origin.x + halfClusterMarkerWidth;
                    if (averageX + halfClusterMarkerWidth > _boundingBox.origin.x + _boundingBox.size.width)
                        averageX = _boundingBox.origin.x + _boundingBox.size.width - halfClusterMarkerWidth;
                    if (averageY - halfClusterMarkerHeight < _boundingBox.origin.y)
                        averageY = _boundingBox.origin.y + halfClusterMarkerHeight;
                    if (averageY + halfClusterMarkerHeight > _boundingBox.origin.y + _boundingBox.size.height)
                        averageY = _boundingBox.origin.y + _boundingBox.size.height - halfClusterMarkerHeight;

                    // TODO: anchorPoint
                    clusterMarkerPosition = RMProjectedPointMake(averageX, averageY);
                }
                else
                {
                    clusterMarkerPosition = RMProjectedPointMake(_boundingBox.origin.x + halfWidth, _boundingBox.origin.y + (_boundingBox.size.height / 2.0));
                }

                CLLocationCoordinate2D clusterMarkerCoordinate = [[_mapView projection] projectedPointToCoordinate:clusterMarkerPosition];

                _cachedClusterAnnotation = [[RMAnnotation alloc] initWithMapView:_mapView
                                                                     coordinate:clusterMarkerCoordinate
                                                                       andTitle:[NSString stringWithFormat:@"%lu", (unsigned long)enclosedAnnotationsCount]];
                _cachedClusterAnnotation.isClusterAnnotation = YES;
                _cachedClusterAnnotation.userInfo = self;

                _cachedClusterEnclosedAnnotations = [[NSArray alloc] initWithArray:enclosedAnnotations];
            }

            [someArray addObject:_cachedClusterAnnotation];
            [someArray addObjectsFromArray:[self unclusteredAnnotations]];

            return;
        }

        if (_nodeType == nodeTypeLeaf)
        {
            @synchronized (_annotations)
            {
                [someArray addObjectsFromArray:_annotations];
            }

            return;
        }
    }
    else
    {
        if (_nodeType == nodeTypeLeaf)
        {
            @synchronized (_annotations)
            {
                [someArray addObjectsFromArray:_annotations];
            }

            return;
        }
    }

    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, _northWestBoundingBox))
        [_northWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, _northEastBoundingBox))
        [_northEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, _southWestBoundingBox))
        [_southWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, _southEastBoundingBox))
        [_southEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];

    @synchronized (_annotations)
    {
        for (RMAnnotation *annotation in _annotations)
        {
            if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, annotation.projectedBoundingBox))
                [someArray addObject:annotation];
        }
    }
}

- (void)removeUpwardsAllCachedClusterAnnotations
{
    if (_parentNode)
        [_parentNode removeUpwardsAllCachedClusterAnnotations];

    @synchronized (_cachedClusterAnnotation)
    {
         _cachedClusterEnclosedAnnotations = nil;
         _cachedClusterAnnotation = nil;
    }

     _cachedEnclosedAnnotations = nil;
     _cachedUnclusteredAnnotations = nil;
}

@end

#pragma mark - RMQuadTree implementation

@implementation RMQuadTree
{
    RMQuadTreeNode *_rootNode;
    __weak RMMapView *_mapView;
}

- (id)initWithMapView:(RMMapView *)aMapView
{
    if (!(self = [super init]))
        return nil;

    _mapView = aMapView;
    _rootNode = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:nil inBoundingBox:[[RMProjection googleProjection] planetBounds]];

    return self;
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    @synchronized (self)
    {
        if ( ! [_rootNode.annotations containsObject:annotation])
            [_rootNode addAnnotation:annotation];
    }
}

- (void)addAnnotations:(NSArray *)annotations
{
//    RMLog(@"Prepare tree");
//    [rootNode precreateQuadTreeInBounds:[[RMProjection googleProjection] planetBounds] withDepth:5];

    @synchronized (self)
    {
        for (RMAnnotation *annotation in annotations)
            if ( ! [_rootNode.annotations containsObject:annotation])
                [_rootNode addAnnotation:annotation];
    }
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    @synchronized (self)
    {
        [annotation.quadTreeNode removeAnnotation:annotation];
    }
}

- (void)removeAllObjects
{
    @synchronized (self)
    {
        _rootNode = [[RMQuadTreeNode alloc] initWithMapView:_mapView forParent:nil inBoundingBox:[[RMProjection googleProjection] planetBounds]];
    }
}

#pragma mark -

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
{
    return [self annotationsInProjectedRect:boundingBox createClusterAnnotations:NO withProjectedClusterSize:RMProjectedSizeMake(0.0, 0.0) andProjectedClusterMarkerSize:RMProjectedSizeMake(0.0, 0.0) findGravityCenter:NO];
}

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox createClusterAnnotations:(BOOL)createClusterAnnotations withProjectedClusterSize:(RMProjectedSize)clusterSize andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize findGravityCenter:(BOOL)findGravityCenter
{
    NSMutableArray *annotations = [NSMutableArray array];

    @synchronized (self)
    {
        [_rootNode addAnnotationsInBoundingBox:boundingBox toMutableArray:annotations createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    }

    return annotations;
}

@end
