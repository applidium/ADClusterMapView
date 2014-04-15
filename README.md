# ADClusterMapView - MKMapView with clustering

ADClusterMapView is a drop-in subclass of MKMapView that displays and animates clusters of annotations. This is very useful in cases where you have to display many annotations on the map. Concept and implementation were described on Applidium's [website][].

[website]: http://applidium.com/en/news/too_many_pins_on_your_map/

## Quick start

1. Add the content of the ADClusterMapView folder to your iOS project
2. Link against the MapKit and CoreLocation frameworks if you don't already
3. Turn your MKMapView instance into a subclass of ADClusterMapView
4. Set your annotations by calling `setAnnotations:`. Do not use `addAnnotation:` or `addAnnotations:` as they are not supported yet.

### ARC

If you are not using ARC in your project, add the `-fobjc-arc` flag to the files of the library in the *Build Phases > Compile Sources* section in Xcode.

## Displaying custom MKAnnotationView instances

In the `mapView:viewForAnnotation:` and `mapView:viewForClusterAnnotation:` implementations of your map view's delegate, you are given an instance of ADClusterAnnotation. You can call `[annotation originalAnnotations]` to retrieve your original `id<MKAnnotation>` instances and customize your `MKAnnotationView` instance like you would do with Map Kit.
This is especially useful in the case of a *leaf* annotation, whose `originalAnnotations` array obviously contains one and only one object.

### Example code:
```objective-c
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MyAnnotationView * pinView = (MyAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ADClusterableAnnotation"];
    if (!pinView) {
        pinView = [[[MyAnnotationView alloc] initWithAnnotation:annotation
                                                reuseIdentifier:@"ADClusterableAnnotation"]
                   autorelease];
    }
    MyModel * model = [annotation originalAnnotations][0];
    pinView.image = model.image;
    return pinView;
}
```

## Optional delegate methods

We provide you with a few optional methods that you may want to add to your `ADClusterMapViewDelegate` implementation:

### Setting the maximum number of clusters that you want to display at the same time

```objective-c
- (NSInteger)numberOfClustersInMapView:(ADClusterMapView *)mapView; // default: 32
```

### Custom MKAnnotationView instance for clusters

```objective-c
- (MKAnnotationView *)mapView:(ADClusterMapView *)mapView viewForClusterAnnotation:(id <MKAnnotation>)annotation; // default: same as returned by mapView:viewForAnnotation:
```

### Custom title for clusters

```objective-c
- (NSString *)clusterTitleForMapView:(ADClusterMapView *)mapView; // default : @"%d elements"
```

### Set visibility for cluster annotation's subtitle

```objective-c
- (BOOL)shouldShowSubtitleForClusterAnnotationsInMapView:(ADClusterMapView *)mapView; // default: YES
```

### Disminish outliers weight

```objective-c
- (double)clusterDiscriminationPowerForMapView:(ADClusterMapView *)mapView; // This parameter emphasize the discrimination of annotations which are far away from the center of mass. default: 1.0 (no discrimination applied)
```

### Animation callback

```objective-c
- (void)clusterAnimationDidStopForMapView:(ADClusterMapView *)mapView;
```

## Future Work

There are a couple of improvements that could be done. Feel free to send us pull requests if you want to contribute!

- Add support for annotations addition and removal.
- Add support for multiple independant trees
- More?
