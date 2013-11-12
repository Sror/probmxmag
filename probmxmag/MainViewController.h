//
//  MainViewController.h
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HeaderImageView.h"
#import "Publisher.h"
#import "NewsstandDownloader.h"
#import "AppDelegate.h"
#import "StoreManager.h"

@interface MainViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIActionSheetDelegate,NewsstandDownloaderDelegate,StoreManagerDelegate>
{
    Publisher *publisher;
    NewsstandDownloader *newsstandDownloader;
    
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *collectionViewFlowlayout;
@property (weak, nonatomic) IBOutlet HeaderImageView *headerImageView;
@end
