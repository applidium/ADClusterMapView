//
//  CDAppDelegate.m
//  ClusterDemo
//
//  Created by Patrick Nollet on 09/10/12.
//  Copyright (c) 2012 Applidium. All rights reserved.
//

#import "CDAppDelegate.h"

#import "CDToiletsMapViewController.h"
#import "CDStreetlightsMapViewController.h"

@implementation CDAppDelegate
@synthesize window = _window;

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    UITabBarController * tabbarController = [[UITabBarController alloc] init];
    UIViewController * toiletsViewController = [[CDToiletsMapViewController alloc] initWithNibName:@"CDMapViewController" bundle:nil];
    toiletsViewController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Free Toilets" image:[UIImage imageNamed:@"CDToiletItem.png"] tag:0] autorelease];
    UIViewController * streetlightsViewController = [[CDStreetlightsMapViewController alloc] initWithNibName:@"CDMapViewController" bundle:nil];
    streetlightsViewController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Streetlights" image:[UIImage imageNamed:@"CDStreetlightItem.png"] tag:0] autorelease];
    tabbarController.viewControllers = [NSArray arrayWithObjects:toiletsViewController, streetlightsViewController, nil];
    [streetlightsViewController release];
    [toiletsViewController release];
    self.window.rootViewController = tabbarController;
    [tabbarController release];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
