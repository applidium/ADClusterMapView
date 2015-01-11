//
//  TSBaseAnnotationView.m
//  TapShield
//
//  Created by Adam Share on 4/2/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import "TSClusertedAnnotationView.h"

@implementation TSClusertedAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.accessibilityValue = @"";
        self.accessibilityLabel = @"Map Annotation";
    }
    return self;
    
}

- (void)refreshView {
    
    //
}

- (NSString *)accessibilityValue {
    
    return self.annotation.title;
}

@end
