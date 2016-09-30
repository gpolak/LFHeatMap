//
//  RMFractalTileProjection.h
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

#import <Foundation/Foundation.h>
#import "RMTile.h"
#import "RMProjection.h"
#import "RMFoundation.h"

@class RMProjection;

@interface RMFractalTileProjection : NSObject

// bounds of the earth, in projected units (meters).
@property (nonatomic, readonly) RMProjectedRect planetBounds;

// Maximum zoom for which we have tile images 
@property (nonatomic, readonly) NSUInteger maxZoom;

// Minimum zoom for which we have tile images 
@property (nonatomic, readonly) NSUInteger minZoom;

// Tile side length in pixels
@property (nonatomic, readonly) NSUInteger tileSideLength;

- (id)initFromProjection:(RMProjection *)projection tileSideLength:(NSUInteger)tileSideLength maxZoom:(NSUInteger)aMaxZoom minZoom:(NSUInteger)aMinZoom;

- (void)setTileSideLength:(NSUInteger)aTileSideLength;
- (void)setMinZoom:(NSUInteger)aMinZoom;
- (void)setMaxZoom:(NSUInteger)aMaxZoom;

- (RMTilePoint)project:(RMProjectedPoint)aPoint atZoom:(float)zoom;
- (RMTileRect)projectRect:(RMProjectedRect)aRect atZoom:(float)zoom;

- (RMTilePoint)project:(RMProjectedPoint)aPoint atScale:(float)scale;
- (RMTileRect)projectRect:(RMProjectedRect)aRect atScale:(float)scale;

- (RMTile)normaliseTile:(RMTile)tile;
- (float)normaliseZoom:(float)zoom;

- (float)calculateZoomFromScale:(float)scale;
- (float)calculateNormalisedZoomFromScale:(float)scale;
- (float)calculateScaleFromZoom:(float)zoom;

@end
