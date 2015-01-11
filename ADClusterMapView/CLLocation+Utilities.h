//
//  CLLocation+Equal.h
//  TapShield
//
//  Created by Adam Share on 7/13/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface CLLocation (Utilities)

BOOL CLLocationCoordinate2DIsApproxEqual(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2, float epsilon);

CLLocationCoordinate2D CLLocationCoordinate2DOffset(CLLocationCoordinate2D coord, double x, double y);

CLLocationCoordinate2D CLLocationCoordinate2DRoundedLonLat(CLLocationCoordinate2D coord, int decimalPlace);

BOOL MKMapRectSizeIsEqual(MKMapRect rect1, MKMapRect rect2);


@end
