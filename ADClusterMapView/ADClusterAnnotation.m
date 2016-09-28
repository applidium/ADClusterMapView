//
//  ADClusterAnnotation.m
//  AppLibrary
//
//  Created by Patrick Nollet on 01/07/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import "ADClusterAnnotation.h"
#import "ADMapCluster.h"

BOOL ADClusterCoordinate2DIsOffscreen(CLLocationCoordinate2D coord) {
    return (coord.latitude == kADCoordinate2DOffscreen.latitude && coord.longitude == kADCoordinate2DOffscreen.longitude);
}

@implementation ADClusterAnnotation
@synthesize cluster = _cluster;

- (nonnull instancetype)init {
    if (self = [super init]) {
        _cluster = nil;
        self.coordinate = kADCoordinate2DOffscreen;
        _type = ADClusterAnnotationTypeUnknown;
        _shouldBeRemovedAfterAnimation = NO;
    }
    return self;
}

- (void)setCluster:(nullable ADMapCluster *)cluster {
    [self willChangeValueForKey:@"title"];
    [self willChangeValueForKey:@"subtitle"];
    _cluster = cluster;
    [self didChangeValueForKey:@"subtitle"];
    [self didChangeValueForKey:@"title"];
}

- (nullable ADMapCluster *)cluster {
    return _cluster;
}

- (nullable NSString *)title {
    return self.cluster.title;
}

- (nullable NSString *)subtitle {
    return self.cluster.subtitle;
}

- (void)reset {
    self.cluster = nil;
    self.coordinate = kADCoordinate2DOffscreen;
}

- (nullable NSArray<id<MKAnnotation>> *)originalAnnotations {
    NSAssert(self.cluster != nil, @"This annotation should have a cluster assigned!");
    return self.cluster.originalAnnotations;
}
@end
