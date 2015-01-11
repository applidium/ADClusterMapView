//
//  TSBaseAnnotationView.h
//  TapShield
//
//  Created by Adam Share on 4/2/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface TSClusertedAnnotationView : MKAnnotationView

@property (strong, nonatomic) UILabel *label;

- (void)refreshView;

@end
