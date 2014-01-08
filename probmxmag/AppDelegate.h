//
//  AppDelegate.h
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoreManager.h"
#import <NewsstandKit/NewsstandKit.h>
#import "Publisher.h"
#import "NewsstandDownloader.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    BOOL isSubscribed;
    
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong) Publisher *publisher;
@property (nonatomic, strong) NewsstandDownloader * newsstandDownloader;
@property (nonatomic, strong) StoreManager *storeManager;


+(AppDelegate*)instance;

@end
