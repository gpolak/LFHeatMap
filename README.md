# LFHeatMap for Mapbox

iOS heat map package

![LFHeatMap](lfheatmap_screenshot.png)

##Usage

**1. Add annotation to the map**

```objective-c
self.heatmapAnnotation = [LFHeatMap heatMapAnnotationForMapView:self.mapView
                                                          boost:self.slider.value
                                                      locations:self.locations
                                                        weights:self.weights];
                                                        
if (self.heatmapAnnotation) 
    [self.mapView addAnnotation:self.heatmapAnnotation];
else
    NSLog(@"Resulting heatmap is too big");
```

**2. Return layer through the map delegate**

```objective-c
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
```

## Features
* extremely fast heat map generation from point/weight data pairs
* generates UIImage objects that can be overlaid as needed
* variable boost/bleed

## Anti-Features
Size of the heatmap is limited to avoid memory overflow.

Check out [DTMHeatMap](https://github.com/dataminr/DTMHeatmap) for an implementation supporting `MKOverlay`.

## Adding LFHeatMap to Your Project

### Source Files

Copy the `LFHeatMap` folder to your project.

### .NET/Xamarin Port
https://github.com/rmarinho/LFHeatMap

## Demo
This demo plots the measured magnitudes of the [2011 Virginia Earthquake](http://en.wikipedia.org/wiki/2011_Virginia_earthquake).

### Running
1. Open and launch the LFHeatMapDemo XCode project. 
2. Move the slider on the bottom to adjust the boost.

### Explanation

The data is stored in `quake.plist` which is a simple plist storing the latitude, longitude, and magnitude of each measurement. The points (locations) and weights (magnitudes) are stored in two `NSArray` objects in `viewDidLoad` of `LFHeatMapDemoViewController`.

With the above data, `LFHeatMap` generates an `RMAnnotation` instance that you can add to your Mapbox map directly.

## License

LFHeatMap is available under the MIT license. See the LICENSE file for more info.


## LF?

LFHeatMap comes from my work on the (now shut down) LocalFaves framework from [Skyhook Wireless](http://skyhookwireless.com). This component has been open-sourced and formed the basis of a chapter in the [Geolocation in iOS](http://www.amazon.com/Geolocation-iOS-Mobile-Positioning-Mapping/dp/1449308449/ref=sr_1_18?ie=UTF8&qid=undefined&sr=8-18&keywords=corelocation) book.
