//
//  LFHeadMapDemoViewController.m
//  LFHeatMapDemo
//
//  Created by George Polak on 7/18/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import "LFHeadMapDemoViewController.h"
#import "LFHeatMap.h"

@interface LFHeadMapDemoViewController () <RMMapViewDelegate>

@property (nonatomic, weak) IBOutlet UISlider *slider;
@property (nonatomic, weak) IBOutlet UILabel *heatmapWarningLabel;

@property (nonatomic, strong) RMMapView *mapView;
@property (nonatomic, strong) RMAnnotation *heatmapAnnotation;

@property (nonatomic) NSMutableArray *locations;
@property (nonatomic) NSMutableArray *weights;

@end


@implementation LFHeadMapDemoViewController

static NSString *const kLatitude = @"latitude";
static NSString *const kLongitude = @"longitude";
static NSString *const kMagnitude = @"magnitude";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupMap];
    [self loadEarthquakeData];
    [self loadHeatmapAnnotation];
    
    self.mapView.centerCoordinate = self.heatmapAnnotation.coordinate;
}

- (void)setupMap
{
    if (self.mapView) return;
    
    //setup mapbox
    NSString *mapId = @"jakunico.mbpa5ak4";
    NSString *accessToken = @"pk.eyJ1IjoiamFrdW5pY28iLCJhIjoiNjAwNDYyYjgxYjk0MTBjNjJiMDI5YmFjMDE2NWIzM2UifQ.KCo52mPGceAjzWvI5ushpQ";
    
    NSAssert([mapId length], @"You must set a Mapbox mapId");
    NSAssert([accessToken length], @"You must set an access token");
    
    [RMConfiguration sharedInstance].accessToken = accessToken;
    RMMapboxSource *source = [[RMMapboxSource alloc] initWithMapID:mapId];
    
    self.mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source];
    self.mapView.zoom = 2;
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.mapView belowSubview:self.slider];
}

- (void)loadEarthquakeData
{
    NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"quake" ofType:@"plist"];
    NSArray *quakeData = [[NSArray alloc] initWithContentsOfFile:dataFile];
    
    self.locations = [[NSMutableArray alloc] initWithCapacity:[quakeData count]];
    self.weights = [[NSMutableArray alloc] initWithCapacity:[quakeData count]];
    for (NSDictionary *reading in quakeData)
    {
        CLLocationDegrees latitude = [[reading objectForKey:kLatitude] doubleValue];
        CLLocationDegrees longitude = [[reading objectForKey:kLongitude] doubleValue];
        double magnitude = [[reading objectForKey:kMagnitude] doubleValue];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        [self.locations addObject:location];
        
        [self.weights addObject:[NSNumber numberWithInteger:(magnitude * 10)]];
    }
}

- (void)loadHeatmapAnnotation
{
    if (self.heatmapAnnotation) {
        [self.mapView removeAnnotation:self.heatmapAnnotation];
    }
    
    self.heatmapAnnotation = [LFHeatMap heatMapAnnotationForMapView:self.mapView
                                                              boost:self.slider.value
                                                          locations:self.locations
                                                            weights:self.weights];
    
    if (self.heatmapAnnotation) {
        
        [self.mapView addAnnotation:self.heatmapAnnotation];
        self.heatmapWarningLabel.hidden = YES;
        
    } else {
        
        self.heatmapWarningLabel.hidden = NO;
        
    }
    
}

- (void)removeHeatmapAnnotation
{
    if (self.heatmapAnnotation) {
        [self.mapView removeAnnotation:self.heatmapAnnotation];
        self.heatmapAnnotation = nil;
    }
}

- (IBAction)sliderChanged:(UISlider *)slider
{
    [self loadHeatmapAnnotation];
}

#pragma mark RMMapView Delegate

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if (annotation.isUserLocationAnnotation) return nil;
    
    if (annotation.class == [RMHeatmapAnnotation class])
    {
        RMHeatmapMarker *heatmapMarker = [[RMHeatmapMarker alloc] initWithHeatmapAnnotation:(RMHeatmapAnnotation*)annotation];
        
        return heatmapMarker;
    }
    
    NSAssert(NO, @"Could not provide layer for annotation: %@", annotation);
    
    return nil;
}

- (void)beforeMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction
{
    [self removeHeatmapAnnotation];
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction
{
    [self sliderChanged:self.slider];
}

@end
