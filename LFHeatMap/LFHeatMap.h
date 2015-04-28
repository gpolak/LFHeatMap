/*
 * LFHeatMap
 * Copyright: (2015) George Polak
 * https://github.com/gpolak/LFHeatMap
 * License: MIT
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LFHeatMap : NSObject
{    
}

/**
 Generates a heat map image for the specified map view.
 
 There should be a one-to-one correspondence between the location and weight elements.
 A nil weight parameter implies an even weight distribution.
 
 @params 
 mapView: Map view representing the heat map area.
 boost: heat boost value
 locations: array of CLLocation objects representing the data points
 weights: array of NSNumber integer objects representing the weight of each point
 
 @returns
 UIImage object representing the heatmap for the map region.
 */
+ (UIImage *)heatMapForMapView:(MKMapView *)mapView
                         boost:(float)boost
                     locations:(NSArray *)locations
                       weights:(NSArray *)weights;

/**
 Generates a heat map image for the specified rectangle.
 
 There should be a one-to-one correspondence between the location and weight elements.
 A nil weight parameter implies an even weight distribution.
 
 @params
 @rect: region frame
 boost: heat boost value
 points: array of NSValue CGPoint objects representing the data points
 weights: array of NSNumber integer objects representing the weight of each point
 
 @returns
 UIImage object representing the heatmap for the specified region.
 */
+ (UIImage *)heatMapWithRect:(CGRect)rect 
                       boost:(float)boost 
                      points:(NSArray *)points 
                     weights:(NSArray *)weights;

/**
 Generates a heat map image for the specified rectangle.
 
 There should be a one-to-one correspondence between the location and weight elements.
 A nil weight parameter implies an even weight distribution.
 
 @params
 @rect: region frame
 boost: heat boost value
 points: array of NSValue CGPoint objects representing the data points
 weights: array of NSNumber integer objects representing the weight of each point
 weightsAdjustmentEnabled: set YES for weight balancing and normalization
 groupingEnabled: set YES for tighter visual grouping of dense areas
 
 @returns
 UIImage object representing the heatmap for the specified region.
 */
+ (UIImage *)heatMapWithRect:(CGRect)rect 
                       boost:(float)boost 
                      points:(NSArray *)points 
                     weights:(NSArray *)weights 
    weightsAdjustmentEnabled:(BOOL)weightsAdjustmentEnabled
             groupingEnabled:(BOOL)groupingEnabled;


@end

