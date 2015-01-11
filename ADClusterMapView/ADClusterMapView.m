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
#import "NSDictionary+MKMapRect.h"
#import "CLLocation+Utilities.h"
#import "TSClusterOperation.h"

NSString * const TSMapViewWillChangeRegion = @"TSMapViewWillChangeRegion";
NSString * const TSMapViewDidChangeRegion = @"TSMapViewDidChangeRegion";


@interface ADClusterMapView ()

@property (nonatomic, weak) id <ADClusterMapViewDelegate>  secondaryDelegate;
@property (nonatomic, strong) ADMapCluster *rootMapCluster;
@property (nonatomic, assign) BOOL isAnimatingClusters;
@property (nonatomic, assign) BOOL isSettingAnnotations;
@property (nonatomic, strong) NSMutableSet *singleAnnotationsPool;
@property (nonatomic, strong) NSMutableSet *clusterAnnotationsPool;
@property (nonatomic, strong) NSMutableSet *clusterableAnnotationsAdded;
@property (nonatomic, strong) NSSet *annotationsToBeSet;
@property (nonatomic, strong) NSMutableSet *originalAnnotations;
@property (nonatomic, strong) id<MKAnnotation> previouslySelectedAnnotation;
@property (nonatomic) BOOL shouldReselectAnnotation;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSDate *lastAnnotationSet;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign) BOOL shouldRefreshMap;
@property (assign) MKMapRect previousVisibleMapRectClustered;

@end

@interface ADClusterMapView (Private)
- (void)_clusterInMapRect:(MKMapRect)rect newRootCluster:(BOOL)isNewCluster;
@end

@implementation ADClusterMapView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initHelpers];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initHelpers];
    }
    return self;
}

- (void)didMoveToSuperview {
    
    [super didMoveToSuperview];
    
    if (!self.superview) {
        [_operationQueue cancelAllOperations];
    }
}

- (void)initHelpers {
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:1];
    [self.operationQueue setName:@"Clustering Queue"];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(didPanMap:)];
    [panRecognizer setDelegate:self];
    [self addGestureRecognizer:panRecognizer];
}

- (void)initAnnotationPools:(NSUInteger)numberOfAnnotationsInPool {
    
    [super removeAnnotations:_clusterAnnotations.allObjects];
    _singleAnnotationsPool = [[NSMutableSet alloc] initWithCapacity: numberOfAnnotationsInPool];
    _clusterAnnotationsPool = [[NSMutableSet alloc] initWithCapacity: numberOfAnnotationsInPool];
    for (int i = 0; i < numberOfAnnotationsInPool; i++) {
        ADClusterAnnotation * annotation = [[ADClusterAnnotation alloc] init];
        annotation.type = ADClusterAnnotationTypeLeaf;
        [_singleAnnotationsPool addObject:annotation];
        annotation = [[ADClusterAnnotation alloc] init];
        annotation.type = ADClusterAnnotationTypeCluster;
        [_clusterAnnotationsPool addObject:annotation];
    }
    [super addAnnotations:_singleAnnotationsPool.allObjects];
    [super addAnnotations:_clusterAnnotationsPool.allObjects];
    _clusterAnnotations = [_singleAnnotationsPool setByAddingObjectsFromSet:_clusterAnnotationsPool];
}

- (void)setClusterableAnnotations:(NSSet *)annotations {
    
    if (!annotations) {
        return;
    }
    
    if (!_lastAnnotationSet) {
        _lastAnnotationSet = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    BOOL shouldShowIndicator = YES;
    BOOL shouldContinue = NO;
    if ([[NSDate date] timeIntervalSinceDate:_lastAnnotationSet] >= 5 || _shouldRefreshMap) {
        shouldContinue = YES;
    }
    else {
        shouldShowIndicator = NO;
    }
    
    if (_originalAnnotations.count > annotations.count) {
        shouldContinue = YES;
        shouldShowIndicator = NO;
    }
    
    if (!_originalAnnotations.count) {
        shouldContinue = YES;
        shouldShowIndicator = NO;
    }
    
    if (!_isSettingAnnotations && !_isAnimatingClusters && ! _operationQueue.operationCount && shouldContinue) {
        _isSettingAnnotations = YES;
        _shouldRefreshMap = NO;
        _lastAnnotationSet = [NSDate date];
        NSLog(@"isSettingAnnoatations");
        
        if (shouldShowIndicator) {
            [self insertSubview:_indicatorView atIndex:1];
            [_indicatorView startAnimating];
        }
        
        if (!_indicatorView) {
            _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            _indicatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
            _indicatorView.layer.cornerRadius = 5;
            _indicatorView.center = self.center;
            [_indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
        
        _originalAnnotations = [[NSMutableSet alloc] initWithSet:annotations];
    
        NSInteger numberOfAnnotationsInPool = 2 * [self numberOfClusters]; //We manage a pool of annotations. In case we have N splits and N joins in a single animation we have to double up the actual number of annotations that belongs to the pool.
        if (_clusterAnnotations.count != numberOfAnnotationsInPool * 2) {
            [self initAnnotationPools:numberOfAnnotationsInPool];
        }

        double gamma = 1.0; // default value
        if ([_secondaryDelegate respondsToSelector:@selector(clusterDiscriminationPowerForMapView:)]) {
            gamma = [_secondaryDelegate clusterDiscriminationPowerForMapView:self];
        }

        NSString * clusterTitle = @"%d elements";
        if ([_secondaryDelegate respondsToSelector:@selector(clusterTitleForMapView:)]) {
            clusterTitle = [_secondaryDelegate clusterTitleForMapView:self];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // use wrapper annotations that expose a MKMapPoint property instead of a CLLocationCoordinate2D property
            NSMutableSet * mapPointAnnotations = [[NSMutableSet alloc] initWithCapacity:annotations.count];
            for (id<MKAnnotation> annotation in annotations) {
                ADMapPointAnnotation * mapPointAnnotation = [[ADMapPointAnnotation alloc] initWithAnnotation:annotation];
                [mapPointAnnotations addObject:mapPointAnnotation];
            }

            // Setting visibility of cluster annotations subtitle (defaults to YES)
            BOOL shouldShowSubtitle = YES;
            if ([_secondaryDelegate respondsToSelector:@selector(shouldShowSubtitleForClusterAnnotationsInMapView:)]) {
                shouldShowSubtitle = [_secondaryDelegate shouldShowSubtitleForClusterAnnotationsInMapView:self];
            }

            _rootMapCluster = [ADMapCluster rootClusterForAnnotations:mapPointAnnotations
                                                                gamma:gamma
                                                         clusterTitle:clusterTitle
                                                         showSubtitle:shouldShowSubtitle];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.superview) {
                    return;
                }
                [self _clusterInMapRect:self.visibleMapRect newRootCluster:YES];
                if ([_secondaryDelegate respondsToSelector:@selector(mapViewDidFinishClustering:)]) {
                    [_secondaryDelegate mapViewDidFinishClustering:self];
                }
                _isSettingAnnotations = NO;
                [self checkAnnotationsToBeSet];
            });
        });
    } else {
        // keep the annotations for setting them later
        _annotationsToBeSet = annotations;
        [self checkAnnotationsToBeSet];
    }
}

- (void)addClusteredAnnotation:(id<MKAnnotation>)annotation {
    
    if (!annotation) {
        return;
    }
    
    if (_clusterableAnnotationsAdded) {
        [_clusterableAnnotationsAdded addObject:annotation];
    }
    else {
        _clusterableAnnotationsAdded = [[NSMutableSet alloc] initWithObjects:annotation, nil];
    }
    
    [self setClusterableAnnotations:[NSSet setWithSet:_clusterableAnnotationsAdded]];
}

- (void)addClusteredAnnotations:(NSArray *)annotations {
    
    if (!annotations || !annotations.count) {
        return;
    }
    
    if (_clusterableAnnotationsAdded) {
        [_clusterableAnnotationsAdded addObjectsFromArray:annotations];
    }
    else {
        _clusterableAnnotationsAdded = [[NSMutableSet alloc] initWithArray:annotations];
    }
    
    [self setClusterableAnnotations:[NSSet setWithSet:_clusterableAnnotationsAdded]];
}

- (void)addAnnotation:(id<MKAnnotation>)annotation {
    [self addNonClusteredAnnotation:annotation];
}

- (void)addAnnotations:(NSArray *)annotations {
    
    [self addNonClusteredAnnotations:annotations];
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation {
    
    if ([_clusterableAnnotationsAdded containsObject:annotation]) {
        [_clusterableAnnotationsAdded removeObject:annotation];
        [self setClusterableAnnotations:_clusterableAnnotationsAdded];
    }
    
    [super removeAnnotation:annotation];
}

- (void)removeAnnotations:(NSArray *)annotations {
    
    NSUInteger previousCount = _clusterableAnnotationsAdded.count;
    NSSet *set = [NSSet setWithArray:annotations];
    [_clusterableAnnotationsAdded minusSet:set];
    
    if (_clusterableAnnotationsAdded.count != previousCount) {
        [self setClusterableAnnotations:_clusterableAnnotationsAdded];
    }
    
    [super removeAnnotations:annotations];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated {
    
    [super selectAnnotation:annotation animated:animated];
}

- (void)selectClusterAnnotation:(ADClusterAnnotation *)annotation animated:(BOOL)animated {
    [super selectAnnotation:annotation animated:animated];
}

- (NSArray *)displayedAnnotations {
    NSMutableArray * displayedAnnotations = [[NSMutableArray alloc] init];
    for (ADClusterAnnotation * annotation in [_singleAnnotationsPool setByAddingObjectsFromSet:_clusterAnnotationsPool]) {
        NSAssert([annotation isKindOfClass:[ADClusterAnnotation class]], @"Unexpected annotation!");
        if (annotation.coordinate.latitude != kADCoordinate2DOffscreen.latitude && annotation.coordinate.longitude != kADCoordinate2DOffscreen.longitude) {
            [displayedAnnotations addObject:annotation];
        }
    }
    
    return displayedAnnotations;
}

// careful, the implementation of the following method is slow
- (NSArray *)annotations {
//    NSArray * otherAnnotations = [[super annotations] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
//        return  ![evaluatedObject isKindOfClass: [ADClusterAnnotation class]];
//    }]];
    
    NSMutableSet *set = [NSMutableSet setWithArray:[super annotations]];
    [set minusSet:_clusterAnnotations];
    
    return [_originalAnnotations.allObjects arrayByAddingObjectsFromArray:set.allObjects];
}

- (void)addNonClusteredAnnotation:(id<MKAnnotation>)annotation {
    [super addAnnotation:annotation];
}

- (void)addNonClusteredAnnotations:(NSArray *)annotations {
    [super addAnnotations:annotations];
}

- (void)removeNonClusteredAnnotation:(id<MKAnnotation>)annotation {
    [super removeAnnotation:annotation];
}

- (void)removeNonClusteredAnnotations:(NSArray *)annotations {
    [super removeAnnotations:annotations];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didPanMap:(UIGestureRecognizer*)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        if ([_secondaryDelegate respondsToSelector:@selector(userWillPanMapView:)]) {
            [_secondaryDelegate userWillPanMapView:self];
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([_secondaryDelegate respondsToSelector:@selector(userDidPanMapView:)]) {
            [_secondaryDelegate userDidPanMapView:self];
        }
    }
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

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_secondaryDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_secondaryDelegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    for (ADClusterAnnotation * annotation in _clusterAnnotations) {
        if ([annotation isKindOfClass:[ADClusterAnnotation class]]) {
            if (annotation.shouldBeRemovedAfterAnimation) {
                [annotation reset];
            }
            annotation.shouldBeRemovedAfterAnimation = NO;
        }
    }
    _isAnimatingClusters = NO;
    [self checkAnnotationsToBeSet];
    
    if ([_secondaryDelegate respondsToSelector:@selector(clusterAnimationDidStopForMapView:)]) {
        [_secondaryDelegate clusterAnimationDidStopForMapView:self];
    }
    
    NSLog(@"Finished Animating");
}

- (void)checkAnnotationsToBeSet {
    
    if (_annotationsToBeSet) {
        if (_annotationsToBeSet.count < _originalAnnotations.count || _shouldRefreshMap) {
            [self setAwaitingAnnotations];
        }
        else {
            [self performSelector:@selector(setAwaitingAnnotations) withObject:nil afterDelay:5];
        }
    }
}

- (void)setAwaitingAnnotations {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (_annotationsToBeSet) {
            NSSet *annotations = _annotationsToBeSet;
            _annotationsToBeSet = nil;
            [self setClusterableAnnotations:annotations];
        }
    }];
}

- (void)needsRefresh {
    
    _shouldRefreshMap = YES;
    [self setAwaitingAnnotations];
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[ADClusterAnnotation class]]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        } else {
            return nil;
        }
	}
    // only leaf clusters have annotations
    if (((ADClusterAnnotation *)annotation).type == ADClusterAnnotationTypeLeaf || ![_secondaryDelegate respondsToSelector:@selector(mapView:viewForClusterAnnotation:)]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        }
        else {
            return nil;
        }
    } else {
        return [_secondaryDelegate mapView:self viewForClusterAnnotation:annotation];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
        [_secondaryDelegate mapView:self regionWillChangeAnimated:animated];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TSMapViewWillChangeRegion object:nil];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    if (MKMapRectContainsPoint(self.visibleMapRect, MKMapPointForCoordinate(kADCoordinate2DOffscreen))) {
        return;
    }
    
    if (!_isSettingAnnotations){
        [self _clusterInMapRect:self.visibleMapRect newRootCluster:NO];
    }
    if (_previouslySelectedAnnotation) {
        _shouldReselectAnnotation = YES;
    }
    for (id<MKAnnotation> annotation in [self selectedAnnotations]) {
        [self deselectAnnotation:annotation animated:YES];
    }
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [_secondaryDelegate mapView:self regionDidChangeAnimated:animated];
    }
    if (_shouldReselectAnnotation) {
        _shouldReselectAnnotation = NO;
        [self selectClusterAnnotation:_previouslySelectedAnnotation animated:YES];
        _previouslySelectedAnnotation = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TSMapViewDidChangeRegion object:nil];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if ([view.annotation isKindOfClass:[ADClusterAnnotation class]]) {
        if (((ADClusterAnnotation *)view.annotation).type == ADClusterAnnotationTypeLeaf &&
            !_shouldReselectAnnotation &&
            ((ADClusterAnnotation *)view.annotation).cluster) {
            _previouslySelectedAnnotation = [((ADClusterAnnotation *)view.annotation).originalAnnotations firstObject];
        }
    }
    
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [_secondaryDelegate mapView:mapView didSelectAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    if (!_shouldReselectAnnotation) {
        _previouslySelectedAnnotation = nil;
    }
    
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)]) {
        [_secondaryDelegate mapView:mapView didDeselectAnnotationView:view];
    }
}

- (ADClusterAnnotation *)clusterAnnotationForOriginalAnnotation:(id<MKAnnotation>)annotation {
    NSAssert(![annotation isKindOfClass:[ADClusterAnnotation class]], @"Unexpected annotation!");
    for (ADClusterAnnotation * clusterAnnotation in self.displayedAnnotations) {
        if ([clusterAnnotation.cluster isRootClusterForAnnotation:annotation]) {
            return clusterAnnotation;
        }
    }
    return nil;
}


- (NSUInteger)numberOfClusters {
    NSUInteger numberOfClusters = 32; // default value
    if ([_secondaryDelegate respondsToSelector:@selector(numberOfClustersInMapView:)]) {
        numberOfClusters = [_secondaryDelegate numberOfClustersInMapView:self];
    }
    //multiply by 9 for the visible rect plus 8 directions of possible screen travel (up, down, up-left, down-left, etc.)
    return numberOfClusters * 9;
}

@end

@implementation ADClusterMapView (Private)


- (void)_clusterInMapRect:(MKMapRect)rect newRootCluster:(BOOL)isNewCluster {
    
    if (!self.superview) {
        return;
    }
    
    _isAnimatingClusters = YES;
    
    if (isNewCluster) {
        _previousVisibleMapRectClustered = MKMapRectNull;
    }
    
    if (!MKMapRectIsNull(_previousVisibleMapRectClustered) &&
        !MKMapRectIsEmpty(_previousVisibleMapRectClustered)) {
        
        MKMapRect halvedPreviousVisibleRect = MKMapRectInset(_previousVisibleMapRectClustered, _previousVisibleMapRectClustered.size.width/4, _previousVisibleMapRectClustered.size.width/4);
        
        if (MKMapRectIntersectsRect(rect, halvedPreviousVisibleRect) &&
            MKMapRectSizeIsEqual(rect, _previousVisibleMapRectClustered)) {
            _isAnimatingClusters = NO;
            return;
        }
    }
    
    NSLog(@"clusterInMapRect");
    
    if (_operationQueue.operationCount) {
        [_operationQueue cancelAllOperations];
    }
    
    TSClusterOperation *clusterOperation = [[TSClusterOperation alloc] initWithMapView:self
                                                                           rootCluster:_rootMapCluster
                                                                            completion:^(ADClusterMapView *mapView) {
                                                                                [_indicatorView stopAnimating];
                                                                                [_indicatorView removeFromSuperview];
                                                                                _previousVisibleMapRectClustered = rect;
                                                                            }];
    [_operationQueue addOperation:clusterOperation];
    [_operationQueue setSuspended:NO];
}


@end
