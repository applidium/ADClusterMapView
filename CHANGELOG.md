## 1.5.0 (24 November 2016)

Miscellaneous:

  - Some code optimization regarding the way we first add and cluster annotations

## 1.4.0 (19 October 2016)

Features:

  - Added nullability annotations for better Swift support
  - Added missing items typing in collections

Miscellaneous:

  - Slightly reduced header imports
  - Small code readability improvements

## 1.3.0 (20 September 2016)

Features:

  - User can select a single annotation using MKMapView `selectAnnotation:animated:` method

Bugfixes:

  - Fix a crash when ADClusterMapView `clusterAnnotationForOriginalAnnotation:` method was called

## 1.2.0 (6 July 2016)

Features:

  - Improved annotations management

Bugfixes:

  - Fix clustered annotation refreshing issue
  - Fix displayed annotation on top left corner of map view

Miscellaneous:

  - Some coding style improvements
  - Slight code clean up

## 1.1.1 (17 June 2016)

Bugfixes:

  - Fix potential crash when forwarding selectors
  - Secondary delegate is now weak to prevent retain cycles

## 1.1.0 (17 November 2014)

Features:

  - Use ARC
  - `annotations` now returns an array of the annotations that the user added instead of ADClusterAnnotation instances.
  - Add methods to add and remove non clustered annotations

## 1.0.3 (15 April 2014)

Bugfixes:

  - Fix potential crash during animations (@scheinem)
  - Fix a bug when an ADClusterAnnotation instance had no cluster assigned in `mapView:viewForAnnotation:`
  - Fix crash when the view is deallocated and the private `MKMapAnnotationManager` class still tries to update a selected annotation. (@alloy)

Features:

  - `originalAnnotations` returns an array of id&lt;MKAnnotation&gt; (not ADMapPointAnnotation)

## 1.0.2 (8 April 2013)

Bugfixes:

  - Fix crash when the delegate is not responding to `mapView:viewForAnnotation:`. (@scheinem)
  - Add a delegate method to hide the subtitle of the cluster annotations.  (@scheinem, @steinerl)
  - Handle MKUserLocation annotations (@xfyre)

## 1.0.1 (7 November 2012)

Bugfixes:

  - Fix compiler errors and warnings in Xcode <4.4 (@DontPHazeMeBro)
  - Fix memory leaks
  - Annotation could not always be selected

## 1.0.0 (26 October 2012)

First release
