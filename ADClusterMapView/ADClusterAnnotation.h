//
//  ADClusterAnnotation.h
//  AppLibrary
//
//  Created by Patrick Nollet on 01/07/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ADMapCluster.h"

#define kADCoordinate2DOffscreen CLLocationCoordinate2DMake(85.0, 179.0) // this coordinate puts the annotation on the top right corner of the map. We use this instead of kCLLocationCoordinate2DInvalid so that we don't mess with MapKit's KVO weird behaviour that removes from the map the annotations whose coordinate was set to kCLLocationCoordinate2DInvalid.

BOOL ADClusterCoordinate2DIsOffscreen(CLLocationCoordinate2D coord);

typedef enum {
    ADClusterAnnotationTypeUnknown = 0,
    ADClusterAnnotationTypeLeaf = 1,
    ADClusterAnnotationTypeCluster = 2
} ADClusterAnnotationType;

@interface ADClusterAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D  _coordinate;
    ADClusterAnnotationType _type;
    ADMapCluster *          _cluster;
    BOOL                    _shouldBeRemovedAfterAnimation;
}
@property (nonatomic) ADClusterAnnotationType type;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) ADMapCluster * cluster;
@property (nonatomic) BOOL shouldBeRemovedAfterAnimation;
@property (nonatomic, readonly) NSArray * originalAnnotations; // this array contains the annotations contained by the cluster of this annotation

- (void)reset;

@end
