//
//  RMMarker.m
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

#import "RMMarker.h"

#import "RMPixel.h"
#import "RMConfiguration.h"

@implementation RMMarker

@synthesize label;
@synthesize textForegroundColor;
@synthesize textBackgroundColor;

#define defaultMarkerAnchorPoint CGPointMake(0.5, 0.5)

#define kCachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

+ (UIFont *)defaultFont
{
    return [UIFont systemFontOfSize:15];
}

// init
- (id)init
{
    if (!(self = [super init]))
        return nil;

    label = nil;
    textForegroundColor = [UIColor blackColor];
    textBackgroundColor = [UIColor clearColor];

    return self;
}

- (id)initWithUIImage:(UIImage *)image
{
    return [self initWithUIImage:image anchorPoint:defaultMarkerAnchorPoint];
}

- (id)initWithUIImage:(UIImage *)image anchorPoint:(CGPoint)_anchorPoint
{
    if (!(self = [self init]))
        return nil;

    self.contents = (id)[image CGImage];
    self.contentsScale = image.scale;
    self.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    self.anchorPoint = _anchorPoint;

    self.masksToBounds = NO;
    self.label = nil;

    return self;
}

- (id)initWithMapboxMarkerImage
{
    return [self initWithMapboxMarkerImage:nil tintColor:nil size:RMMarkerMapboxImageSizeMedium];
}

- (id)initWithMapboxMarkerImage:(NSString *)symbolName
{
    return [self initWithMapboxMarkerImage:symbolName tintColor:nil size:RMMarkerMapboxImageSizeMedium];
}

- (id)initWithMapboxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color
{
    return [self initWithMapboxMarkerImage:symbolName tintColor:color size:RMMarkerMapboxImageSizeMedium];
}

- (id)initWithMapboxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color size:(RMMarkerMapboxImageSize)size
{
    NSString *sizeString = nil;
    
    switch (size)
    {
        case RMMarkerMapboxImageSizeSmall:
            sizeString = @"small";
            break;
        
        case RMMarkerMapboxImageSizeMedium:
        default:
            sizeString = @"medium";
            break;
        
        case RMMarkerMapboxImageSizeLarge:
            sizeString = @"large";
            break;
    }
    
    NSString *colorHex = nil;
    
    if (color)
    {
        CGFloat white, red, green, blue, alpha;

        if ([color getRed:&red green:&green blue:&blue alpha:&alpha])
        {
            colorHex = [NSString stringWithFormat:@"%02lx%02lx%02lx", (unsigned long)(red * 255), (unsigned long)(green * 255), (unsigned long)(blue * 255)];
        }
        else if ([color getWhite:&white alpha:&alpha])
        {
            colorHex = [NSString stringWithFormat:@"%02lx%02lx%02lx", (unsigned long)(white * 255), (unsigned long)(white * 255), (unsigned long)(white * 255)];
        }
    }
    
    return [self initWithMapboxMarkerImage:symbolName tintColorHex:colorHex sizeString:sizeString];
}

- (id)initWithMapboxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex
{
    return [self initWithMapboxMarkerImage:symbolName tintColorHex:colorHex sizeString:@"medium"];
}

- (id)initWithMapboxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex sizeString:(NSString *)sizeString
{
    BOOL useRetina = ([[UIScreen mainScreen] scale] > 1.0);

    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.tiles.mapbox.com/v4/marker/pin-%@%@%@%@.png%@",
                                               (sizeString ? [sizeString substringToIndex:1] : @"m"),
                                               (symbolName ? [@"-" stringByAppendingString:symbolName] : @""),
                                               (colorHex   ? [@"+" stringByAppendingString:[colorHex stringByReplacingOccurrencesOfString:@"#" withString:@""]] : @"+ff0000"),
                                               (useRetina  ? @"@2x" : @""),
                                               [@"?access_token=" stringByAppendingString:[[RMConfiguration sharedInstance] accessToken]]]];

    UIImage *image = nil;
    
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", kCachesPath, [imageURL lastPathComponent]];
    
    if ((image = [UIImage imageWithData:[NSData dataWithContentsOfFile:cachePath] scale:(useRetina ? 2.0 : 1.0)]) && image)
        return [self initWithUIImage:image];
    
    [[NSFileManager defaultManager] createFileAtPath:cachePath contents:[NSData brandedDataWithContentsOfURL:imageURL] attributes:nil];
    
    return [self initWithUIImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:cachePath] scale:(useRetina ? 2.0 : 1.0)]];
}

+ (void)clearCachedMapboxMarkers
{
    for (NSString *filePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kCachesPath error:nil])
        if ([[filePath lastPathComponent] hasPrefix:@"pin-"] && [[filePath lastPathComponent] hasSuffix:@".png"])
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", kCachesPath, filePath] error:nil];
}

#pragma mark -

- (void)replaceUIImage:(UIImage *)image
{
    [self replaceUIImage:image anchorPoint:defaultMarkerAnchorPoint];
}

- (void)replaceUIImage:(UIImage *)image anchorPoint:(CGPoint)_anchorPoint
{
    self.contents = (id)[image CGImage];
    self.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    self.anchorPoint = _anchorPoint;

    self.masksToBounds = NO;
}

- (void)setLabel:(UIView *)aView
{
    if (label == aView)
        return;

    if (label != nil)
        [[label layer] removeFromSuperlayer];

    if (aView != nil)
    {
        label = aView;
        [self addSublayer:[label layer]];
    }
}

- (void)setTextBackgroundColor:(UIColor *)newTextBackgroundColor
{
    textBackgroundColor = newTextBackgroundColor;

    self.label.backgroundColor = textBackgroundColor;
}

- (void)setTextForegroundColor:(UIColor *)newTextForegroundColor
{
    textForegroundColor = newTextForegroundColor;

    if ([self.label respondsToSelector:@selector(setTextColor:)])
        ((UILabel *)self.label).textColor = textForegroundColor;
}

- (void)changeLabelUsingText:(NSString *)text
{
    CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:[RMMarker defaultFont]].width / 2, 4);
    [self changeLabelUsingText:text position:position font:[RMMarker defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void)changeLabelUsingText:(NSString*)text position:(CGPoint)position
{
    [self changeLabelUsingText:text position:position font:[RMMarker defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void)changeLabelUsingText:(NSString *)text font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor
{
    CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:font].width / 2, 4);
    [self setTextForegroundColor:textColor];
    [self setTextBackgroundColor:backgroundColor];
    [self changeLabelUsingText:text  position:position font:font foregroundColor:textColor backgroundColor:backgroundColor];
}

- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor
{
    CGSize textSize = [text sizeWithFont:font];
    CGRect frame = CGRectMake(position.x, position.y, textSize.width+4, textSize.height+4);

    UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
    [self setTextForegroundColor:textColor];
    [self setTextBackgroundColor:backgroundColor];
    [aLabel setNumberOfLines:0];
    [aLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aLabel setBackgroundColor:backgroundColor];
    [aLabel setTextColor:textColor];
    [aLabel setFont:font];
    [aLabel setTextAlignment:NSTextAlignmentCenter];
    [aLabel setText:text];

    [self setLabel:aLabel];
}

- (void)toggleLabel
{
    if (self.label == nil)
        return;

    if ([self.label isHidden])
        [self showLabel];
    else
        [self hideLabel];
}

- (void)showLabel
{
    if ([self.label isHidden])
    {
        // Using addSublayer will animate showing the label, whereas setHidden is not animated
        [self addSublayer:[self.label layer]];
        [self.label setHidden:NO];
    }
}

- (void)hideLabel
{
    if (![self.label isHidden])
    {
        // Using removeFromSuperlayer will animate hiding the label, whereas setHidden is not animated
        [[self.label layer] removeFromSuperlayer];
        [self.label setHidden:YES];
    }
}

- (void)setDragState:(RMMapLayerDragState)dragState animated:(BOOL)animated
{
    if (dragState == RMMapLayerDragStateStarting)
    {
        [CATransaction begin];
        [CATransaction setAnimationDuration:(animated ? 0.3 : 0)];

        self.opacity -= 0.1;
        self.transform = CATransform3DScale(self.transform, 1.3, 1.3, 1.0);

        [CATransaction setCompletionBlock:^(void)
        {
            [super setDragState:RMMapLayerDragStateDragging animated:animated];
        }];

        [CATransaction commit];
    }
    else if (dragState == RMMapLayerDragStateCanceling || dragState == RMMapLayerDragStateEnding)
    {
        [CATransaction begin];
        [CATransaction setAnimationDuration:(animated ? 0.3 : 0)];

        self.opacity += 0.1;
        self.transform = CATransform3DScale(self.transform, 1.0/1.3, 1.0/1.3, 1.0);

        [CATransaction setCompletionBlock:^(void)
        {
             [super setDragState:RMMapLayerDragStateNone animated:animated];
        }];

        [CATransaction commit];
    }
    else
    {
        [super setDragState:dragState animated:animated];
    }
}

@end
