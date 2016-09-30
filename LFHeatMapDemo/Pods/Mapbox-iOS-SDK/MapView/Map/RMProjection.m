//
//  RMProjection.m
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

#import "RMGlobalConstants.h"
#import "proj_api.h"
#import "RMProjection.h"

@implementation RMProjection
{
    // This is actually a PROJ4 projPJ, but it is typed as void* so the proj_api doesn't have to be included
    void *_internalProjection;

    // the size of the earth, in projected units (meters, most often)
    RMProjectedRect	_planetBounds;

    // hardcoded to YES in #initWithString:InBounds:
    BOOL _projectionWrapsHorizontally;
}

@synthesize internalProjection = _internalProjection;
@synthesize planetBounds = _planetBounds;
@synthesize projectionWrapsHorizontally = _projectionWrapsHorizontally;

#pragma mark - Common projections

static RMProjection *_googleProjection = nil;
static RMProjection *_latitudeLongitudeProjection = nil;

+ (instancetype)googleProjection
{
    if (_googleProjection)
    {
        return _googleProjection;
    }
    else
    {
        RMProjectedRect theBounds = RMProjectedRectMake(-20037508.34, -20037508.34, 20037508.34 * 2, 20037508.34 * 2);

        _googleProjection = [[RMProjection alloc] initWithString:@"+title= Google Mercator EPSG:900913 +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs"
                                                        inBounds:theBounds];
        return _googleProjection;
    }
}

+ (instancetype)EPSGLatLong
{
    if (_latitudeLongitudeProjection)
    {
        return _latitudeLongitudeProjection;
    }
    else
    {
        RMProjectedRect theBounds = RMProjectedRectMake(-kMaxLong, -kMaxLat, 360.0, kMaxLong);

        _latitudeLongitudeProjection = [[RMProjection alloc] initWithString:@"+proj=latlong +ellps=WGS84"
                                                                   inBounds:theBounds];
        return _latitudeLongitudeProjection;
    }
}

#pragma mark -

- (id)initWithString:(NSString *)proj4String inBounds:(RMProjectedRect)projectedBounds
{
    if (!(self = [super init]))
        return nil;

    _internalProjection = pj_init_plus([proj4String UTF8String]);

    if (_internalProjection == NULL)
    {
        RMLog(@"Unhandled error creating projection. String is %@", proj4String);
        return nil;
    }

    _planetBounds = projectedBounds;
    _projectionWrapsHorizontally = YES;

    return self;
}

- (id)initWithString:(NSString *)proj4String
{
    RMProjectedRect theBounds;
    theBounds = RMProjectedRectMake(0, 0, 0, 0);

    return [self initWithString:proj4String inBounds:theBounds];
}

- (id)init
{
    return [self initWithString:@"+proj=latlong +ellps=WGS84"];
}

- (void)dealloc
{
    if (_internalProjection)
        pj_free(_internalProjection);
}

- (RMProjectedPoint)wrapPointHorizontally:(RMProjectedPoint)aPoint
{
    if (!_projectionWrapsHorizontally || _planetBounds.size.width == 0.0f || _planetBounds.size.height == 0.0f)
        return aPoint;

    while (aPoint.x < _planetBounds.origin.x)
        aPoint.x += _planetBounds.size.width;

    while (aPoint.x > (_planetBounds.origin.x + _planetBounds.size.width))
        aPoint.x -= _planetBounds.size.width;

    return aPoint;
}

- (RMProjectedPoint)constrainPointToBounds:(RMProjectedPoint)aPoint
{
    if (_planetBounds.size.width == 0.0f || _planetBounds.size.height == 0.0f)
        return aPoint;

    [self wrapPointHorizontally:aPoint];

    if (aPoint.y < _planetBounds.origin.y)
        aPoint.y = _planetBounds.origin.y;
    else if (aPoint.y > (_planetBounds.origin.y + _planetBounds.size.height))
        aPoint.y = _planetBounds.origin.y + _planetBounds.size.height;

    return aPoint;
}

- (RMProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)aLatLong
{
    projUV uv = {
        aLatLong.longitude * DEG_TO_RAD,
        aLatLong.latitude * DEG_TO_RAD
    };

    projUV result = pj_fwd(uv, _internalProjection);

    RMProjectedPoint result_point = {
        result.u,
        result.v,
    };

    return result_point;
}

- (CLLocationCoordinate2D)projectedPointToCoordinate:(RMProjectedPoint)aPoint
{
    projUV uv = {
        aPoint.x,
        aPoint.y,
    };

    projUV result = pj_inv(uv, _internalProjection);

    CLLocationCoordinate2D result_coordinate = {
        result.v * RAD_TO_DEG,
        result.u * RAD_TO_DEG,
    };

    return result_coordinate;
}

#pragma mark - UTM conversions

// This uses code by Chuck Gantz, found at http://www.gpsy.com/gpsinfo/geotoutm/
// It is limited to WGS84, have a look at the original source code if you need more.

//
// Source
// Defense Mapping Agency. 1987b. DMA Technical Report: Supplement to Department of Defense World Geodetic System
// 1984 Technical Report. Part I and II. Washington, DC: Defense Mapping Agency
//

#define deg2rad (M_PI / 180.0)
#define rad2deg (180.0 / M_PI)

// This routine determines the correct UTM letter designator for the given latitude.
// Returns 'Z' if latitude is outside the UTM limits of 84N to 80S
// Written by Chuck Gantz- chuck.gantz@globalstar.com
+ (NSString *)UTMLetterDesignatorForLatitude:(double)latitude
{
    char letterDesignator;

    if ((84 >= latitude) && (latitude >= 72)) letterDesignator = 'X';
    else if ((72 > latitude) && (latitude >= 64)) letterDesignator = 'W';
    else if ((64 > latitude) && (latitude >= 56)) letterDesignator = 'V';
    else if ((56 > latitude) && (latitude >= 48)) letterDesignator = 'U';
    else if ((48 > latitude) && (latitude >= 40)) letterDesignator = 'T';
    else if ((40 > latitude) && (latitude >= 32)) letterDesignator = 'S';
    else if ((32 > latitude) && (latitude >= 24)) letterDesignator = 'R';
    else if ((24 > latitude) && (latitude >= 16)) letterDesignator = 'Q';
    else if ((16 > latitude) && (latitude >= 8)) letterDesignator = 'P';
    else if (( 8 > latitude) && (latitude >= 0)) letterDesignator = 'N';
    else if (( 0 > latitude) && (latitude >= -8)) letterDesignator = 'M';
    else if ((-8> latitude) && (latitude >= -16)) letterDesignator = 'L';
    else if ((-16 > latitude) && (latitude >= -24)) letterDesignator = 'K';
    else if ((-24 > latitude) && (latitude >= -32)) letterDesignator = 'J';
    else if ((-32 > latitude) && (latitude >= -40)) letterDesignator = 'H';
    else if ((-40 > latitude) && (latitude >= -48)) letterDesignator = 'G';
    else if ((-48 > latitude) && (latitude >= -56)) letterDesignator = 'F';
    else if ((-56 > latitude) && (latitude >= -64)) letterDesignator = 'E';
    else if ((-64 > latitude) && (latitude >= -72)) letterDesignator = 'D';
    else if ((-72 > latitude) && (latitude >= -80)) letterDesignator = 'C';
    else letterDesignator = 'Z'; //This is here as an error flag to show that the Latitude is outside the UTM limits

    return [NSString stringWithFormat:@"%c", letterDesignator];
}

// Converts latitude/longitude to UTM coordinates.  Equations from USGS Bulletin 1532.
// East longitudes are positive, West longitudes are negative.
// North latitudes are positive, South latitudes are negative.
// Latitude and longitude are in decimal degrees.
// Written by Chuck Gantz - chuck.gantz@globalstar.com
+ (void)convertCoordinate:(CLLocationCoordinate2D)coordinate
          toUTMZoneNumber:(int *)utmZoneNumber
            utmZoneLetter:(NSString **)utmZoneLetter
     isNorthernHemisphere:(BOOL *)isNorthernHemisphere
                  easting:(double *)easting
                 northing:(double *)northing
{
    double a = 6378137.0;
    double eccSquared = 0.00669438;
    double k0 = 0.9996;

    double longitudeOrigin, longitudeOriginRad;
    double eccPrimeSquared;
    double N, T, C, A, M;

    // Make sure the longitude is between -180.00 .. 179.9
    double longitudeTemp = (coordinate.longitude + 180.0) - (floor((coordinate.longitude + 180.0) / 360.0) * 360.0) - 180.0;
    double latitudeRad = coordinate.latitude * deg2rad;
    double longitudeRad = longitudeTemp * deg2rad;

    *utmZoneNumber = floor((longitudeTemp + 180.0) / 6.0) + 1;

    if (coordinate.latitude >= 56.0 && coordinate.latitude < 64.0 && longitudeTemp >= 3.0 && longitudeTemp < 12.0)
        *utmZoneNumber = 32;

    // Special zones for Svalbard
    if (coordinate.latitude >= 72.0 && coordinate.latitude < 84.0)
    {
        if (longitudeTemp >= 0.0 && longitudeTemp < 9.0) *utmZoneNumber = 31;
        else if (longitudeTemp >= 9.0 && longitudeTemp < 21.0) *utmZoneNumber = 33;
        else if (longitudeTemp >= 21.0 && longitudeTemp < 33.0) *utmZoneNumber = 35;
        else if (longitudeTemp >= 33.0 && longitudeTemp < 42.0) *utmZoneNumber = 37;
    }

    longitudeOrigin = (*utmZoneNumber - 1) * 6 - 180 + 3;  //+3 puts origin in middle of zone
    longitudeOriginRad = longitudeOrigin * deg2rad;

    // Compute the UTM Zone from the latitude and longitude
    NSString *utmLetterDesignator = [self UTMLetterDesignatorForLatitude:coordinate.latitude];

    if (utmZoneLetter != NULL)
        *utmZoneLetter = utmLetterDesignator;

    if (isNorthernHemisphere != NULL)
    {
        char zoneLetterChar = [utmLetterDesignator UTF8String][0];
        *isNorthernHemisphere = (zoneLetterChar >= 'N' && zoneLetterChar <= 'X');
    }

    eccPrimeSquared = (eccSquared) / (1.0 - eccSquared);

    N = a / sqrt(1.0 - eccSquared * sin(latitudeRad) * sin(longitudeRad));
    T = tan(latitudeRad) * tan(latitudeRad);
    C = eccPrimeSquared * cos(latitudeRad) * cos(latitudeRad);
    A = cos(latitudeRad) * (longitudeRad - longitudeOriginRad);

    M = a * ((1.0 - eccSquared/4 - 3*eccSquared*eccSquared/64 - 5*eccSquared*eccSquared*eccSquared/256) * latitudeRad
             - (3*eccSquared/8 + 3*eccSquared*eccSquared/32 + 45*eccSquared*eccSquared*eccSquared/1024) * sin(2*latitudeRad)
             + (15*eccSquared*eccSquared/256 + 45*eccSquared*eccSquared*eccSquared/1024) * sin(4*latitudeRad)
             - (35*eccSquared*eccSquared*eccSquared/3072) * sin(6*latitudeRad));

    *easting = (double)(k0*N*(A+(1-T+C)*A*A*A/6 + (5 - 18*T+T*T + 72*C - 58*eccPrimeSquared)*A*A*A*A*A / 120) + 500000.0);

    *northing = (double)(k0 * (M + N*tan(latitudeRad) * (A*A/2 + (5 - T + 9*C + 4*C*C) * A*A*A*A/24 + (61 - 58*T + T*T + 600*C - 330*eccPrimeSquared) * A*A*A*A*A*A/720)));

    if (coordinate.latitude < 0)
        *northing += 10000000.0; //10000000 meter offset for southern hemisphere
}

// Converts UTM coords to latitude/longitude. Equations from USGS Bulletin 1532.
// East longitudes are positive, West longitudes are negative.
// North latitudes are positive, South latitudes are negative.
// Latitude and longitude are in decimal degrees.
// Written by Chuck Gantz - chuck.gantz@globalstar.com
+ (void)convertUTMZoneNumber:(int)utmZoneNumber
               utmZoneLetter:(NSString *)utmZoneLetter
        isNorthernHemisphere:(BOOL)isNorthernHemisphere
                     easting:(double)easting
                    northing:(double)northing
                toCoordinate:(CLLocationCoordinate2D *)coordinate
{
    double k0 = 0.9996;
    double a = 6378137.0;
    double eccSquared = 0.00669438;

    double eccPrimeSquared;
    double e1 = (1 - sqrt(1-eccSquared)) / (1 + sqrt(1-eccSquared));
    double N1, T1, C1, R1, D, M;
    double longitudeOrigin;
    double mu, phi1, phi1Rad;
    double x, y, latitude, longitude;

    x = easting - 500000.0; // remove 500,000 meter offset for longitude
    y = northing;

    if (utmZoneLetter != nil)
    {
        char zoneLetter = [utmZoneLetter UTF8String][0];
        if ((zoneLetter >= 'c' && zoneLetter <= 'm') || (zoneLetter >= 'C' && zoneLetter <= 'M'))
            y -= 10000000.0; // remove 10,000,000 meter offset used for southern hemisphere
    }
    else if ( ! isNorthernHemisphere)
    {
            y -= 10000000.0; // remove 10,000,000 meter offset used for southern hemisphere
    }

    longitudeOrigin = (utmZoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone

    eccPrimeSquared = (eccSquared) / (1-eccSquared);

    M = y / k0;
    mu = M / (a * (1 - eccSquared/4 - 3*eccSquared*eccSquared/64 - 5*eccSquared*eccSquared*eccSquared/256));

    phi1Rad = mu + (3*e1/2 - 27*e1*e1*e1/32) * sin(2*mu) + (21*e1*e1/16 - 55*e1*e1*e1*e1/32) * sin(4*mu) + (151*e1*e1*e1/96) * sin(6*mu);
    phi1 = phi1Rad * rad2deg;

    N1 = a / sqrt(1 - eccSquared*sin(phi1Rad)*sin(phi1Rad));
    T1 = tan(phi1Rad) * tan(phi1Rad);
    C1 = eccPrimeSquared * cos(phi1Rad) * cos(phi1Rad);
    R1 = a * (1 - eccSquared) / pow(1 - eccSquared*sin(phi1Rad)*sin(phi1Rad), 1.5);
    D = x / (N1 * k0);

    latitude = phi1Rad - (N1 * tan(phi1Rad) / R1) * (D*D/2 - (5 + 3*T1 + 10*C1 - 4*C1*C1 - 9*eccPrimeSquared) * D*D*D*D/24 + (61 + 90*T1 + 298*C1 + 45*T1*T1 - 252*eccPrimeSquared - 3*C1*C1) * D*D*D*D*D*D/720);
    latitude = latitude * rad2deg;

    longitude = (D - (1 + 2*T1+C1) * D*D*D/6 + (5 - 2*C1 + 28*T1 - 3*C1*C1 + 8*eccPrimeSquared + 24*T1*T1) * D*D*D*D*D/120) / cos(phi1Rad);
    longitude = longitudeOrigin + longitude * rad2deg;

    (*coordinate).latitude = latitude;
    (*coordinate).longitude = longitude;
}

@end
