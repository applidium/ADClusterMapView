//
//  ADMapCluster.h
//  ADClusterMapView
//
//  Created by Patrick Nollet on 27/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ADMapPointAnnotation.h"

@interface ADMapCluster : NSObject {
    CLLocationCoordinate2D _clusterCoordinate;
    ADMapCluster *         _leftChild;
    ADMapCluster *         _rightChild;
    MKMapRect              _mapRect;
    ADMapPointAnnotation * _annotation;
    NSString *             _clusterTitle;
    NSInteger              _depth;
}
@property (nonatomic) CLLocationCoordinate2D clusterCoordinate;
@property (nonatomic, readonly) NSString * title;
@property (nonatomic, readonly) NSString * subtitle;
@property (nonatomic, retain) ADMapPointAnnotation * annotation;
@property (nonatomic, readonly) NSMutableArray * originalAnnotations;
@property (nonatomic, readonly) NSInteger depth;
- (id)initWithAnnotations:(NSArray *)annotations atDepth:(NSInteger)depth inMapRect:(MKMapRect)mapRect gamma:(double)gamma clusterTitle:(NSString *)clusterTitle;
+ (ADMapCluster *)rootClusterForAnnotations:(NSArray *)annotations gamma:(double)gamma clusterTitle:(NSString *)clusterTitle;
- (NSArray *)find:(NSInteger)N childrenInMapRect:(MKMapRect)mapRect;
- (NSArray *)children;
- (BOOL)isAncestorOf:(ADMapCluster *)mapCluster;
- (BOOL)isRootClusterForAnnotation:(id<MKAnnotation>)annotation;
- (NSInteger)numberOfChildren;
- (NSArray *)namesOfChildren;
@end
