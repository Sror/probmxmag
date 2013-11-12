//
//  AppDelegate.h
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoreManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) StoreManager *storeManager;

+(AppDelegate*)instance;

@end
