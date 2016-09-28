//
//  ADClusterMapView.m
//  ADClusterMapView
//
//  Created by Patrick Nollet on 30/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <QuartzCore/CoreAnimation.h>
#import "ADClusterMapView.h"
#import "ADClusterAnnotation.h"
#import "ADMapPointAnnotation.h"
#import "ADMapCluster.h"

@interface ADClusterMapView () {
@private
    __weak id <ADClusterMapViewDelegate>  _secondaryDelegate;
    ADMapCluster *                 _rootMapCluster;
    BOOL                           _isAnimatingClusters;
    BOOL                           _shouldComputeClusters;
}
@property (strong, nonatomic) NSMutableArray * clusterAnnotations;
@property (strong, nonatomic) NSMutableArray * clusterAnnotationsToAddAfterAnimation;
- (void)_initElements;
- (ADClusterAnnotation *)_newAnnotationWithCluster:(ADMapCluster *)cluster ancestorAnnotation:(ADClusterAnnotation *)ancestor;
- (void)_clusterInMapRect:(MKMapRect)rect;
- (NSInteger)_numberOfClusters;
- (BOOL)_annotation:(ADClusterAnnotation *)annotation belongsToClusters:(NSArray *)clusters;
- (void)_handleClusterAnimationEnded;
- (void)_addClusterAnnotations:(NSArray <id <MKAnnotation>> *)annotations;
- (void)_addClusterAnnotation:(id <MKAnnotation>)annotation;
@end

@implementation ADClusterMapView

- (nonnull instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _initElements];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _initElements];
    }
    return self;
}

#pragma mark - MKMapView
- (void)addAnnotation:(nonnull id<MKAnnotation>)annotation {
    NSAssert(NO, @"Cannot be used for now");
}

- (void)addAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations {
    NSAssert(NO, @"Cannot be used for now");
}

- (void)removeAnnotation:(nonnull id<MKAnnotation>)annotation {
    [self.clusterAnnotations removeObject:annotation];
    [super removeAnnotation:annotation];
}

- (void)removeAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations {
    [self.clusterAnnotations removeObjectsInArray:annotations];
    [super removeAnnotations:annotations];
}

- (void)selectAnnotation:(nonnull id<MKAnnotation>)annotation animated:(BOOL)animated {
    ADClusterAnnotation *_Nullable clusterAnnotation = [self clusterAnnotationForOriginalAnnotation:annotation];
    // If annotation is not part of a cluster then it should be a single annotation that is selectable
    id<MKAnnotation> _Nonnull annotationToSelect = clusterAnnotation ?: annotation;
    
    [super selectAnnotation:annotationToSelect animated:animated];
}

#pragma mark - Getters
- (nonnull NSArray<id<MKAnnotation>> *)displayedAnnotations {
    return [self annotationsInMapRect:self.visibleMapRect].allObjects;
}

- (nonnull NSArray<id<MKAnnotation>> *)displayedClusterAnnotations {
    return [self.displayedAnnotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [ADClusterAnnotation class]]];
}

#pragma mark - Methods
- (nullable ADClusterAnnotation *)clusterAnnotationForOriginalAnnotation:(nonnull id<MKAnnotation>)annotation {
    NSAssert(![annotation isKindOfClass:[ADClusterAnnotation class]], @"Unexpected annotation!");
    for (ADClusterAnnotation * clusterAnnotation in self.displayedClusterAnnotations) {
        if ([clusterAnnotation.cluster isRootClusterForAnnotation:annotation]) {
            return clusterAnnotation;
        }
    }
    return nil;
}

- (void)selectClusterAnnotation:(nonnull ADClusterAnnotation *)annotation animated:(BOOL)animated {
    [super selectAnnotation:annotation animated:animated];
}

- (void)setAnnotations:(nullable NSArray<id<MKAnnotation>> *)annotations {
    [self removeAnnotations:self.annotations];
    NSMutableArray<id<MKAnnotation>> * leafClusterAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
    
    for (NSInteger i = 0; i < annotations.count; i++) {
        ADClusterAnnotation * annotation = [[ADClusterAnnotation alloc] init];
        annotation.type = ADClusterAnnotationTypeLeaf;
        annotation.coordinate = [annotations[i] coordinate];
        [leafClusterAnnotations addObject:annotation];
    }
    
    [self _addClusterAnnotations:leafClusterAnnotations];
    double gamma = 1.0; // default value
    
    if ([_secondaryDelegate respondsToSelector:@selector(clusterDiscriminationPowerForMapView:)]) {
        gamma = [_secondaryDelegate clusterDiscriminationPowerForMapView:self];
    }

    NSString *_Nullable clusterTitle = @"%d elements";
    if ([_secondaryDelegate respondsToSelector:@selector(clusterTitleForMapView:)]) {
        clusterTitle = [_secondaryDelegate clusterTitleForMapView:self];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // use wrapper annotations that expose a MKMapPoint property instead of a CLLocationCoordinate2D property
        NSMutableArray<ADMapPointAnnotation *> * mapPointAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
        for (id<MKAnnotation> annotation in annotations) {
            ADMapPointAnnotation * mapPointAnnotation = [[ADMapPointAnnotation alloc] initWithAnnotation:annotation];
            [mapPointAnnotations addObject:mapPointAnnotation];
        }

        // Setting visibility of cluster annotations subtitle (defaults to YES)
        BOOL shouldShowSubtitle = YES;
        if ([_secondaryDelegate respondsToSelector:@selector(shouldShowSubtitleForClusterAnnotationsInMapView:)]) {
            shouldShowSubtitle = [_secondaryDelegate shouldShowSubtitleForClusterAnnotationsInMapView:self];
        }

        _rootMapCluster = [ADMapCluster rootClusterForAnnotations:mapPointAnnotations gamma:gamma clusterTitle:clusterTitle showSubtitle:shouldShowSubtitle];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self _clusterInMapRect:self.visibleMapRect];
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K = nil", NSStringFromSelector(@selector(cluster))];
            NSArray * annotationNotDisplayedAfterClustering = [self.clusterAnnotations filteredArrayUsingPredicate:predicate];
            [self removeAnnotations:annotationNotDisplayedAfterClustering];
            if ([_secondaryDelegate respondsToSelector:@selector(mapViewDidFinishClustering:)]) {
                [_secondaryDelegate mapViewDidFinishClustering:self];
            }
        });
    });
}

- (void)addNonClusteredAnnotation:(nonnull id<MKAnnotation>)annotation {
    [super addAnnotation:annotation];
}

- (void)addNonClusteredAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations {
    [super addAnnotations:annotations];
}

- (void)removeNonClusteredAnnotation:(nonnull id<MKAnnotation>)annotation {
    [super removeAnnotation:annotation];
}

- (void)removeNonClusteredAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations {
    [super removeAnnotations:annotations];
}

#pragma mark - Objective-C Runtime and subclassing methods
- (void)setDelegate:(id<ADClusterMapViewDelegate>)delegate {
    /*
     For an undefined reason, setDelegate is called multiple times. The first time, it is called with delegate = nil
     Therefore _secondaryDelegate may be nil when [_secondaryDelegate respondsToSelector:aSelector] is called (result : NO)
     There is some caching done in order to avoid calling respondsToSelector: too much. That's why if we don't take care the runtime will guess that we always have [_secondaryDelegate respondsToSelector:] = NO
     Therefore we clear the cache by setting the delegate to nil.
     */
    [super setDelegate:nil];
    _secondaryDelegate = delegate;
    [super setDelegate:self];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector = [super respondsToSelector:aSelector] || [_secondaryDelegate respondsToSelector:aSelector];
    return respondsToSelector;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([_secondaryDelegate respondsToSelector:aSelector]) {
        return _secondaryDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_secondaryDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_secondaryDelegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark - MKMapViewDelegate
- (nullable MKAnnotationView *)mapView:(nonnull MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[ADClusterAnnotation class]]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        }
        return nil;
	}
    // only leaf clusters have annotations
    if (((ADClusterAnnotation *)annotation).type == ADClusterAnnotationTypeLeaf
        || ![_secondaryDelegate respondsToSelector:@selector(mapView:viewForClusterAnnotation:)]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        }
        return nil;
    }
    return [_secondaryDelegate mapView:self viewForClusterAnnotation:annotation];
}

- (void)mapView:(nonnull MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (_isAnimatingClusters) {
        _shouldComputeClusters = YES;
    } else {
        _isAnimatingClusters = YES;
        [self _clusterInMapRect:self.visibleMapRect];
    }
    for (id<MKAnnotation> annotation in [self selectedAnnotations]) {
        [self deselectAnnotation:annotation animated:YES];
    }
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [_secondaryDelegate mapView:self regionDidChangeAnimated:animated];
    }
}

- (void)mapView:(nonnull MKMapView *)mapView didSelectAnnotationView:(nonnull MKAnnotationView *)view {
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [_secondaryDelegate mapView:mapView didSelectAnnotationView:view];
    }
}

#pragma mark - Private
- (void)_initElements {
    _clusterAnnotations = [[NSMutableArray alloc] init];
    _clusterAnnotationsToAddAfterAnimation = [[NSMutableArray alloc] init];
}

-(nonnull ADClusterAnnotation *)_newAnnotationWithCluster:(nullable ADMapCluster *)cluster ancestorAnnotation:(nullable ADClusterAnnotation *)ancestor {
    ADClusterAnnotation * annotation = [[ADClusterAnnotation alloc] init];
    annotation.type = (cluster.numberOfChildren == 1) ? ADClusterAnnotationTypeLeaf : ADClusterAnnotationTypeCluster;
    annotation.cluster = cluster;
    annotation.coordinate = (ancestor) ? ancestor.coordinate : cluster.clusterCoordinate;
    return annotation;
}

- (void)_clusterInMapRect:(MKMapRect)rect {
    NSArray * clustersToShowOnMap = [_rootMapCluster find:[self _numberOfClusters] childrenInMapRect:rect];

    NSMutableArray<ADClusterAnnotation *> *_Nonnull annotationToRemoveFromMap = [[NSMutableArray alloc] init];
    NSMutableArray<ADClusterAnnotation *> *_Nonnull annotationToAddToMap = [[NSMutableArray alloc] init];
    NSMutableArray<ADClusterAnnotation *> *_Nonnull selfDividingAnnotations = [[NSMutableArray alloc] init];
    NSArray *_Nonnull displayedAnnotation = self.displayedClusterAnnotations;
    
    for (ADClusterAnnotation * annotation in displayedAnnotation) {
        if ([annotation isKindOfClass:[MKUserLocation class]] || !annotation.cluster) {
            continue;
        }
        
        for (ADMapCluster * cluster in clustersToShowOnMap) { // is the current annotation cluster an ancestor of one of the clustersToShowOnMap?
            if (![annotation.cluster isAncestorOf:cluster]) {
                continue;
            }
            [selfDividingAnnotations addObject:annotation];
            break;
        }
    }

    // Let ancestor annotations divide themselves
    for (ADClusterAnnotation * annotation in selfDividingAnnotations) {
        ADMapCluster * originalAnnotationCluster = annotation.cluster;
        for (ADMapCluster * cluster in clustersToShowOnMap) {
            if (![originalAnnotationCluster isAncestorOf:cluster]) {
                continue;
            }
            ADClusterAnnotation * newAnnotation = [self _newAnnotationWithCluster:cluster ancestorAnnotation:annotation];
            [annotationToRemoveFromMap addObject:annotation];
            [annotationToAddToMap addObject:newAnnotation];
        }
    }

    // Converge annotations to ancestor clusters
    for (ADMapCluster * cluster in clustersToShowOnMap) {
        BOOL didAlreadyFindAChild = NO;
        for (__strong ADClusterAnnotation * annotation in displayedAnnotation) {
            if ([annotation isKindOfClass:[MKUserLocation class]] || !annotation.cluster || ![cluster isAncestorOf:annotation.cluster]) {
                continue;
            }
            if (!didAlreadyFindAChild) {
                ADClusterAnnotation * newAnnotation = [[ADClusterAnnotation alloc] init];
                newAnnotation.type = ADClusterAnnotationTypeCluster;
                newAnnotation.cluster = cluster;
                newAnnotation.coordinate = cluster.clusterCoordinate;
                [self.clusterAnnotationsToAddAfterAnimation addObject:newAnnotation];
            }
            annotation.cluster = cluster;
            annotation.shouldBeRemovedAfterAnimation = YES;
            didAlreadyFindAChild = YES;
        }
    }

    [self _addClusterAnnotations:annotationToAddToMap];
    [self removeAnnotations:annotationToRemoveFromMap];
    displayedAnnotation = self.displayedClusterAnnotations;
    
    [UIView animateWithDuration:0.5f animations:^{
        for (ADClusterAnnotation * annotation in displayedAnnotation) {
            if ([annotation isKindOfClass:[MKUserLocation class]]) {
                continue;
            }
            if (![annotation isKindOfClass:[MKUserLocation class]] && annotation.cluster) {
                NSAssert(!ADClusterCoordinate2DIsOffscreen(annotation.coordinate), @"annotation.coordinate not valid! Can't animate from an invalid coordinate (inconsistent result)!");
                annotation.coordinate = annotation.cluster.clusterCoordinate;
            }
        }
    } completion:^(BOOL finished) {
        [self _handleClusterAnimationEnded];;
    }];


    // Add not-yet-annotated clusters
    annotationToAddToMap = [[NSMutableArray alloc] init];
    
    for (ADMapCluster * cluster in clustersToShowOnMap) {
        BOOL isAlreadyAnnotated = NO;
        for (ADClusterAnnotation * annotation in displayedAnnotation) {
            if (![annotation isKindOfClass:[MKUserLocation class]]) {
                if ([cluster isEqual:annotation.cluster]) {
                    isAlreadyAnnotated = YES;
                    break;
                }
            }
        }
        if (!isAlreadyAnnotated) {
            ADClusterAnnotation * newAnnotation = [self _newAnnotationWithCluster:cluster ancestorAnnotation:nil];
            [annotationToAddToMap addObject:newAnnotation];
        }
    }
    [self _addClusterAnnotations:annotationToAddToMap];
}

- (NSInteger)_numberOfClusters {
    NSInteger numberOfClusters = 32; // default value
    if ([_secondaryDelegate respondsToSelector:@selector(numberOfClustersInMapView:)]) {
        numberOfClusters = [_secondaryDelegate numberOfClustersInMapView:self];
    }
    return numberOfClusters;
}


- (BOOL)_annotation:(nonnull ADClusterAnnotation *)annotation belongsToClusters:(nonnull NSArray<ADMapCluster *> *)clusters {
    if (!annotation.cluster) {
        return NO;
    }
    for (ADMapCluster * cluster in clusters) {
        if ([cluster isAncestorOf:annotation.cluster] || [cluster isEqual:annotation.cluster]) {
            return YES;
        }
    }
    return NO;
}

- (void)_handleClusterAnimationEnded {
    NSMutableArray *_Nonnull annotationToRemove = [[NSMutableArray alloc] init];;
    for (ADClusterAnnotation * annotation in self.annotations) {
        if ([annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        if ([annotation isKindOfClass:[ADClusterAnnotation class]]) {
            if (annotation.shouldBeRemovedAfterAnimation) {
                [annotationToRemove addObject:annotation];
            }
        }
    }
    [self removeAnnotations:annotationToRemove];
    [self _addClusterAnnotations:self.clusterAnnotationsToAddAfterAnimation];
    [self.clusterAnnotationsToAddAfterAnimation removeAllObjects];
    _isAnimatingClusters = NO;
    if (_shouldComputeClusters) { // do one more computation if the user moved the map while animating
        _shouldComputeClusters = NO;
        [self _clusterInMapRect:self.visibleMapRect];
    }
    if ([_secondaryDelegate respondsToSelector:@selector(clusterAnimationDidStopForMapView:)]) {
        [_secondaryDelegate clusterAnimationDidStopForMapView:self];
    }
}

- (void)_addClusterAnnotation:(nonnull id<MKAnnotation>)annotation {
    [self.clusterAnnotations addObject:annotation];
    [super addAnnotation:annotation];
}

- (void)_addClusterAnnotations:(nonnull NSArray<id<MKAnnotation>> *)annotations {
    [self.clusterAnnotations addObjectsFromArray:annotations];
    [super addAnnotations:annotations];
}

@end
