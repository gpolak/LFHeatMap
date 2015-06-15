/*
 * LFHeatMap
 * Copyright: (2015) George Polak
 * https://github.com/gpolak/LFHeatMap
 * License: MIT
 */

#import <Foundation/Foundation.h>
#import <Mapbox-iOS-SDK/Mapbox.h>

extern inline CGRect CGRectContainingPoints(NSArray *points);
extern inline CGPoint CGPointOffset(CGPoint point, CGFloat xOffset, CGFloat yOffset);

@interface RMHeatmapAnnotation : RMAnnotation

@property (nonatomic, strong) UIImage *heatmapImage;

@end

@interface RMHeatmapMarker : RMMarker

- (instancetype)initWithHeatmapAnnotation:(RMHeatmapAnnotation *)heatmapAnnotation;

@end

@interface LFHeatMap : NSObject
{
}

/**
 Generates a heat map annotation for the specified map view.
 
 There should be a one-to-one correspondence between the location and weight elements.
 A nil weight parameter implies an even weight distribution.
 
 @param mapView Map view representing the heat map area.
 @param boost heat boost value
 @param locations array of CLLocation objects representing the data points
 @param weights array of NSNumber integer objects representing the weight of each point
 
 @warning If the heatmap image generated is too big, this method will return nil
 
 @return RMHeatmapAnnotation object representing the heatmap ready to be added to the map
 */
+ (RMHeatmapAnnotation *)heatMapAnnotationForMapView:(RMMapView *)mapView
                                               boost:(float)boost
                                           locations:(NSArray *)locations
                                             weights:(NSArray *)weights;


@end

