//
//  AppDelegate.m
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

+(AppDelegate*)instance {
    return  [[UIApplication sharedApplication]delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.storeManager = [[StoreManager alloc] init];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self.storeManager];
    
    // Let the device know we want to handle Newsstand push notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeNewsstandContentAvailability];
    
    // Check if the app is runnig in response to a notification
    NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        NSDictionary *aps = [payload objectForKey:@"aps"];
        if (aps && [aps objectForKey:@"content-available"]) {
            
            __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self applicationWillHandleNewsstandNotificationOfContent:[payload objectForKey:@"content-name"]];
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            });
        }
    }
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationWillHandleNewsstandNotificationOfContent:(NSString *)contentName
{
    NSLog(@"applicationWillHandleNewsstandNotificationOfContent");
/*
    IssuesManager *issuesManager = [IssuesManager sharedInstance];
    [issuesManager refresh];
    
    if (contentName) {
        for (BakerIssue *issue in issuesManager.issues) {
            if ([issue.ID isEqualToString:contentName]) {
                [issue download];
                break;
            }
        }
    } else {
        BakerIssue *targetIssue = [issuesManager.issues objectAtIndex:0];
        [targetIssue download];
    }
*/
}
@end
