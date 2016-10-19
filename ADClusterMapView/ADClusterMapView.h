//
//  ADClusterMapView.h
//  ADClusterMapView
//
//  Created by Patrick Nollet on 30/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class ADClusterAnnotation;
@class ADClusterMapView;

@protocol ADClusterMapViewDelegate <MKMapViewDelegate>
@optional
- (NSInteger)numberOfClustersInMapView:(nonnull ADClusterMapView *)mapView; // default: 32
- (nonnull MKAnnotationView *)mapView:(nonnull ADClusterMapView *)mapView viewForClusterAnnotation:(nonnull id <MKAnnotation>)annotation; // default: same as returned by mapView:viewForAnnotation:
- (BOOL)shouldShowSubtitleForClusterAnnotationsInMapView:(nonnull ADClusterMapView *)mapView; // default: YES
- (double)clusterDiscriminationPowerForMapView:(nonnull ADClusterMapView *)mapView; // This parameter emphasize the discrimination of annotations which are far away from the center of mass. default: 1.0 (no discrimination applied)
- (nullable NSString *)clusterTitleForMapView:(nonnull ADClusterMapView *)mapView; // default : @"%d elements"
- (void)clusterAnimationDidStopForMapView:(nonnull ADClusterMapView *)mapView;
- (void)mapViewDidFinishClustering:(nonnull ADClusterMapView *)mapView;
@end

@interface ADClusterMapView : MKMapView <MKMapViewDelegate>
@property (nonatomic, readonly, nonnull) NSArray<id<MKAnnotation>> * displayedAnnotations;
@property (nonatomic, readonly, nonnull) NSArray<ADClusterAnnotation *> * displayedClusterAnnotations;

- (void)addAnnotation:(nonnull id<MKAnnotation>)annotation NS_UNAVAILABLE;
- (void)addAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations NS_UNAVAILABLE;
- (nullable ADClusterAnnotation *)clusterAnnotationForOriginalAnnotation:(nonnull id<MKAnnotation>)annotation; // returns the ADClusterAnnotation instance containing the annotation originally added.
- (void)selectClusterAnnotation:(nonnull ADClusterAnnotation *)annotation animated:(BOOL)animated;
- (void)setAnnotations:(nullable NSArray<id<MKAnnotation>> *)annotations; // entry point for the annotations that you want to cluster
- (void)addNonClusteredAnnotation:(nonnull id<MKAnnotation>)annotation;
- (void)addNonClusteredAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations;
- (void)removeNonClusteredAnnotation:(nonnull id<MKAnnotation>)annotation;
- (void)removeNonClusteredAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations;
@end
