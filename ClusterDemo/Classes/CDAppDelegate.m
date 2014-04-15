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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UITabBarController * tabbarController = [[UITabBarController alloc] init];
    UIViewController * toiletsViewController = [[CDToiletsMapViewController alloc] initWithNibName:@"CDMapViewController" bundle:nil];
    toiletsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Free Toilets" image:[UIImage imageNamed:@"CDToiletItem.png"] tag:0];
    UIViewController * streetlightsViewController = [[CDStreetlightsMapViewController alloc] initWithNibName:@"CDMapViewController" bundle:nil];
    streetlightsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Streetlights" image:[UIImage imageNamed:@"CDStreetlightItem.png"] tag:0];
    tabbarController.viewControllers = [NSArray arrayWithObjects:toiletsViewController, streetlightsViewController, nil];
    self.window.rootViewController = tabbarController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
