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
@property (weak, nonatomic, readonly) NSString * title;
@property (weak, nonatomic, readonly) NSString * subtitle;
@property (nonatomic, strong) ADMapPointAnnotation * annotation;
@property (weak, nonatomic, readonly) NSMutableArray * originalAnnotations;
@property (nonatomic, readonly) NSInteger depth;
@property (nonatomic, assign) BOOL showSubtitle;
- (id)initWithAnnotations:(NSArray *)annotations atDepth:(NSInteger)depth inMapRect:(MKMapRect)mapRect gamma:(double)gamma clusterTitle:(NSString *)clusterTitle showSubtitle:(BOOL)showSubtitle;
+ (ADMapCluster *)rootClusterForAnnotations:(NSArray *)annotations gamma:(double)gamma clusterTitle:(NSString *)clusterTitle showSubtitle:(BOOL)showSubtitle;
- (NSArray *)find:(NSInteger)N childrenInMapRect:(MKMapRect)mapRect;
- (NSArray *)children;
- (BOOL)isAncestorOf:(ADMapCluster *)mapCluster;
- (BOOL)isRootClusterForAnnotation:(id<MKAnnotation>)annotation;
- (NSInteger)numberOfChildren;
- (NSArray *)namesOfChildren;
@end
