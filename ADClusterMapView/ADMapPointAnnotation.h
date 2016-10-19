//
//  ADMapPointAnnotation.h
//  ClusterDemo
//
//  Created by Patrick Nollet on 11/10/12.
//  Copyright (c) 2012 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@interface ADMapPointAnnotation : NSObject
@property (nonatomic, readonly) MKMapPoint mapPoint;
@property (nonatomic, readonly, nonnull) id<MKAnnotation> annotation;
- (nonnull instancetype)initWithAnnotation:(nonnull id<MKAnnotation>)annotation;
@end
