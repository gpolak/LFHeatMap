//
//  RMTileSourcesContainer.h
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

#import "RMTileSource.h"

#define kRMTileSourcesContainerMinZoom 0
#define kRMTileSourcesContainerMaxZoom 255

@interface RMTileSourcesContainer : NSObject

// These are the minimum and maximum zoom levels across all tile sources.
@property (nonatomic, assign) float minZoom;
@property (nonatomic, assign) float maxZoom;

// These properties are (and have to be) equal across all tile sources
@property (nonatomic, readonly) NSUInteger tileSideLength;

@property (nonatomic, weak, readonly) RMFractalTileProjection *mercatorToTileProjection;
@property (nonatomic, weak, readonly) RMProjection *projection;

@property (nonatomic, readonly) RMSphericalTrapezium latitudeLongitudeBoundingBox;

#pragma mark -

@property (nonatomic, weak, readonly) NSArray *tileSources;

- (id <RMTileSource>)tileSourceForUniqueTilecacheKey:(NSString *)uniqueTilecacheKey;

#pragma mark -

- (BOOL)setTileSource:(id <RMTileSource>)tileSource;
- (BOOL)setTileSources:(NSArray *)tileSources;

- (BOOL)addTileSource:(id <RMTileSource>)tileSource;
- (BOOL)addTileSource:(id<RMTileSource>)tileSource atIndex:(NSUInteger)index;

- (void)removeTileSource:(id <RMTileSource>)tileSource;
- (void)removeTileSourceAtIndex:(NSUInteger)index;

- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void)removeAllTileSources;
- (void)cancelAllDownloads;

- (void)didReceiveMemoryWarning;

@end
