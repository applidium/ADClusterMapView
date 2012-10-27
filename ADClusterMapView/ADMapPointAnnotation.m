//
//  ADMapPointAnnotation.m
//  ClusterDemo
//
//  Created by Patrick Nollet on 11/10/12.
//  Copyright (c) 2012 Applidium. All rights reserved.
//

#import "ADMapPointAnnotation.h"

@implementation ADMapPointAnnotation
@synthesize mapPoint = _mapPoint;
@synthesize annotation = _annotation;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation {
    self = [super init];
    if (self) {
        _mapPoint = MKMapPointForCoordinate(annotation.coordinate);
        _annotation = [annotation retain];
    }
    return self;
}

- (void)dealloc {
    [_annotation release], _annotation = nil;
    [super dealloc];
}
@end
