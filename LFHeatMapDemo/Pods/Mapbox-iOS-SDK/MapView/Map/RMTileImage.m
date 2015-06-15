//
//  RMTileImage.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
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

#import "RMTileImage.h"

static BOOL _didLoadErrorTile = NO;
static BOOL _didLoadMissingTile = NO;
static UIImage *_errorTile = nil;
static UIImage *_missingTile = nil;

@implementation RMTileImage

+ (UIImage *)errorTile
{
    if (_errorTile)
        return _errorTile;

    if (_didLoadErrorTile)
        return nil;

    _errorTile = [UIImage imageNamed:@"error.png"];
    _didLoadErrorTile = YES;

    return _errorTile;
}

+ (void)setErrorTile:(UIImage *)newErrorTile
{
    if (_errorTile == newErrorTile) return;
    _errorTile = newErrorTile;
    _didLoadErrorTile = YES;
}

+ (UIImage *)missingTile
{
    if (_missingTile)
        return _missingTile;

    if (_didLoadMissingTile)
        return nil;

    _missingTile = [UIImage imageNamed:@"missing.png"];
    _didLoadMissingTile = YES;

    return _missingTile;
}

+ (void)setMissingTile:(UIImage *)newMissingTile
{
    if (_missingTile == newMissingTile) return;
    _missingTile = newMissingTile;
    _didLoadMissingTile = YES;
}

@end
