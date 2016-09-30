//
//  RMGreatCircleAnnotation.m
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

#import "RMGreatCircleAnnotation.h"

#import "RMShape.h"

@implementation RMGreatCircleAnnotation

- (id)initWithMapView:(RMMapView *)aMapView coordinate1:(CLLocationCoordinate2D)coordinate1 coordinate2:(CLLocationCoordinate2D)coordinate2
{
    NSAssert(coordinate1.latitude != coordinate2.latitude || coordinate1.longitude != coordinate2.longitude, @"Start and end coordinates must differ.");

    if (!(self = [super initWithMapView:aMapView points:@[ [[CLLocation alloc] initWithLatitude:coordinate1.latitude longitude:coordinate1.longitude], [[CLLocation alloc] initWithLatitude:coordinate2.latitude longitude:coordinate2.longitude]]]))
        return nil;

    _coordinate1 = coordinate1;
    _coordinate2 = coordinate2;

    return self;
}

- (RMMapLayer *)layer
{
    if ( ! [super layer])
    {
        RMShape *shape = [[RMShape alloc] initWithView:self.mapView];

        [shape performBatchOperations:^(RMShape *aShape)
        {
            // based on implementation at http://stackoverflow.com/questions/6104517/drawing-great-circle-overlay-lines-on-an-mkmapview
            //
            double lat1 = self.coordinate1.latitude;
            double lon1 = self.coordinate1.longitude;
            double lat2 = self.coordinate2.latitude;
            double lon2 = self.coordinate2.longitude;
            lat1 = lat1 * (M_PI/180);
            lon1 = lon1 * (M_PI/180);
            lat2 = lat2 * (M_PI/180);
            lon2 = lon2 * (M_PI/180);
            double d = 2 * asin( sqrt(pow(( sin( (lat1-lat2)/2) ), 2) + cos(lat1) * cos(lat2) * pow(( sin( (lon1-lon2)/2) ), 2)));
            int numsegs = 100;
            NSMutableArray *coords = [NSMutableArray arrayWithCapacity:numsegs];
            double f = 0.0;
            for(int i=1; i<=numsegs; i++)
            {
                f += 1.0 / (float)numsegs;
                double A=sin((1-f)*d)/sin(d);
                double B=sin(f*d)/sin(d);
                double x = A*cos(lat1) * cos(lon1) +  B * cos(lat2) * cos(lon2);
                double y = A*cos(lat1) * sin(lon1) +  B * cos(lat2) * sin(lon2);
                double z = A*sin(lat1)           +  B*sin(lat2);
                double latr=atan2(z, sqrt(pow(x, 2) + pow(y, 2) ));
                double lonr=atan2(y, x);
                double lat = latr * (180/M_PI);
                double lon = lonr * (180/M_PI);
                [coords addObject:[[CLLocation alloc] initWithLatitude:lat longitude:lon]];
            }
            CLLocationCoordinate2D prevCoord;
            NSMutableArray *coords2 = [NSMutableArray array];
            for(int i=0; i<numsegs; i++)
            {
                CLLocationCoordinate2D coord = ((CLLocation *)coords[i]).coordinate;
                if(prevCoord.longitude < -170 && prevCoord.longitude > -180  && prevCoord.longitude < 0
                   && coord.longitude > 170 && coord.longitude < 180 && coord.longitude > 0)
                {
                    [coords2 addObjectsFromArray:[coords subarrayWithRange:NSMakeRange(i, [coords count] - i)]];
                    [coords removeObjectsInRange:NSMakeRange(i, [coords count] - i)];
                    break;
                }
                prevCoord = coord;
            }

            [aShape moveToCoordinate:((CLLocation *)coords[0]).coordinate];

            for (int i = 1; i < [coords count]; i++)
                [aShape addLineToCoordinate:((CLLocation *)coords[i]).coordinate];

            if ([coords2 count])
            {
                [aShape moveToCoordinate:((CLLocation *)coords2[0]).coordinate];

                for (int j = 1; j < [coords2 count]; j++)
                    [aShape addLineToCoordinate:((CLLocation *)coords2[j]).coordinate];
            }
        }];

        super.layer = shape;
    }
    
    return [super layer];
}

@end
