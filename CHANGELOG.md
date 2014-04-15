## 1.1.0 (under development)

Features:

  - Use ARC

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
