//
//  RMTile.h
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

#ifndef _RMTILE_H_
#define _RMTILE_H_

#include <CoreGraphics/CGGeometry.h>
#include <stdint.h>

// Uniquely specifies coordinates and zoom level for a particular tile in some tile source.
typedef struct {
	uint32_t x, y;
	short zoom;
} RMTile;

typedef struct {
	RMTile tile;
	CGPoint offset;
} RMTilePoint;

typedef struct {
	RMTilePoint origin;
	CGSize size;
} RMTileRect;

char RMTilesEqual(RMTile one, RMTile two);

char RMTileIsDummy(RMTile tile);
RMTile RMTileDummy();

RMTile RMTileMake(uint32_t x, uint32_t y, short zoom);

// Return a hash of the tile, used to override the NSObject hash method for RMTile.
uint64_t RMTileHash(RMTile tile);

// Returns a unique key of the tile for use in the SQLite cache
uint64_t RMTileKey(RMTile tile);

// Round the rectangle to whole numbers of tiles
RMTileRect RMTileRectRound(RMTileRect rect);

// Dump a description of the tile to the console
void RMLogTile(RMTile tile);

#endif
