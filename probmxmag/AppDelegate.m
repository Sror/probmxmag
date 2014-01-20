//
//  AppDelegate.m
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import <Parse/Parse.h>



@implementation AppDelegate



+(AppDelegate*)instance {
    return  [[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"app didFinishLaunchingWithOptions with launchOptions %@",launchOptions);
    
    self.storeManager = [[StoreManager alloc] init];
    self.publisher = [[Publisher alloc] init];
    //self.newsstandDownloader = [NewsstandDownloader sharedInstance];
    self.newsstandDownloader = [[NewsstandDownloader alloc] initWithPublisher:self.publisher];
    
    //rate app reminder
    [Appirater setAppId:@"709195924"];
    
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:1];
    [Appirater setTimeBeforeReminding:1];
    [Appirater setDebug:NO];
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    for(NKAssetDownload *asset in [nkLib downloadingAssets]) {
        [asset downloadWithDelegate:self.newsstandDownloader];
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self.storeManager];
    isSubscribed = [self.storeManager isSubscribed];
    NSLog(@"launchOptions %@",launchOptions);
    
    
    //Parse apn server implementation
    [Parse setApplicationId:@"1iJxP2Paprhv5RA5STPQlyvsMFZ9tWGZxTC9LHMH"
                  clientKey:@"YNxve5HhSdqdySYcuCJGAi2S9Wxc3KofW0ZzmBFu"];
    
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double counting
        // the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    // Let the device know we want to handle Newsstand push notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound | UIRemoteNotificationTypeNewsstandContentAvailability];

    // Check if the app is runnig in response to a notification
    NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        // Create a pointer to the Photo object
       
        NSDictionary *aps = [payload objectForKey:@"aps"];
        if (aps && [aps objectForKey:@"content-available"]) {
             NSLog(@"notified to get new content");
            __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }];
            
            // Credit where credit is due. This semaphore solution found here:
            // http://stackoverflow.com/a/4326754/2998
            dispatch_semaphore_t sema = NULL;
            sema = dispatch_semaphore_create(0);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self applicationWillHandleNewsstandNotificationOfContent:payload];
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            NSLog(@"dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)");
        }
    }
    /*
   
    // For debugging - allow multiple pushes per day
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NKDontThrottleNewsstandContentNotifications"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  */
    
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self
                                                    selector:@selector(readyForAppinator)
                                                    userInfo:nil
                                                     repeats:NO ];
    
    return YES;
}
-(void)readyForAppinator{
    NSLog(@"readyForAppinator");
    [Appirater appLaunched:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"app will resign active");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"app did enter background");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"app will enter foreground");
    //[Appirater appEnteredForeground:YES];
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"app did become active");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"app will terminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}



-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    NSLog(@"app did receive remote notification with userInfo %@",userInfo);
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }

//    [PFPush handlePush:userInfo];
    /*
    NSString *linkCover = [userInfo objectForKey:@"link-cover"];
    PFObject *linkCoverObject = [PFObject objectWithoutDataWithClassName:@"linkCover"
                                                                objectId:linkCover];
   
    NSLog(@"linkCoverObject %@",linkCoverObject);
      */
    /*
     {"aps":
     {
     "alert":"Доступен новый выпуск!",
     "sound":"default","badge":1,
     "content-available":1,
     "name-pdf":"probmxmag_special",
     "link-cover":"http://tinyurl.com/l54mpl2",
     "link-pdf":"http://tinyurl.com/nydazbo"
     }}
     */
    /* EXAMPLE JSON PUSH NOTIFICATION USERINFO
     aps =     {
     alert = "alert message";
     "content-available" = 1;
     sound = chime;
     };
     "link-cover" = "http://tinyurl.com/l54mpl2";
     "link-pdf" = "http://tinyurl.com/mhnmtv4";
     "name-pdf" = "probmxmag_special";
     title = "alertTitle";
     }
     
     { "alert": "Доступен новый выпуск журнала!", "sound": "chime", "title": "Ура!", "content-available": 1, "name-pdf": "probmxmag_special", "link-cover": "http://tinyurl.com/l54mpl2", "link-pdf": "http://tinyurl.com/mhnmtv4", "badge": "Increment" }
     */
     
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if (aps && [aps objectForKey:@"content-available"])
    {
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && [self.storeManager isSubscribed]) {
            NSLog(@"application subscribed and active");
            [self applicationWillHandleNewsstandNotificationOfContent:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:PublisherMustUpdateIssueList object:nil];
        }
        if ([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive &&![self.storeManager isSubscribed]) {
            NSLog(@"application active but not subscribed to get new content");
            [[NSNotificationCenter defaultCenter] postNotificationName:PublisherMustUpdateIssueList object:nil];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Уведомление" message:@"Доступен новый выпуск журнала. Подпишитесь на журнал, для автоматической загрузки новых выпусков." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
        
        //backgrounded
        if ([[UIApplication sharedApplication] applicationState]== UIApplicationStateBackground && [self.storeManager isSubscribed]) {
            NSLog(@"app backgrounded and subscribed to get new content");
            [self applicationWillHandleNewsstandNotificationOfContent:userInfo];
        }
        //inactive
        if ([[UIApplication sharedApplication] applicationState]== UIApplicationStateInactive && [self.storeManager isSubscribed]) {
            NSLog(@"app inactive and subscribed to get new content");
            [self applicationWillHandleNewsstandNotificationOfContent:userInfo];
        }
    }
}

- (void)applicationWillHandleNewsstandNotificationOfContent:(NSDictionary *)content
{
    NSLog(@"applicationWillHandleNewsstandNotificationOfContent %@",content);
    NSDictionary *aps = [content objectForKey:@"aps"];
    NSNumber * contentNmbr = [aps objectForKey:@"content-available"];
    if(contentNmbr && [contentNmbr intValue] > 0)
    {
        NSLog(@"New content Available: %i", [contentNmbr intValue]);

        NSString * namePDF =@"";
        NSString * pdfUrlS =@"";
        NSString * coverUrlS=@"";
        //define namePDF if it exist
        if ([content objectForKey:@"name-pdf"]){
            namePDF = [content objectForKey:@"name-pdf"];
            NSLog(@"PDF Name: %@", namePDF);
        }
        //define url string if it exist
        if([content objectForKey:@"link-pdf"]){
            pdfUrlS = [content objectForKey:@"link-pdf"];
            NSLog(@"PDF URL: %@", pdfUrlS);
        }
        //define cover url string if exist
        if([content objectForKey:@"link-cover"]){
            coverUrlS = [content  objectForKey:@"link-cover"];
            NSLog(@"Cover URL: %@",coverUrlS);
        }
        
        NKLibrary *library=[NKLibrary sharedLibrary];
        if ([library issueWithName:namePDF]) {
            NSLog(@"Issue already exist %@, in NKLibrary!",namePDF);
            [library removeIssue:[library issueWithName:namePDF]];
        }
        if (coverUrlS) {
            NSURL *url=[NSURL URLWithString:coverUrlS];
            NSData *imageData=[NSData dataWithContentsOfURL:url];
            
            if (imageData) {
                UIImage *newCoverImg=[UIImage imageWithData:imageData];
                [self.newsstandDownloader updateIssueIconWithImage:newCoverImg ];
                
            }
            
        }
        if(![namePDF isEqualToString:@""] && ![pdfUrlS isEqualToString:@""])
        {
            NSURL *url = [NSURL URLWithString:pdfUrlS];
            NKLibrary *library = [NKLibrary sharedLibrary];
            if ([library issueWithName:namePDF]) {
                [library removeIssue:[library issueWithName:namePDF]];
            }
            
            NKIssue *issue = [library addIssueWithName:namePDF date:[NSDate date]];
            NSURLRequest * request = nil;
            request = [[NSURLRequest alloc ]initWithURL:url];
            NKAssetDownload *asset = [issue addAssetWithRequest:request];
            [asset setUserInfo:[NSDictionary dictionaryWithObject:namePDF forKey:@"filename"]];
            NSLog(@"added NKAssetDownload %@",asset.userInfo);
            [asset downloadWithDelegate:self.newsstandDownloader];

        }
    }
    
}


@end
