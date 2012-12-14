//
//  ADMapCluster.m
//  ADClusterMapView
//
//  Created by Patrick Nollet on 27/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import "ADMapCluster.h"
#import "ADMapPointAnnotation.h"

#define ADMapClusterDiscriminationPrecision 1E-4

@interface ADMapCluster (Private)
- (MKMapRect)_mapRect;
- (void)_cleanClusters:(NSMutableArray *)clusters fromAncestorsOfClusters:(NSArray *)referenceClusters;
- (void)_cleanClusters:(NSMutableArray *)clusters outsideMapRect:(MKMapRect)mapRect;
@end

@implementation ADMapCluster
@synthesize clusterCoordinate = _clusterCoordinate;
@synthesize annotation = _annotation;
@synthesize depth = _depth;

- (id)initWithAnnotations:(NSArray *)annotations atDepth:(NSInteger)depth inMapRect:(MKMapRect)mapRect gamma:(double)gamma clusterTitle:(NSString *)clusterTitle {
    self = [super init];
    if (self) {
        _depth = depth;
        _mapRect = mapRect;
        _clusterTitle = [clusterTitle retain];
        if (annotations.count == 0) {
            _leftChild = nil;
            _rightChild = nil;
            self.annotation = nil;
            self.clusterCoordinate = kCLLocationCoordinate2DInvalid;
        } else if (annotations.count == 1) {
            _leftChild = nil;
            _rightChild = nil;
            self.annotation = [annotations lastObject];
            self.clusterCoordinate = self.annotation.annotation.coordinate;
        } else {
            self.annotation = nil;
            
            // Principal Component Analysis
            // If cov(x,y) = ∑(x-x_mean) * (y-y_mean) != 0 (covariance different from zero), we are looking for the following principal vector:
            // a (aX)
            //   (aY)
            //
            // x_ = x - x_mean ; y_ = y - y_mean
            //
            // aX = cov(x_,y_)
            // 
            //
            // aY = 0.5/n * ( ∑(x_^2) + ∑(y_^2) + sqrt( (∑(x_^2) + ∑(y_^2))^2 + 4 * cov(x_,y_)^2 ) ) 
            
            // compute the means of the coordinate
            double XSum = 0.0;
            double YSum = 0.0;
            for (ADMapPointAnnotation * annotation in annotations) {
                XSum += annotation.mapPoint.x;
                YSum += annotation.mapPoint.y;
            }
            double XMean = XSum / (double)annotations.count;
            double YMean = YSum / (double)annotations.count;
            
            if (gamma != 1.0) {
                // take gamma weight into account
                double gammaSumX = 0.0;
                double gammaSumY = 0.0;
                
                double maxDistance = 0.0;
                MKMapPoint meanCenter = MKMapPointMake(XMean, YMean);
                for (ADMapPointAnnotation * annotation in annotations) {
                    const double distance = MKMetersBetweenMapPoints(annotation.mapPoint, meanCenter);
                    if (distance > maxDistance) {
                        maxDistance = distance;
                    }
                }
                
                double totalWeight = 0.0;
                for (ADMapPointAnnotation * annotation in annotations) {
                    const MKMapPoint point = annotation.mapPoint;
                    const double distance = MKMetersBetweenMapPoints(point, meanCenter);
                    const double normalizedDistance = maxDistance != 0.0 ? distance/maxDistance : 1.0;
                    const double weight = pow(normalizedDistance, gamma-1.0);
                    gammaSumX += point.x * weight;
                    gammaSumY += point.y * weight;
                    totalWeight += weight;
                }
                XMean = gammaSumX/totalWeight;
                YMean = gammaSumY/totalWeight;
            }
            // compute coefficients
            
            double sumXsquared = 0.0;
            double sumYsquared = 0.0;
            double sumXY = 0.0;

            for (ADMapPointAnnotation * annotation in annotations) {
                double x = annotation.mapPoint.x - XMean;
                double y = annotation.mapPoint.y - YMean;
                sumXsquared += x * x;
                sumYsquared += y * y;
                sumXY += x * y;
            }
            
            double aX = 0.0;
            double aY = 0.0;
            
            if (fabs(sumXY)/annotations.count > ADMapClusterDiscriminationPrecision) {
                aX = sumXY;
                double lambda = 0.5 * ((sumXsquared + sumYsquared) + sqrt((sumXsquared + sumYsquared) * (sumXsquared + sumYsquared) + 4 * sumXY * sumXY));
                aY = lambda - sumXsquared;
            } else {
                aX = sumXsquared > sumYsquared ? 1.0 : 0.0;
                aY = sumXsquared > sumYsquared ? 0.0 : 1.0;
            }
            
            NSArray * leftAnnotations = nil;
            NSArray * rightAnnotations = nil;
            
            if (fabs(sumXsquared)/annotations.count < ADMapClusterDiscriminationPrecision || fabs(sumYsquared)/annotations.count < ADMapClusterDiscriminationPrecision) { // all X and Y are the same => same coordinates
                // then every x equals XMean and we have to arbitrarily choose where to put the pivotIndex
                NSInteger pivotIndex = annotations.count /2 ;
                leftAnnotations = [[annotations subarrayWithRange:NSMakeRange(0, pivotIndex)] retain];
                rightAnnotations = [[annotations subarrayWithRange:NSMakeRange(pivotIndex, annotations.count-pivotIndex)] retain];
            } else {
                // compute scalar product between the vector of this regression line and the vector
                // (x - x(mean))
                // (y - y(mean))
                // the sign of this scalar product determines which cluster the point belongs to
                leftAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
                rightAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
                for (ADMapPointAnnotation * annotation in annotations) {
                    const MKMapPoint point = annotation.mapPoint;
                    BOOL positivityConditionOfScalarProduct = YES;
                    if (YES) {
                        positivityConditionOfScalarProduct = (point.x - XMean) * aX + (point.y - YMean) * aY > 0.0;
                    } else {
                        positivityConditionOfScalarProduct = (point.y - YMean) > 0.0;
                    }
                    if (positivityConditionOfScalarProduct) {
                        [(NSMutableArray *)leftAnnotations addObject:annotation];
                    } else {
                        [(NSMutableArray *)rightAnnotations addObject:annotation];
                    }
                }
            }
            
            MKMapRect leftMapRect = MKMapRectNull;
            MKMapRect rightMapRect = MKMapRectNull;
            
            // compute map rects
            double XMin = MAXFLOAT, XMax = 0.0, YMin = MAXFLOAT, YMax = 0.0;
            for (ADMapPointAnnotation * annotation in leftAnnotations) {
                const MKMapPoint point = annotation.mapPoint;
                if (point.x > XMax) {
                    XMax = point.x;
                }
                if (point.y > YMax) {
                    YMax = point.y;
                }
                if (point.x < XMin) {
                    XMin = point.x;
                }
                if (point.y < YMin) {
                    YMin = point.y;
                }
            }
            leftMapRect = MKMapRectMake(XMin, YMin, XMax - XMin, YMax - YMin);
            
            XMin = MAXFLOAT, XMax = 0.0, YMin = MAXFLOAT, YMax = 0.0;
            for (ADMapPointAnnotation * annotation in rightAnnotations) {
                const MKMapPoint point = annotation.mapPoint;
                if (point.x > XMax) {
                    XMax = point.x;
                }
                if (point.y > YMax) {
                    YMax = point.y;
                }
                if (point.x < XMin) {
                    XMin = point.x;
                }
                if (point.y < YMin) {
                    YMin = point.y;
                }
            }
            rightMapRect = MKMapRectMake(XMin, YMin, XMax - XMin, YMax - YMin);
            
            _clusterCoordinate = MKCoordinateForMapPoint(MKMapPointMake(XMean, YMean));
            
            _leftChild = [[ADMapCluster alloc] initWithAnnotations:leftAnnotations atDepth:depth+1 inMapRect:leftMapRect gamma:gamma clusterTitle:clusterTitle];
            _rightChild = [[ADMapCluster alloc] initWithAnnotations:rightAnnotations atDepth:depth+1 inMapRect:rightMapRect gamma:gamma clusterTitle:clusterTitle];
            
            [leftAnnotations release];
            [rightAnnotations release];
        }
    }
    return self;
}

- (void)dealloc {
    [_leftChild release], _leftChild = nil;
    [_rightChild release], _rightChild = nil;
    [_annotation release], _annotation = nil;
    [_clusterTitle release], _clusterTitle = nil;
    [super dealloc];
}

+ (ADMapCluster *)rootClusterForAnnotations:(NSArray *)initialAnnotations gamma:(double)gamma clusterTitle:(NSString *)clusterTitle {
    // KDTree
    
    MKMapRect boundaries = MKMapRectWorld;
    
    // This is optional
    boundaries = MKMapRectMake(HUGE_VALF, HUGE_VALF, 0.0, 0.0);
    for (ADMapPointAnnotation * annotation in initialAnnotations) {
        MKMapPoint point = annotation.mapPoint;
        if (point.x < boundaries.origin.x) {
            boundaries.origin.x = point.x;
        }
        if (point.y < boundaries.origin.y) {
            boundaries.origin.y = point.y;
        }
        if (point.x > boundaries.origin.x + boundaries.size.width) {
            boundaries.size.width = point.x - boundaries.origin.x;
        }
        if (point.y > boundaries.origin.y + boundaries.size.height) {
            boundaries.size.height = point.y - boundaries.origin.y;
        }
    }
    
    NSLog(@"Computing KD-tree...");
    ADMapCluster * cluster = [[ADMapCluster alloc] initWithAnnotations:initialAnnotations atDepth:0 inMapRect:boundaries gamma:gamma clusterTitle:clusterTitle];
    NSLog(@"Computation done !");
    return [cluster autorelease];
}

- (NSArray *)find:(NSInteger)N childrenInMapRect:(MKMapRect)mapRect {
    // Start from the root (self)
    // Adopt a breadth-first search strategy
    // If MapRect intersects the bounds, then keep this element for next iteration
    // Stop if there are N elements or more
    // Or if the bottom of the tree was reached (d'oh!)    
    NSMutableArray * clusters = [[NSMutableArray alloc] initWithObjects:self, nil];
    NSMutableArray * annotations = [[NSMutableArray alloc] init];
    NSMutableArray * previousLevelClusters = nil;
    NSMutableArray * previousLevelAnnotations = nil;
    BOOL clustersDidChange = YES; // prevents infinite loop at the bottom of the tree
    while (clusters.count + annotations.count < N && clusters.count > 0 && clustersDidChange) {
        [previousLevelAnnotations release];
        previousLevelAnnotations = [annotations mutableCopy];
        [previousLevelClusters release];
        previousLevelClusters = [clusters mutableCopy];
        
        clustersDidChange = NO;
        NSMutableArray * nextLevelClusters = [[NSMutableArray alloc] init];
        for (ADMapCluster * cluster in clusters) {
            for (ADMapCluster * child in [cluster children]) {
                if (child.annotation) {
                    [annotations addObject:child];
                } else {
                    if (MKMapRectIntersectsRect(mapRect, [child _mapRect])) {
                        [nextLevelClusters addObject:child];
                    }
                }
            }
        }  
        if (nextLevelClusters.count > 0) {
            [clusters release];
            clusters = [nextLevelClusters retain];
            clustersDidChange = YES;
        }
        [nextLevelClusters release];
    }
    [self _cleanClusters:clusters fromAncestorsOfClusters:annotations];
    
    if (clusters.count + annotations.count > N) { // if there are too many clusters and annotations, that means that we went one level too far in depth
        [clusters release];
        clusters = [previousLevelClusters retain];
        [annotations release];
        annotations = [previousLevelAnnotations retain];
        [self _cleanClusters:clusters fromAncestorsOfClusters:annotations];
    }
    [previousLevelClusters release];
    [previousLevelAnnotations release];
    [self _cleanClusters:clusters outsideMapRect:mapRect];
    [annotations addObjectsFromArray:clusters];
    [clusters release];
    
    return [annotations autorelease];
}

- (NSArray *)children {
    NSMutableArray * children = [[NSMutableArray alloc] initWithCapacity:2];
    if (_leftChild != nil) {
        [children addObject:_leftChild];
    }
    if (_rightChild != nil) {
        [children addObject:_rightChild];
    }
    return [children autorelease];
}

- (BOOL)isAncestorOf:(ADMapCluster *)mapCluster {
    return _depth < mapCluster.depth && (_leftChild == mapCluster || _rightChild == mapCluster || [_leftChild isAncestorOf:mapCluster] || [_rightChild isAncestorOf:mapCluster]);
}

- (BOOL)isRootClusterForAnnotation:(id<MKAnnotation>)annotation {
    return _annotation.annotation == annotation || [_leftChild isRootClusterForAnnotation:annotation] || [_rightChild isRootClusterForAnnotation:annotation];
}

- (NSString *)title {
    if (!self.annotation) {
        return [NSString stringWithFormat:_clusterTitle, [self numberOfChildren]];
    } else {
        if ([self.annotation.annotation respondsToSelector:@selector(title)]) {
            return self.annotation.annotation.title;
        } else {
            return nil;
        }
    }
}

- (NSString *)subtitle {
    if (!self.annotation) {
        return [[self namesOfChildren] componentsJoinedByString:@", "];
    } else {
        if ([self.annotation.annotation respondsToSelector:@selector(subtitle)]) {
            return self.annotation.annotation.subtitle;
        } else {
            return nil;
        }
    }
}

- (NSInteger)numberOfChildren {
    if (_leftChild == nil && _rightChild == nil) {
        return 1;
    } else {
        return [_leftChild numberOfChildren] + [_rightChild numberOfChildren];
    }
}

- (NSArray *)namesOfChildren {
    if (self.annotation) {
        return [NSArray arrayWithObject:self.annotation.annotation.title];
    } else {
        NSMutableArray * names = [NSMutableArray arrayWithArray:[_leftChild namesOfChildren]];
        [names addObjectsFromArray:[_rightChild namesOfChildren]];
        return names;
    }
}

- (NSString *)description {
    return [self title];
}

- (NSMutableArray *)originalAnnotations {
    NSMutableArray * originalAnnotations = nil;
    if (self.annotation) {
        originalAnnotations = [[NSMutableArray alloc] init];
        [originalAnnotations addObject:self.annotation];
    } else {
        originalAnnotations = [_leftChild.originalAnnotations retain];
        [originalAnnotations addObjectsFromArray:_rightChild.originalAnnotations];
    }
    return [originalAnnotations autorelease];
}
@end

@implementation ADMapCluster (Private)

- (MKMapRect)_mapRect {
    return _mapRect;
}

- (void)_cleanClusters:(NSMutableArray *)clusters fromAncestorsOfClusters:(NSArray *)referenceClusters {
    NSMutableArray * clustersToRemove = [[NSMutableArray alloc] init];
    for (ADMapCluster * cluster in clusters) {
        for (ADMapCluster * referenceCluster in referenceClusters) {
            if ([cluster isAncestorOf:referenceCluster]) {
                [clustersToRemove addObject:cluster];
                break;
            }
        }
    }
    [clusters removeObjectsInArray:clustersToRemove];
    [clustersToRemove release];
}
- (void)_cleanClusters:(NSMutableArray *)clusters outsideMapRect:(MKMapRect)mapRect {
    NSMutableArray * clustersToRemove = [[NSMutableArray alloc] init];
    for (ADMapCluster * cluster in clusters) {
        if (!MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(cluster.clusterCoordinate))) {
            [clustersToRemove addObject:cluster];
        }
    }
    [clusters removeObjectsInArray:clustersToRemove];
    [clustersToRemove release];
}
@end