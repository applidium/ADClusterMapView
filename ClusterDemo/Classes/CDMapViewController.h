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
@property (weak, readonly, nonatomic) NSString * seedFileName; // abstract
@property (weak, readonly, nonatomic) NSString * pictoName; // abstract
@property (weak, readonly, nonatomic) NSString * clusterPictoName; // abstract
@end
