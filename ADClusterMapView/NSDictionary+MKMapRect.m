//
//  NSDictionary+MKMapRect.m
//  TapShield
//
//  Created by Adam Share on 7/12/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import "NSDictionary+MKMapRect.h"

@implementation NSDictionary (MKMapRect)

+ (NSDictionary *)dictionaryFromMapRect:(MKMapRect)mapRect{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSNumber numberWithDouble:mapRect.origin.x] forKey:@"x"];
    [d setObject:[NSNumber numberWithDouble:mapRect.origin.y] forKey:@"y"];
    [d setObject:[NSNumber numberWithDouble:mapRect.size.width] forKey:@"width"];
    [d setObject:[NSNumber numberWithDouble:mapRect.size.height] forKey:@"height"];
    
    return d;
}

- (MKMapRect)mapRectForDictionary {
    
    return MKMapRectMake([[self objectForKey:@"x"] doubleValue],
                         [[self objectForKey:@"y"] doubleValue],
                         [[self objectForKey:@"width"] doubleValue],
                         [[self objectForKey:@"height"] doubleValue]);
}

@end
