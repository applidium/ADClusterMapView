//
//  ADMapCluster.h
//  ADClusterMapView
//
//  Created by Patrick Nollet on 27/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class ADMapPointAnnotation;

@interface ADMapCluster : NSObject
@property (nonatomic) CLLocationCoordinate2D clusterCoordinate;
@property (weak, nonatomic, readonly, nullable) NSString * title;
@property (weak, nonatomic, readonly, nullable) NSString * subtitle;
@property (nonatomic, strong, nullable) ADMapPointAnnotation * annotation;
@property (nonatomic, readonly, nonnull) NSMutableArray<id<MKAnnotation>> * originalAnnotations;
@property (nonatomic, readonly) NSInteger depth;
@property (nonatomic, assign) BOOL showSubtitle;

- (nonnull instancetype)initWithAnnotations:(nullable NSArray<ADMapPointAnnotation *> *)annotations
                                    atDepth:(NSInteger)depth
                                  inMapRect:(MKMapRect)mapRect
                                      gamma:(double)gamma
                               clusterTitle:(nullable NSString *)clusterTitle
                               showSubtitle:(BOOL)showSubtitle;
+ (nonnull ADMapCluster *)rootClusterForAnnotations:(nonnull NSArray<ADMapPointAnnotation *> *)annotations
                                              gamma:(double)gamma
                                       clusterTitle:(nullable NSString *)clusterTitle
                                       showSubtitle:(BOOL)showSubtitle;
- (nonnull NSArray<ADMapCluster *> *)find:(NSInteger)N
                        childrenInMapRect:(MKMapRect)mapRect;
- (nonnull NSArray<ADMapCluster *> *)children;
- (BOOL)isAncestorOf:(nonnull ADMapCluster *)mapCluster;
- (BOOL)isRootClusterForAnnotation:(nonnull id<MKAnnotation>)annotation;
- (NSInteger)numberOfChildren;
- (nonnull NSArray<NSString *> *)namesOfChildren;

@end
