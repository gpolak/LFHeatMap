//
//  RMQuadTree.h
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

#import "RMFoundation.h"

@class RMAnnotation, RMMapView;

typedef enum : short {
    nodeTypeLeaf,
    nodeTypeNode
} RMQuadTreeNodeType;

#pragma mark - RMQuadTree nodes

@interface RMQuadTreeNode : NSObject

@property (nonatomic, weak, readonly) NSArray *annotations;
@property (nonatomic, readonly) RMQuadTreeNodeType nodeType;

@property (nonatomic, readonly) RMProjectedRect boundingBox;
@property (nonatomic, readonly) RMProjectedRect northWestBoundingBox;
@property (nonatomic, readonly) RMProjectedRect northEastBoundingBox;
@property (nonatomic, readonly) RMProjectedRect southWestBoundingBox;
@property (nonatomic, readonly) RMProjectedRect southEastBoundingBox;

@property (nonatomic, weak, readonly) RMQuadTreeNode *parentNode;
@property (nonatomic, readonly) RMQuadTreeNode *northWest;
@property (nonatomic, readonly) RMQuadTreeNode *northEast;
@property (nonatomic, readonly) RMQuadTreeNode *southWest;
@property (nonatomic, readonly) RMQuadTreeNode *southEast;

@property (nonatomic, weak, readonly) RMAnnotation *clusterAnnotation;
@property (nonatomic, weak, readonly) NSArray *clusteredAnnotations;

// Operations on this node and all subnodes
@property (nonatomic, weak, readonly) NSArray *enclosedAnnotations;
@property (nonatomic, weak, readonly) NSArray *unclusteredAnnotations;

@end

#pragma mark - RMQuadTree

@interface RMQuadTree : NSObject

- (id)initWithMapView:(RMMapView *)aMapView;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)removeAllObjects;

// Returns all annotations that are either inside of or intersect with boundingBox
- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox;
- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
               createClusterAnnotations:(BOOL)createClusterAnnotations
               withProjectedClusterSize:(RMProjectedSize)clusterSize
          andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                      findGravityCenter:(BOOL)findGravityCenter;

@end
