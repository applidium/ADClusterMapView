//
//  CDMapViewController.h
//  ClusterDemo
//
//  Created by Patrick Nollet on 09/10/12.
//  Copyright (c) 2012 Applidium. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ADClusterMapView.h"

@interface CDMapViewController : UIViewController <ADClusterMapViewDelegate>
@property (strong, nonatomic) IBOutlet ADClusterMapView * mapView;
@property (copy, readonly, nonatomic) NSString * seedFileName; // abstract
@property (copy, readonly, nonatomic) NSString * pictoName; // abstract
@property (copy, readonly, nonatomic) NSString * clusterPictoName; // abstract
@end
