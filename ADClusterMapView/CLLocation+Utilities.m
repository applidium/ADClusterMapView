//
//  CLLocation+Equal.m
//  TapShield
//
//  Created by Adam Share on 7/13/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import "CLLocation+Utilities.h"

@implementation CLLocation (Utilities)

BOOL CLLocationCoordinate2DIsApproxEqual(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2, float epsilon) {
    return (fabs(coord1.latitude - coord2.latitude) < epsilon &&
            fabs(coord1.longitude - coord2.longitude) < epsilon);
}

CLLocationCoordinate2D CLLocationCoordinate2DOffset(CLLocationCoordinate2D coord, double x, double y) {
    return CLLocationCoordinate2DMake(coord.latitude + y, coord.longitude + x);
}

float roundToN(float num, int decimals)
{
    int tenpow = 1;
    for (; decimals; tenpow *= 10, decimals--);
    return round(tenpow * num) / tenpow;
}

CLLocationCoordinate2D CLLocationCoordinate2DRoundedLonLat(CLLocationCoordinate2D coord, int decimalPlace) {
    double lat = roundToN(coord.latitude, decimalPlace);
    double lon = roundToN(coord.longitude, decimalPlace);
    return CLLocationCoordinate2DMake(lat, lon);
}

BOOL MKMapRectSizeIsEqual(MKMapRect rect1, MKMapRect rect2) {
    
    return (round(rect1.size.height) == round(rect2.size.height) &&
            round(rect1.size.width) == round(rect2.size.width));
}


@end
