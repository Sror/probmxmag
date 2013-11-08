//
//  MainViewController.m
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "MainViewController.h"
#import "HeaderImageView.h"
#import "IssueCell.h"
#define PublisherErrorMessage @"Cannot get issues from publisher server. Try to refresh again."
#define TITLE_NAVBAR @"Выпуски"

//#import "MFDocumentViewController.h"
#import "ReaderViewController.h"
//#import "DocumentViewController.h" //?

@class MFDocumentManager;

@interface MainViewController () {
    BOOL isIpad;
    BOOL isIos7;
    BOOL isRetina;
}

@end

@implementation MainViewController
@synthesize headerImageView;


- (void)viewDidLoad
{
    [super viewDidLoad];
    isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    isIos7 = [[[UIDevice currentDevice] systemVersion]floatValue]>= 7.0;
    isRetina =[[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);
    if (isRetina) {
        NSLog(@"Retina display");
    }else{
        NSLog(@"non-Retina display");
    }
    //delegates and instances
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    publisher = [Publisher sharedInstance];
    newsstandDownloader = [NewsstandDownloader sharedInstance];
    newsstandDownloader = [[NewsstandDownloader alloc] initWithPublisher:publisher];
    newsstandDownloader.delegate = self;
    
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    
    // set settings bar button
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings.png"]
                                                                       style:UIBarButtonItemStyleBordered target:self
                                                                      action:@selector(changeSettings)];
    [self.navigationItem setLeftBarButtonItem:settingsButton];
    
    //set refresh button
    UIBarButtonItem *refreshButton=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadIssues)];
    
    [self.navigationItem setRightBarButtonItem:refreshButton];
    //set background
	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    //set header view
   
    [self loadIssues];
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadIssues{
    self.navigationItem.title = @"Loading...";
    self.collectionView.alpha = 0.0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:PublisherDidUpdate object:publisher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:PublisherFailedUpdate object:publisher];
    
    [publisher getIssuesList];
}
-(void)publisherReady:(NSNotification *)not {
    NSLog(@"publisherReady, so we will remove observer and show issues");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdate object:publisher];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdate object:publisher];
    [self showIssues];
    [self loadHeader];
}
-(void)publisherFailed:(NSNotification *)not {
    NSLog(@"publisherFailed");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdate object:publisher];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdate object:publisher];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                    message:PublisherErrorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}
-(void)changeSettings{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Настройки"
                                                             delegate:self
                                                    cancelButtonTitle:@"Отмена"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Бесплатная подписка",@"Восстановить покупки", @"Удалить все выпуски",nil];
    
    
    [actionSheet showInView:self.view];
}


-(void)showIssues {
    self.navigationItem.title = TITLE_NAVBAR;
    self.collectionView.alpha = 1.0;
    [self.collectionView reloadData];
    [self.headerImageView setNeedsDisplay];
}
-(void)loadHeader{
    
    UIImage *headerImage=[publisher headerImageForIssueAtIndex:0 forRetina:isRetina];
    if(headerImage){
        NSLog(@"set header from local image");
        [self.headerImageView.activityIndicator stopAnimating];
        [self.headerImageView setImage:headerImage];
    }else{
        [self.headerImageView setImage:nil];
        [self.headerImageView.activityIndicator startAnimating];
        NSLog(@"start downloading header image");
#warning weakSelf in block
        __weak HeaderImageView *self_ = self.headerImageView;
       [publisher setHeaderImageOfIssueAtIndex:0 forRetina:isRetina completionBlock:^(UIImage*img)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"header downloaded and written");
                [self_.activityIndicator stopAnimating];
                [self_ setImage:img];
            });
        }];
        
    }

}
-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [publisher numberOfIssues ];
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IssueCell *cell=(IssueCell*)[cv dequeueReusableCellWithReuseIdentifier:@"IssueCell" forIndexPath:indexPath];
    cell.backgroundColor =[UIColor clearColor];
    //cell.layer.borderWidth = 1.0;
    
    NKLibrary *nkLib=[NKLibrary sharedLibrary];
    NKIssue *issue=[nkLib issueWithName:[publisher nameOfIssueAtIndex:indexPath.row]];
    [cell updateCellInformationWithStatus:issue.status];
    
    NSString *titleOfIssue=[publisher titleOfIssueAtIndex:indexPath.row];
    cell.issueTitle.text = titleOfIssue;
    NSString *description =[publisher issueDescriptionAtIndex:indexPath.row];
    description = [description stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    cell.textView.backgroundColor = [UIColor clearColor];
    
    cell.textView.text = description;
    [cell.downloadOrShowButton setTag:indexPath.row];
    [cell.downloadOrShowButton addTarget:self action:@selector(cellButtonPressed:)
                        forControlEvents:UIControlEventTouchUpInside];
    UIImage *coverImage=[publisher coverImageForIssueAtIndex:indexPath.row retina:isRetina];
    if(coverImage){
        [cell.imageView setImage:coverImage];
        [cell.activityIndicator stopAnimating];
    }else{
        [cell.imageView setImage:nil];
        [cell.activityIndicator startAnimating];
        [publisher setCoverOfIssueAtIndex:indexPath.row forRetina:isRetina completionBlock:^(UIImage*img){
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.activityIndicator stopAnimating];
                [cell.imageView setImage:img];
            });
        }];
    }

    return cell;
}
#pragma mark - UIButton cell delegate
-(void)cellButtonPressed:(id)sender{
    int row = [sender tag];
    [self showOrDownloadIssueAtIndex:row];
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //IssueCell *cell=(IssueCell*)[cv dequeueReusableCellWithReuseIdentifier:@"IssueCell" forIndexPath:indexPath];
    [cv deselectItemAtIndexPath:indexPath animated:YES];
    [self showOrDownloadIssueAtIndex:indexPath.row];
   
}
-(void)showOrDownloadIssueAtIndex:(int)index{
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:[publisher nameOfIssueAtIndex:index]];
    if(nkIssue.status==NKIssueContentStatusAvailable) {
        NSLog(@"open issue at index %d",index);
        [self openIssueinFastPdfReader:nkIssue];
    } else if(nkIssue.status==NKIssueContentStatusNone) {
        NSLog(@"download issue at index %d",index);
        [self downloadIssueAtIndex:index];
    }
    else if(nkIssue.status ==NKIssueContentStatusDownloading){
        NSLog(@"Issue already downloading");
        //TODO pause downloading
        
    }
}
-(void)downloadIssueAtIndex:(NSInteger)index {
    [newsstandDownloader downloadIssueAtIndex:index];
    IssueCell* tile = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [tile updateCellInformationWithStatus:NKIssueContentStatusDownloading];
}
#pragma  mark - OpenIssue in FastPdfKitReader
-(void)openIssueinFastPdfReader:(NKIssue*)issue
{
    [[NKLibrary sharedLibrary] setCurrentlyReadingIssue:issue];
    NSString *documentName=[issue.name stringByAppendingString:@".pdf"];
    NSURL *documentURL = [NSURL fileURLWithPath:[[issue.contentURL path] stringByAppendingPathComponent:documentName]];
    NSLog(@"document URL = %@",documentURL);

    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *thumbnailsPath = [[documentURL path] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",documentName]];
    
    MFDocumentManager *documentManager = [[MFDocumentManager alloc]initWithFileUrl:documentURL];
    ReaderViewController *pdfViewController = [[ReaderViewController alloc]initWithDocumentManager:documentManager];
    [pdfViewController setDocumentDelegate:pdfViewController];
    pdfViewController.fpkAnnotationsEnabled = YES;
    documentManager.resourceFolder = thumbnailsPath;
    pdfViewController.documentId = documentName;
    
    [self presentViewController:pdfViewController animated:YES completion:nil];
    
}
#pragma mark - 
-(BOOL)shouldAutorotate
{
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (isIpad )
    {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            NSLog(@"willRotate to landscape");
            
            if (isIos7)
            {
                //header image size is 1024 x 282
                //navBar+statusBar = 64
                self.view.frame =CGRectMake(0, 0, 1024, 768);
                self.headerImageView.frame = CGRectMake(0, 64, 1024, 255);
                self.collectionView.frame = CGRectMake(0, 255+64, 1024, 768-64-255);
            }else{
                //ios 6 landscape
                self.view.frame =CGRectMake(0, 44+20, 1024, 768-44-20);
                self.headerImageView.frame = CGRectMake(0, 0, 1024, 255);
                self.collectionView.frame = CGRectMake(0, 255, 1024, 768-44-20-255);
            }
            //TODO header center point
            self.headerImageView.activityIndicator.center = self.headerImageView.center;
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 80, 10, 80)];
            [self.collectionViewFlowlayout setMinimumLineSpacing:18.0];
        }else{
            //portrait orientation
            NSLog(@"willRotate to portrait mode");
            if (isIos7) {
                self.view.frame = CGRectMake(0, 0, 768, 1024);
                self.headerImageView.frame = CGRectMake(-128, 64, 1024, 255);
                self.collectionView.frame =CGRectMake(0, 255+64, 768, 1024-64-255);
            }else{
                //ios 6 portrait
                //status bar 20 px
                self.view.frame = CGRectMake(0, 44+20, 768, 1024-44-20);
                self.headerImageView.frame = CGRectMake(-128.0, 0.0, 1024.0, 255.0);
                self.collectionView.frame = CGRectMake(0, 255, 768, 1024-44-20-255);
            }
            self.headerImageView.activityIndicator.center = self.headerImageView.center;
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 10, 10, 10)];
            [self.collectionViewFlowlayout setMinimumLineSpacing:18.0];
         
        }
    }else{
        //to do iphone implementation
        
    }
}

#pragma mark - NewsstandDownloaderDelegate methods

-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    NKAssetDownload *dnl = connection.newsstandAssetDownload;
    int tileIndex = [[dnl.userInfo objectForKey:@"Index"] intValue];
    IssueCell* cell = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:tileIndex inSection:0]];
    cell.progressView.progress=1.f*totalBytesWritten/expectedTotalBytes;
    // NSLog(@"Downloading progress: %f",1.f*totalBytesWritten/expectedTotalBytes);
    [cell.imageView setAlpha:0.5f+0.5f*totalBytesWritten/expectedTotalBytes];
    [cell updateCellInformationWithStatus:NKIssueContentStatusDownloading];
}


-(void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    
    if ([[UIApplication sharedApplication]applicationState]==UIApplicationStateActive) {
        [self updateProgressOfConnection:connection withTotalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
    }else{
        NSLog(@"App is backgrounded");
    }
    
}

-(void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    NSLog(@"Resume downloading %f",1.f*totalBytesWritten/expectedTotalBytes);
    [self updateProgressOfConnection:connection withTotalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
}

-(void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
    // copy file to destination URL
    
    NSLog(@"connection:(NSURLConnection *)connectionDidFinishDownloading");
    [self.collectionView reloadData];
    
    if (!UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        NSLog(@"App is backgrounded. Download finished");
        //TODO
    }
    
}
#pragma mark - IssueCellDelegate

-(void)trashContent {
    NSLog(@"trashContent method implementation");
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NSLog(@"nkLib.issues= %@",nkLib.issues);
    [nkLib.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [nkLib removeIssue:(NKIssue *)obj];
    }];
    [publisher addIssuesInNewsstandLibrary];
    [self.collectionView reloadData];
}

#pragma mark- UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"actionSheet clickedButtonAtIndex %d",buttonIndex);
    /*
    if (buttonIndex==0 || buttonIndex==1) {
        //purchase
        StoreManager *storeManager=[AppDelegate instance].storeManager;
        [storeManager subscribeToMagazine];
    }
    */
    if (buttonIndex==2) {
        [self trashContent];
    }
}
@end
