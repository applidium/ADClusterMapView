//
//  NSDictionary+MKMapRect.h
//  TapShield
//
//  Created by Adam Share on 7/12/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NSDictionary (MKMapRect)

+ (NSDictionary *)dictionaryFromMapRect:(MKMapRect)mapRect;
- (MKMapRect)mapRectForDictionary;

@end
