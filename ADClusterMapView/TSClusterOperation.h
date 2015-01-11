//
//  TSClusterOperation.h
//  TapShield
//
//  Created by Adam Share on 7/14/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADClusterMapView.h"

typedef void(^ClusterOperationCompletionBlock)(ADClusterMapView *mapView);

@interface TSClusterOperation : NSOperation

@property (nonatomic, copy) ClusterOperationCompletionBlock finishedBlock;

- (instancetype)initWithMapView:(ADClusterMapView *)mapView rootCluster:(ADMapCluster *)rootCluster completion:(ClusterOperationCompletionBlock)completion;

@end
