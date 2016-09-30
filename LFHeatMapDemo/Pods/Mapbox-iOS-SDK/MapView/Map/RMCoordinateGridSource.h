//
//  RMCoordinateGridSource.h
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

#import "RMAbstractMercatorTileSource.h"
#import "RMProjection.h"

typedef enum : short {
    GridModeGeographic, // 47˚ 33'
    GridModeGeographicDecimal, // 47.56
    GridModeUTM // 32T 5910
} CoordinateGridMode;

// UTM grid is missing for now

@interface RMCoordinateGridSource : RMAbstractMercatorTileSource

@property (nonatomic, assign) CoordinateGridMode gridMode;

@property (nonatomic, strong) UIColor *gridColor;
@property (nonatomic, assign) CGFloat  gridLineWidth;
@property (nonatomic, assign) NSUInteger gridLabelInterval;

@property (nonatomic, strong) UIColor *minorLabelColor;
@property (nonatomic, strong) UIFont  *minorLabelFont;
@property (nonatomic, strong) UIColor *majorLabelColor;
@property (nonatomic, strong) UIFont  *majorLabelFont;

@end
