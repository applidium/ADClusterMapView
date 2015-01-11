//
//  TSClusterOperation.m
//  TapShield
//
//  Created by Adam Share on 7/14/14.
//  Copyright (c) 2014 TapShield, LLC. All rights reserved.
//

#import "TSClusterOperation.h"
#import <MapKit/MapKit.h>
#import "ADMapCluster.h"
#import "ADClusterAnnotation.h"
#import "ADMapPointAnnotation.h"
#import "NSDictionary+MKMapRect.h"
#import "CLLocation+Utilities.h"
#import "ADClusterMapView.h"

@interface TSClusterOperation ()

@property (weak, nonatomic) ADClusterMapView *mapView;
@property (strong, nonatomic) ADMapCluster *rootMapCluster;

@end

@implementation TSClusterOperation

- (instancetype)initWithMapView:(ADClusterMapView *)mapView rootCluster:(ADMapCluster *)rootCluster completion:(ClusterOperationCompletionBlock)completion
{
    self = [super init];
    if (self) {
        self.mapView = mapView;
        self.rootMapCluster = rootCluster;
        self.finishedBlock = completion;
    }
    return self;
}

- (void)main {
    // a lengthy operation
    @autoreleasepool {
        
        [self _clusterInMapRect];
    }
}

int nearestEvenInt(int to) {
    return (to % 2 == 0) ? to : (to + 1);
}

- (void)_clusterInMapRect {
    
    NSLog(@"Begin Clustering");
    
    //Create buffer room for map drag outside visible rect before next regionDidChange
    MKMapRect rect = [self visibleMapRectWithBuffer];
    
    NSUInteger numberOnScreen;
    
    if (_mapView.region.span.longitudeDelta > .005) {
        //create grid to estimate number of clusters needed based on the spread of annotations across map rect
        NSSet *mapRects = [self mapRectsFromNumberOfClustersAcross:15 mapRect:rect];
        
        //number of map rects that contain at least one annotation
        numberOnScreen = [_rootMapCluster numberOfMapRectsContainingChildren:mapRects];
        numberOnScreen = numberOnScreen * _mapView.numberOfClusters/mapRects.count;
        numberOnScreen = nearestEvenInt((int)numberOnScreen);
        
        if (_mapView.region.span.longitudeDelta < .1) {
            //if we are at a small enough span lets take into account and not over cluster
            if (numberOnScreen < _mapView.numberOfClusters/9) {
                numberOnScreen = _mapView.numberOfClusters/9;
            }
        }
    }
    else {
        //Really close lets just show as many single annotations as we can
        numberOnScreen = _mapView.numberOfClusters;
    }
    if (self.isCancelled) {
        return;
    }
    
    NSSet *clustersToShowOnMap = [_rootMapCluster find:numberOnScreen childrenInMapRect:rect];//[_rootMapCluster find:[self _numberOfClusters] childrenInMapRect:rect];
    
    // Build an array with available annotations (eg. not moving or not staying at the same place on the map)
    NSMutableSet * availableSingleAnnotations = [[NSMutableSet alloc] init];
    NSMutableSet * availableClusterAnnotations = [[NSMutableSet alloc] init];
    NSMutableSet * selfDividingSingleAnnotations = [[NSMutableSet alloc] init];
    NSMutableSet * selfDividingClusterAnnotations = [[NSMutableSet alloc] init];
    for (ADClusterAnnotation * annotation in _mapView.clusterAnnotations) {
        BOOL isAncestor = NO;
        if (annotation.cluster) { // if there is a cluster associated to the current annotation
            for (ADMapCluster * cluster in clustersToShowOnMap) { // is the current annotation cluster an ancestor of one of the clustersToShowOnMap?
                if ([annotation.cluster isAncestorOf:cluster]) {
                    if (cluster.annotation) {
                        [selfDividingSingleAnnotations addObject:annotation];
                    } else {
                        [selfDividingClusterAnnotations addObject:annotation];
                    }
                    isAncestor = YES;
                    break;
                }
            }
        }
        if (!isAncestor) { // if not an ancestor
            if (![self _annotation:annotation belongsToClusters:clustersToShowOnMap]) { // check if this annotation will be used later. If not, it is flagged as "available".
                if (annotation.type == ADClusterAnnotationTypeLeaf) {
                    [availableSingleAnnotations addObject:annotation];
                } else {
                    [availableClusterAnnotations addObject:annotation];
                }
            }
        }
    }
    
    if (self.isCancelled) {
        return;
    }
    
    static NSString *coordinatesKey = @"coordinates";
    static NSString *annotationKey = @"annotation";
    static NSString *clusterKey = @"cluster";
    NSMutableArray *nonAnimated = [[NSMutableArray alloc] init];
    NSMutableArray *afterAnimation = [[NSMutableArray alloc] init];
    
    // Let ancestor annotations divide themselves
    for (ADClusterAnnotation * annotation in [selfDividingSingleAnnotations setByAddingObjectsFromSet:selfDividingClusterAnnotations]) {
        BOOL willNeedAnAvailableAnnotation = NO;
        CLLocationCoordinate2D originalAnnotationCoordinate = annotation.coordinate;
        ADMapCluster * originalAnnotationCluster = annotation.cluster;
        for (ADMapCluster * cluster in clustersToShowOnMap) {
            if ([originalAnnotationCluster isAncestorOf:cluster]) {
                if (!willNeedAnAvailableAnnotation) {
                    willNeedAnAvailableAnnotation = YES;
                    annotation.cluster = cluster;
                    if (cluster.annotation) { // replace this annotation by a leaf one
                        NSAssert(annotation.type != ADClusterAnnotationTypeLeaf, @"Inconsistent annotation type!");
                        ADClusterAnnotation * singleAnnotation = [availableSingleAnnotations anyObject];
                        [availableSingleAnnotations removeObject:singleAnnotation];
                        singleAnnotation.cluster = annotation.cluster;
                        [nonAnimated addObject:@{annotationKey: singleAnnotation, coordinatesKey: [NSValue valueWithMKCoordinate:originalAnnotationCoordinate]}];
                        
                        [availableClusterAnnotations addObject:annotation];
                    }
                } else {
                    ADClusterAnnotation * availableAnnotation = nil;
                    if (cluster.annotation) {
                        availableAnnotation = [availableSingleAnnotations anyObject];
                        [availableSingleAnnotations removeObject:availableAnnotation];
                    } else {
                        availableAnnotation = [availableClusterAnnotations anyObject];
                        [availableClusterAnnotations removeObject:availableAnnotation];
                    }
                    availableAnnotation.cluster = cluster;
                    [nonAnimated addObject:@{annotationKey: availableAnnotation, coordinatesKey: [NSValue valueWithMKCoordinate:originalAnnotationCoordinate]}];
                }
            }
        }
    }
    
    if (self.isCancelled) {
        return;
    }
    
    // Converge annotations to ancestor clusters
    for (ADMapCluster * cluster in clustersToShowOnMap) {
        BOOL didAlreadyFindAChild = NO;
        for (__strong ADClusterAnnotation * annotation in _mapView.clusterAnnotations) {
            if (![annotation isKindOfClass:[MKUserLocation class]]) {
                if (annotation.cluster && ![annotation isKindOfClass:[MKUserLocation class]]) {
                    if ([cluster isAncestorOf:annotation.cluster]) {
                        if (annotation.type == ADClusterAnnotationTypeLeaf) { // replace this annotation by a cluster one
                            ADClusterAnnotation * clusterAnnotation = [availableClusterAnnotations anyObject];
                            [availableClusterAnnotations removeObject:clusterAnnotation];
                            clusterAnnotation.cluster = cluster;
                            // Setting the coordinate makes us call viewForAnnotation: right away, so make sure the cluster is set

                            [nonAnimated addObject:@{annotationKey: clusterAnnotation, coordinatesKey: [NSValue valueWithMKCoordinate:annotation.coordinate]}];
                            [availableSingleAnnotations addObject:annotation];
                            annotation = clusterAnnotation;
                        } else {
                            annotation.cluster = cluster;
                        }
                        if (didAlreadyFindAChild) {
                            annotation.shouldBeRemovedAfterAnimation = YES;
                        }
                        if (ADClusterCoordinate2DIsOffscreen(annotation.coordinate)) {
                            [nonAnimated addObject:@{annotationKey: annotation, coordinatesKey: [NSValue valueWithMKCoordinate:annotation.cluster.clusterCoordinate]}];
                        }
                        didAlreadyFindAChild = YES;
                    }
                }
            }
        }
    }
    if (self.isCancelled) {
        return;
    }
    for (ADClusterAnnotation * annotation in availableSingleAnnotations) {
        NSAssert(annotation.type == ADClusterAnnotationTypeLeaf, @"Inconsistent annotation type!");
        if (annotation.cluster) { // This is here for performance reason (annotation reset causes the refresh of the annotation because of KVO)
            [nonAnimated addObject:@{annotationKey: annotation}];
        }
    }
    if (self.isCancelled) {
        return;
    }
    for (ADClusterAnnotation * annotation in availableClusterAnnotations) {
        NSAssert(annotation.type == ADClusterAnnotationTypeCluster, @"Inconsistent annotation type!");
        if (annotation.cluster) {
            [nonAnimated addObject:@{annotationKey: annotation}];
        }
    }
    if (self.isCancelled) {
        return;
    }
    
    [TSClusterOperation mutateCoordinatesOfClashingAnnotations:_mapView.clusterAnnotations];
    if (self.isCancelled) {
        return;
    }
    
    // Add not-yet-annotated clusters
    for (ADMapCluster * cluster in clustersToShowOnMap) {
        BOOL isAlreadyAnnotated = NO;
        for (ADClusterAnnotation * annotation in _mapView.clusterAnnotations) {
            if (![annotation isKindOfClass:[MKUserLocation class]]) {
                if ([cluster isEqual:annotation.cluster]) {
                    isAlreadyAnnotated = YES;
                    break;
                }
            }
        }
        if (!isAlreadyAnnotated) {
            if (cluster.annotation) {
                    ADClusterAnnotation * annotation = [availableSingleAnnotations anyObject];
                    [availableSingleAnnotations removeObject:annotation]; // update the availableAnnotations
                [afterAnimation addObject:@{annotationKey: annotation,
                                           clusterKey: cluster,
                                           coordinatesKey: [NSValue valueWithMKCoordinate:cluster.clusterCoordinate]}];
            } else {
                    ADClusterAnnotation * annotation = [availableClusterAnnotations anyObject];
//                    annotation.cluster = cluster; // the order here is important: because of KVO, the cluster property must be set before the coordinate property (change of coordinate -> refresh of the view -> refresh of the title -> the cluster can't be nil)
                    [availableClusterAnnotations removeObject:annotation]; // update the availableAnnotations
                
                [afterAnimation addObject:@{annotationKey: annotation,
                                           clusterKey: cluster,
                                           coordinatesKey: [NSValue valueWithMKCoordinate:cluster.clusterCoordinate]}];
            }
        }
    }
    
    if (self.isCancelled) {
        return;
    }
    
        for (ADClusterAnnotation * annotation in availableSingleAnnotations) {
            NSAssert(annotation.type == ADClusterAnnotationTypeLeaf, @"Inconsistent annotation type!");
            [afterAnimation addObject:@{annotationKey: annotation}];
        }
    
    if (self.isCancelled) {
        return;
    }
        for (ADClusterAnnotation * annotation in availableClusterAnnotations) {
            NSAssert(annotation.type == ADClusterAnnotationTypeCluster, @"Inconsistent annotation type!");
            [afterAnimation addObject:@{annotationKey: annotation}];
        }
    
    if (self.isCancelled) {
        return;
    }
    
    NSLog(@"Finished Clustering");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Animating");
        
        if (self.isCancelled) {
            NSLog(@"Animation cancelled");
            return;
        }
        
        for (NSDictionary *dic in nonAnimated) {
            ADClusterAnnotation * annotation = [dic objectForKey:annotationKey];
            if ([dic objectForKey:coordinatesKey]) {
                annotation.coordinate = [[dic objectForKey:coordinatesKey] MKCoordinateValue];
            }
            else {
                [annotation reset];
            }
        }
        
        [UIView beginAnimations:@"ADClusterMapViewAnimation" context:NULL];
        [UIView setAnimationBeginsFromCurrentState:NO];
        [UIView setAnimationDelegate:_mapView];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3f];
        for (ADClusterAnnotation * annotation in _mapView.clusterAnnotations) {
            if (![annotation isKindOfClass:[MKUserLocation class]] && annotation.cluster) {
                annotation.coordinate = annotation.cluster.clusterCoordinate;
            }
        }
        [UIView commitAnimations];
        
        NSLog(@"Adjust after setting animated annotations");
        for (NSDictionary *dic in afterAnimation) {
            ADClusterAnnotation * annotation = [dic objectForKey:annotationKey];
            if ([dic objectForKey:coordinatesKey]) {
                annotation.cluster = [dic objectForKey:clusterKey];
                annotation.coordinate = [[dic objectForKey:coordinatesKey] MKCoordinateValue];
            }
            else {
                [annotation reset];
            }
        }
        
        NSLog(@"Refreshing Annotation Views");
        for (ADClusterAnnotation * annotation in _mapView.clusterAnnotations) {
            if (![annotation isKindOfClass:[MKUserLocation class]] && annotation.cluster) {
                [annotation.annotationView refreshView];
            }
        }
        
        NSLog(@"Finished mainqueue");
        
        if (_finishedBlock) {
            _finishedBlock(nil);
        }
    });
}

- (BOOL)_annotation:(ADClusterAnnotation *)annotation belongsToClusters:(NSSet *)clusters {
    if (annotation.cluster) {
        for (ADMapCluster * cluster in clusters) {
            if ([cluster isAncestorOf:annotation.cluster] || [cluster isEqual:annotation.cluster]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Spread close annotations

+ (void)mutateCoordinatesOfClashingAnnotations:(NSSet *)annotations {
    
    NSDictionary *coordinateValuesToAnnotations = [self groupAnnotationsByLocationValue:annotations];
    
    for (NSValue *coordinateValue in coordinateValuesToAnnotations.allKeys) {
        NSMutableArray *outletsAtLocation = coordinateValuesToAnnotations[coordinateValue];
        if (outletsAtLocation.count > 1) {
            CLLocationCoordinate2D coordinate;
            [coordinateValue getValue:&coordinate];
            [self repositionAnnotations:[[NSMutableSet alloc] initWithArray:outletsAtLocation]
             toAvoidClashAtCoordination:coordinate];
        }
    }
}

+ (NSDictionary *)groupAnnotationsByLocationValue:(NSSet *)annotations {
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (ADClusterAnnotation *pin in annotations) {
        
        if ([pin isKindOfClass:[MKUserLocation class]] || !pin.cluster) {
            continue;
        }
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DRoundedLonLat(pin.cluster.clusterCoordinate, 5);
        NSValue *coordinateValue = [NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
        
        NSMutableArray *annotationsAtLocation = result[coordinateValue];
        if (!annotationsAtLocation) {
            annotationsAtLocation = [NSMutableArray array];
            result[coordinateValue] = annotationsAtLocation;
        }
        
        [annotationsAtLocation addObject:pin];
    }
    return result;
}

+ (void)repositionAnnotations:(NSMutableSet *)annotations toAvoidClashAtCoordination:(CLLocationCoordinate2D)coordinate {
    
    double distance = 3 * annotations.count / 2.0;
    double radiansBetweenAnnotations = (M_PI * 2) / annotations.count;
    
    int i = 0;
    for (ADClusterAnnotation *annotation in annotations) {
        
        double heading = radiansBetweenAnnotations * i;
        CLLocationCoordinate2D newCoordinate = [self calculateCoordinateFrom:coordinate onBearing:heading atDistance:distance];
        
        annotation.cluster.clusterCoordinate = newCoordinate;
        
        i++;
    }
}

+ (CLLocationCoordinate2D)calculateCoordinateFrom:(CLLocationCoordinate2D)coordinate  onBearing:(double)bearingInRadians atDistance:(double)distanceInMetres {
    
    double coordinateLatitudeInRadians = coordinate.latitude * M_PI / 180;
    double coordinateLongitudeInRadians = coordinate.longitude * M_PI / 180;
    
    double distanceComparedToEarth = distanceInMetres / 6378100;
    
    double resultLatitudeInRadians = asin(sin(coordinateLatitudeInRadians) * cos(distanceComparedToEarth) + cos(coordinateLatitudeInRadians) * sin(distanceComparedToEarth) * cos(bearingInRadians));
    double resultLongitudeInRadians = coordinateLongitudeInRadians + atan2(sin(bearingInRadians) * sin(distanceComparedToEarth) * cos(coordinateLatitudeInRadians), cos(distanceComparedToEarth) - sin(coordinateLatitudeInRadians) * sin(resultLatitudeInRadians));
    
    CLLocationCoordinate2D result;
    result.latitude = resultLatitudeInRadians * 180 / M_PI;
    result.longitude = resultLongitudeInRadians * 180 / M_PI;
    return result;
}

- (NSSet *)mapRectsFromNumberOfClustersAcross:(int)amount mapRect:(MKMapRect)rect {
    
    if (amount == 0) {
        return [NSSet setWithObject:[NSDictionary dictionaryFromMapRect:rect]];
    }
    
    double x = rect.origin.x;
    double y = rect.origin.y;
    double width = rect.size.width;
    double height = rect.size.height;
    
    //create basic cluster grid
    double clusterWidth = width/amount;
    int horizontalClusters = amount;
    int verticalClusters = round(height/clusterWidth);
    double clusterHeight = height/verticalClusters;
    
    //build array of MKMapRects
    NSMutableSet* set = [[NSMutableSet alloc] initWithCapacity:10];
    for (int i=0; i<horizontalClusters; i++) {
        double newX = x + clusterWidth*(i);
        for (int j=0; j<verticalClusters; j++) {
            double newY = y + clusterHeight*(j);
            MKMapRect newRect = MKMapRectMake(newX, newY, clusterWidth, clusterHeight);
            [set addObject:[NSDictionary dictionaryFromMapRect:newRect]];
        } 
    }
    
    return set;
}

- (MKMapRect)visibleMapRectWithBuffer {
    
    double width = _mapView.visibleMapRect.size.width;
    double height = _mapView.visibleMapRect.size.height;
    MKMapRect mapRect = _mapView.visibleMapRect;
    mapRect = MKMapRectUnion(mapRect, MKMapRectOffset(_mapView.visibleMapRect, -width, -height));
    mapRect = MKMapRectUnion(mapRect, MKMapRectOffset(_mapView.visibleMapRect, width, height));
    
    return mapRect;
}

@end
