/*
 * LFHeatMap
 * Copyright: (2015) George Polak
 * https://github.com/gpolak/LFHeatMap
 * License: MIT
 */

#import "LFHeatMap.h"


@implementation LFHeatMap

inline static int isqrt(int x)
{
    static const int sqrttable[] = {
        0, 16, 22, 27, 32, 35, 39, 42, 45, 48, 50, 53, 55, 57,
        59, 61, 64, 65, 67, 69, 71, 73, 75, 76, 78, 80, 81, 83,
        84, 86, 87, 89, 90, 91, 93, 94, 96, 97, 98, 99, 101, 102,
        103, 104, 106, 107, 108, 109, 110, 112, 113, 114, 115, 116, 117, 118,
        119, 120, 121, 122, 123, 124, 125, 126, 128, 128, 129, 130, 131, 132,
        133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 144, 145,
        146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 155, 156, 157,
        158, 159, 160, 160, 161, 162, 163, 163, 164, 165, 166, 167, 167, 168,
        169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 178,
        179, 180, 181, 181, 182, 183, 183, 184, 185, 185, 186, 187, 187, 188,
        189, 189, 190, 191, 192, 192, 193, 193, 194, 195, 195, 196, 197, 197,
        198, 199, 199, 200, 201, 201, 202, 203, 203, 204, 204, 205, 206, 206,
        207, 208, 208, 209, 209, 210, 211, 211, 212, 212, 213, 214, 214, 215,
        215, 216, 217, 217, 218, 218, 219, 219, 220, 221, 221, 222, 222, 223,
        224, 224, 225, 225, 226, 226, 227, 227, 228, 229, 229, 230, 230, 231,
        231, 232, 232, 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238,
        239, 240, 240, 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246,
        246, 247, 247, 248, 248, 249, 249, 250, 250, 251, 251, 252, 252, 253,
        253, 254, 254, 255
    };
    
    int xn;
	
    if (x >= 0x10000) 
    {
        if (x >= 0x1000000) 
        {
            if (x >= 0x10000000) 
            {
                if (x >= 0x40000000) 
                {
                    xn = sqrttable[x >> 24] << 8;
                } 
                else 
                {
                    xn = sqrttable[x >> 22] << 7;
                }
            } 
            else 
            {
                if (x >= 0x4000000) 
                {
                    xn = sqrttable[x >> 20] << 6;
                } 
                else 
                {
                    xn = sqrttable[x >> 18] << 5;
                }
            }
			
            xn = (xn + 1 + (x / xn)) >> 1;
            xn = (xn + 1 + (x / xn)) >> 1;
			
            return ((xn * xn) > x) ? --xn : xn;
        } 
        else 
        {
            if (x >= 0x100000) 
            {
                if (x >= 0x400000) 
                {
                    xn = sqrttable[x >> 16] << 4;
                } 
                else 
                {
                    xn = sqrttable[x >> 14] << 3;
                }
            } 
            else 
            {
                if (x >= 0x40000) 
                {
                    xn = sqrttable[x >> 12] << 2;
                } 
                else 
                {
                    xn = sqrttable[x >> 10] << 1;
                }
            }
			
            xn = (xn + 1 + (x / xn)) >> 1;
			
            return ((xn * xn) > x) ? --xn : xn;
        }
    }
    else
    {
        if (x >= 0x100) 
        {
            if (x >= 0x1000) 
            {
                if (x >= 0x4000) 
                {
                    xn = (sqrttable[x >> 8] ) + 1;
                } 
                else 
                {
                    xn = (sqrttable[x >> 6] >> 1) + 1;
                }
            } 
            else 
            {
                if (x >= 0x400) 
                {
                    xn = (sqrttable[x >> 4] >> 2) + 1;
                } 
                else 
                {
                    xn = (sqrttable[x >> 2] >> 3) + 1;
                }
            }
			
            return ((xn * xn) > x) ? --xn : xn;
        }
        else
        {
            if (x >= 0)
            {
                return sqrttable[x] >> 4;
            }
            else
            {
                return -1; // negative argument...
            }
        }
    }
}

+ (UIImage *)heatMapForMapView:(MKMapView *)mapView
                         boost:(float)boost
                     locations:(NSArray *)locations
                       weights:(NSArray *)weights
{
    if (!mapView || !locations)
        return nil;
    
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:[locations count]];
    for (NSInteger i = 0; i < [locations count]; i++)
    {
        CLLocation *location = [locations objectAtIndex:i];        
        CGPoint point = [mapView convertCoordinate:location.coordinate toPointToView:mapView];        
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    
    return [LFHeatMap heatMapWithRect:mapView.frame boost:boost points:points weights:weights];
}

+ (UIImage *)heatMapWithRect:(CGRect)rect
                       boost:(float)boost
                      points:(NSArray *)points
                     weights:(NSArray *)weights
{
    return [LFHeatMap heatMapWithRect:rect
                                boost:boost
                               points:points
                              weights:weights
             weightsAdjustmentEnabled:NO
                      groupingEnabled:YES];
}

+ (UIImage *)heatMapWithRect:(CGRect)rect
                       boost:(float)boost
                      points:(NSArray *)points
                     weights:(NSArray *)weights
    weightsAdjustmentEnabled:(BOOL)weightsAdjustmentEnabled
             groupingEnabled:(BOOL)groupingEnabled
{
	
    // Adjustment variables for weights adjustment
    float weightSensitivity = 1; // Percents from maximum weight
    float weightBoostTo = 50; // Percents to boost least sensible weight to
    
    // Adjustment variables for grouping
    int groupingThreshold = 10;  // Increasing this will improve performance with less accuracy. Negative will disable grouping
    int peaksRemovalThreshold = 20; // Should be greater than groupingThreshold
    float peaksRemovalFactor = 0.4; // Should be from 0 (no peaks removal) to 1 (peaks are completely lowered to zero)
    
    // Validate arguments
    if (points == nil ||
        rect.size.width <= 0 ||
        rect.size.height <= 0 ||
        (weights != nil &&
		 [points count] != [weights count]))
    {
        NSLog(@"LFHeatMap: heatMapWithRect: incorrect arguments");
        return nil;
    }
    
    UIImage* image = nil;
    int width = rect.size.width;
    int height = rect.size.height;
    int i, j;
    
    // According to heatmap API, boost is heat radius multiplier
    int radius = 50 * boost;
    
    // RGBA array is initialized with 0s
    unsigned char* rgba = (unsigned char*)calloc(width*height*4, sizeof(unsigned char));
    int* density = (int*)calloc(width*height, sizeof(int));
    memset(density, 0, sizeof(int) * width*height);
    
    // Step 1
    // Copy points into plain array (plain array iteration is faster than accessing NSArray objects)
    int points_num = (int)[points count];
    int *point_x = malloc(sizeof(int) * points_num);
    int *point_y = malloc(sizeof(int) * points_num);
    int *point_weight_percent = malloc(sizeof(int) * points_num);
    float *point_weight = 0;
    float max_weight = 0;
    if (weights != nil)
    {
        point_weight = malloc(sizeof(float) * points_num);
        max_weight = 0.0;
    }
	
    i = 0;
    j = 0;
    for (NSValue* pointValue in points)
    {
        point_x[i] = [pointValue CGPointValue].x - rect.origin.x;
        point_y[i] = [pointValue CGPointValue].y - rect.origin.y;
        
        // Filter out of range points
        if (point_x[i] < 0 - radius ||
            point_y[i] < 0 - radius ||
            point_x[i] >= rect.size.width + radius ||
            point_y[i] >= rect.size.height + radius)
        {
            points_num--;
            j++;
            // Do not increment i, to replace this point in next iteration (or drop if it is last one)
            // but increment j to leave consistency when accessing weights
            continue;
        }
		
        // Fill weights if available
        if (weights != nil)
        {
            NSNumber* weightValue = [weights objectAtIndex:j];
            
            point_weight[i] = [weightValue floatValue];
            if (max_weight < point_weight[i])
                max_weight = point_weight[i];
        }
        
        i++;
        j++;
    }
    
    // Step 1.5
    // Normalize weights to be 0 .. 100 (like percents)
    // Weights array should be integer for not slowing down calculation by
    // int-float conversion and float multiplication
    if (weights != nil)
    {
        float absWeightSensitivity = ( max_weight / 100.0 ) * weightSensitivity;
        float absWeightBoostTo = ( max_weight / 100.0 ) * weightBoostTo;
        for (i = 0; i < points_num; i++)
        {
            if (weightsAdjustmentEnabled)
            {
                if (point_weight[i] <= absWeightSensitivity)
                    point_weight[i] *= absWeightBoostTo / absWeightSensitivity;
                else
                    point_weight[i] = absWeightBoostTo + ( point_weight[i] - absWeightSensitivity ) * ((max_weight - absWeightBoostTo) / (max_weight - absWeightSensitivity));
            }
            point_weight_percent[i] = 100.0 * (point_weight[i] / max_weight);
        }
        free(point_weight);
    } else
    {
        // Fill with 1 in case if no weights provided
        for (i = 0; i < points_num; i++)
        {
            point_weight_percent[i] = 1;
        }
    }
    
    // Step 1.75 (optional)
    // Grouping and filtering bunches of points in same location
    int currentDistance;
    int currentDensity;
        
    if (groupingEnabled)
    {
        for (i = 0; i < points_num; i++)
        {
            if (point_weight_percent[i]> 0)
            {
                for (j = i + 1; j < points_num; j++)
                {
                    if (point_weight_percent[j]> 0)
                    {
                        currentDistance = isqrt((point_x[i] - point_x[j])*(point_x[i] - point_x[j]) + (point_y[i] - point_y[j])*(point_y[i] - point_y[j]));
                        
                        if (currentDistance > peaksRemovalThreshold)
                            currentDistance = peaksRemovalThreshold;
                        
                        float K1 = 1 - peaksRemovalFactor;
                        float K2 = peaksRemovalFactor;
                        
                        // Lowering peaks
                        point_weight_percent[i] =
                        K1 * point_weight_percent[i] +
                        K2 * point_weight_percent[i] * (float) ((float)(currentDistance) / (float)peaksRemovalThreshold);
                        
                        // Performing grouping if two points are closer than groupingThreshold
                        if (currentDistance <= groupingThreshold)
                        {
                            // Merge i and j points. Store result in [i], remove [j]
                            point_x[i] = (point_x[i] + point_x[j]) / 2;
                            point_y[i] = (point_y[i] + point_y[j]) / 2;
                            point_weight_percent[i] = point_weight_percent[i] + point_weight_percent[j];
                            
                            // point_weight_percent[j] is set negative to be avoided
                            point_weight_percent[j] = -10;
                            
                            // Repeat again for new point
                            i--;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    // Step 2
    // Fill density info. Density is calculated around each point
    int from_x, from_y, to_x, to_y;
    for (i = 0; i < points_num; i++)
    {
        if (point_weight_percent[i]> 0)
        {
            from_x = point_x[i] - radius;
            from_y = point_y[i] - radius;
            to_x = point_x[i] + radius;
            to_y = point_y[i] + radius;
            
            if (from_x < 0)
                from_x = 0;
            if (from_y < 0)
                from_y = 0;
            if (to_x > width)
                to_x = width;
            if (to_y > height)
                to_y = height;
            
            
            for (int y = from_y; y < to_y; y++)
            {
                for (int x = from_x; x < to_x; x++)
                {
                    currentDistance = (x - point_x[i])*(x - point_x[i]) + (y - point_y[i])*(y - point_y[i]);
                    
                    currentDensity = radius - isqrt(currentDistance);
                    if (currentDensity < 0)
                        currentDensity = 0;
                    
                    density[y*width + x] += currentDensity * point_weight_percent[i];
                }
            }
        }
    }
    
    
    free(point_x);
    free(point_y);
    free(point_weight_percent);
    
    
    // Step 2.5
    // Find max density (doing this in step 2 will have less performance)
    int maxDensity = density[0];
    for (i = 1; i < width * height; i++)
    {
        if (maxDensity < density[i])
            maxDensity = density[i];
    }
    
    // Step 3
    // Render density info into raw RGBA pixels
    i = 0;
    float floatDensity;
    uint indexOrigin;
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++, i++)
        {
            if (density[i] > 0)
            {
                indexOrigin = 4*i;
                // Normalize density to 0..1
                floatDensity = (float)density[i] / (float)maxDensity;
                
                // Red and alpha component
                rgba[indexOrigin] = floatDensity * 255;
                rgba[indexOrigin+3] = rgba[indexOrigin];
                
                 // Green component
                if (floatDensity >= 0.75)
                    rgba[indexOrigin+1] = rgba[indexOrigin];
                else if (floatDensity >= 0.5)
                    rgba[indexOrigin+1] = (floatDensity - 0.5) * 255 * 3;
               
                
                // Blue component
                if (floatDensity >= 0.8)
                    rgba[indexOrigin+2] = (floatDensity - 0.8) * 255 * 5;
            }
        }
    }
    
    free(density);
    
    // Step 4
    // Create image from rendered raw data
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(rgba,
                                                       width,
                                                       height,
                                                       8, // bitsPerComponent
                                                       4 * width, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    
    CFRelease(colorSpace);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    
    image = [UIImage imageWithCGImage:cgImage];
    
    CFRelease(cgImage);
    CFRelease(bitmapContext);
    
    free(rgba);
    
    return image;
}

@end

