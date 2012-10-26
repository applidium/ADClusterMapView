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
        _name = [[dictionary objectForKey:@"name"] retain];
        NSDictionary * coordinateDictionary = [dictionary objectForKey:@"coordinates"];
        self.coordinate = CLLocationCoordinate2DMake([[coordinateDictionary objectForKey:@"latitude"] doubleValue], [[coordinateDictionary objectForKey:@"longitude"] doubleValue]);
    }
    return self;
}

- (void)dealloc {
    [_name release], _name = nil;
    [super dealloc];
}

- (NSString *)title {
    return self.description;
}

- (NSString *)description {
    return _name;
}
@end
