//
//  ADClusterableAnnotation.m
//  ADClusterMapView
//
//  Created by Patrick Nollet on 27/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import "ADClusterableAnnotation.h"

@interface ADClusterableAnnotation () {
    NSString * _name;
}

@end

@implementation ADClusterableAnnotation
@synthesize coordinate = _coordinate;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _name = dictionary[@"name"];
        NSDictionary * coordinateDictionary = dictionary[@"coordinates"];
        self.coordinate = CLLocationCoordinate2DMake([coordinateDictionary[@"latitude"] doubleValue], [coordinateDictionary[@"longitude"] doubleValue]);
    }
    return self;
}

- (NSString *)title {
    return self.description;
}

- (NSString *)description {
    return _name;
}
@end
