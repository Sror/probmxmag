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
#import "Reachability.h"
#import "OverlayManager.h"
#import "ReaderViewController.h"
#import <Parse/Parse.h>
#define PublisherErrorMessage @"Нет доступа к серверу. Проверьте подключение к интернету."
#define TITLE_NAVBAR @"Выпуски"
#define CacheDirectory [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]



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
    self.publisher = [[AppDelegate instance] publisher];
    
    newsstandDownloader= [[AppDelegate instance] newsstandDownloader];
    [newsstandDownloader setDelegate:self];
    
    StoreManager *storeManager = [AppDelegate instance].storeManager;
    [storeManager setDelegate:self];
    
    if ([storeManager isSubscribed]) {
        NSLog(@"already subscribed!");
    }else{
        NSLog(@"not subscribed!");
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadIssues) name:PublisherMustUpdateIssueList object:self];
   
    //Have to set UICollectionViewFlow layout when loaded and changing orientation
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:5];
    
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
    [self loadIssues];
   
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadIssues{
    
    self.navigationItem.title = @"Загрузка...";
    self.collectionView.alpha = 0.0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:PublisherDidUpdate object:self.publisher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:PublisherFailedUpdate object:self.publisher];
    
    [self.publisher getIssuesList];
}

-(void)publisherReady:(NSNotification *)not {
    NSLog(@"publisherReady, so we will remove observer and show issues");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdate object:self.publisher];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdate object:self.publisher];
    [self showIssues];
    [self loadHeader];
}

-(void)publisherFailed:(NSNotification *)not {
    NSLog(@"publisherFailed");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdate object:self.publisher];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdate object:self.publisher];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка!"
                                                    message:PublisherErrorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)changeSettings{
    //TODO
    // if allready rated then dont show rate app
    NSArray *buttons=nil;
    if ([self userHasRatedCurrentVersion]) {
        
        buttons = @[@"Бесплатная подписка",@"Восстановить подписку", @"Удалить все выпуски"];
    }else{
        NSLog(@"user don't rate app");
        buttons = @[@"Оценить probmxmag", @"Бесплатная подписка",@"Восстановить подписку", @"Удалить все выпуски"];
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Настройки"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    for (NSString *buttonTitle in buttons) {
        [actionSheet addButtonWithTitle:buttonTitle];
    }
    [actionSheet addButtonWithTitle:@"Отмена"];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
    
    [actionSheet showInView:self.view];
}


-(void)showIssues {
    self.navigationItem.title = TITLE_NAVBAR;
    self.collectionView.alpha = 1.0;
    [self.collectionView reloadData];
    [self.headerImageView setNeedsDisplay];
}


-(void)loadHeader{
    
    UIImage *headerImage=[self.publisher headerImageForIssueAtIndex:0 forRetina:isRetina];
    if(headerImage){
        NSLog(@"set header from local image");
        [self.headerImageView.activityIndicator stopAnimating];
        [self.headerImageView setImage:headerImage];
    }else{
        [self.headerImageView setImage:nil];
        [self.headerImageView.activityIndicator startAnimating];
        __weak HeaderImageView *self_ = self.headerImageView;
       [self.publisher setHeaderImageOfIssueAtIndex:0 forRetina:isRetina completionBlock:^(UIImage*img)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self_.activityIndicator stopAnimating];
                [self_ setImage:img];
            });
        }];
    }
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.publisher numberOfIssues ];
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IssueCell *cell=(IssueCell*)[cv dequeueReusableCellWithReuseIdentifier:@"IssueCell" forIndexPath:indexPath];
    cell.backgroundColor =[UIColor clearColor];
    //cell.layer.borderWidth = 1.0;
    
    NKLibrary *nkLib=[NKLibrary sharedLibrary];
    NKIssue *issue=[nkLib issueWithName:[self.publisher nameOfIssueAtIndex:indexPath.row]];
    [cell updateCellInformationWithStatus:issue.status];
    
    NSString *titleOfIssue=[self.publisher titleOfIssueAtIndex:indexPath.row];
    cell.issueTitle.text = titleOfIssue;
    NSString *description =[self.publisher issueDescriptionAtIndex:indexPath.row];
    description = [description stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    cell.textView.backgroundColor = [UIColor clearColor];
    cell.textView.text = description;
    
    [cell.downloadOrShowButton setTag:indexPath.row];
    [cell.downloadOrShowButton addTarget:self action:@selector(cellButtonPressed:)
                        forControlEvents:UIControlEventTouchUpInside];
    [cell.delButton setTag:indexPath.row];
    
    [cell.delButton addTarget:self action:@selector(delButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    //cover image
    UIImage *coverImage=[self.publisher coverImageForIssueAtIndex:indexPath.row retina:isRetina];
    if(coverImage){
        [cell.imageView setImage:coverImage];
        [cell.activityIndicator stopAnimating];
        [cell.imageView setTag:indexPath.row];
    }else{
        [cell.imageView setImage:nil];
        [cell.activityIndicator startAnimating];
        [self.publisher setCoverOfIssueAtIndex:indexPath.row forRetina:isRetina completionBlock:^(UIImage*img){
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.activityIndicator stopAnimating];
                [cell.imageView setImage:img];
                [cell.imageView setTag:indexPath.row];
            });
        }];
    }
    if (issue.status == NKIssueContentStatusDownloading) {
        [cell.circularProgressView setAlpha:1.0];
    }
    return cell;
}

#pragma mark - remove thumbnail
-(void)removeThumbnailFolderOfIssue:(NKIssue*)issue{
    NSString* path = [CacheDirectory stringByAppendingPathComponent:[issue.name stringByAppendingString:@".pdf"]];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"error to remove: %@",error.localizedDescription);
    }
}

#pragma mark - UIButton cell delegate
-(void)cellButtonPressed:(id)sender{
    int row = [sender tag];
    [self showOrDownloadIssueAtIndex:row];
}

#pragma mark - del button delegate
-(void)delButtonPressed:(id)sender {
    int row = [sender tag];
    [self removeIssueAtIndex:row];
}

-(void)removeIssueAtIndex:(int)index{
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:[self.publisher nameOfIssueAtIndex:index]];
    [nkLib removeIssue:nkIssue];
    IssueCell* tile = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [tile updateCellInformationWithStatus:nkIssue.status];
    [self removeThumbnailFolderOfIssue:nkIssue];
}
-(void)showOrDownloadIssueAtIndex:(int)index{
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:[self.publisher nameOfIssueAtIndex:index]];
    if(nkIssue.status==NKIssueContentStatusAvailable) {
        [self openIssueinFastPdfReader:nkIssue];
    } else if(nkIssue.status==NKIssueContentStatusNone) {
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        if (netStatus == NotReachable) {
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Проверьте интернет подключение" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }else if (netStatus == ReachableViaWiFi)
        {
            [self downloadIssueAtIndex:index];
        }else if (netStatus == ReachableViaWWAN){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Внимание!" message:@"Для загрузки выпусков рекомендуется использовать WiFi соединение (стоимость зависит от тарифов сот. оператора." delegate:self cancelButtonTitle:@"Продолжить" otherButtonTitles:@"Отменить", nil];
            alert.tag = index;
            [alert show];
        }
  
    }
    else if(nkIssue.status == NKIssueContentStatusDownloading){
        NSLog(@"Issue already downloading");
        //TODO cancel downloading
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [nkLib removeIssue:nkIssue];
        [self.publisher addIssuesInNewsstandLibrary];
        IssueCell* tile = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [tile updateCellInformationWithStatus:NKIssueContentStatusNone];
    }
}
-(void)downloadIssueAtIndex:(NSInteger)index
{
    [newsstandDownloader downloadIssueAtIndex:index];
    IssueCell* tile = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [tile.circularProgressView setAlpha:1.0];
    [tile.circularProgressView startSpinProgressBackgroundLayer];
    [tile updateCellInformationWithStatus:NKIssueContentStatusDownloading];
}

#pragma  mark - OpenIssue in FastPdfKitReader
-(void)openIssueinFastPdfReader:(NKIssue*)issue
{
    [[NKLibrary sharedLibrary] setCurrentlyReadingIssue:issue];
    NSString *documentName=[issue.name stringByAppendingString:@".pdf"];
    NSURL *documentURL = [NSURL fileURLWithPath:[[issue.contentURL path] stringByAppendingPathComponent:documentName]];
    NSString* resourceFolder = [issue.contentURL path];
    MFDocumentManager *documentManager = [[MFDocumentManager alloc]
                                          initWithFileUrl:documentURL];
    ReaderViewController *pdfViewController = [[ReaderViewController alloc]
                                               initWithDocumentManager:documentManager];
    [pdfViewController setThumbnailSliderEnabled:YES];
    documentManager.resourceFolder = resourceFolder;
    pdfViewController.documentId = documentName;
    OverlayManager *_overlayManager = [[OverlayManager alloc] init] ;
    /** Add the FPKOverlayManager as OverlayViewDataSource to the ReaderViewController */
    [pdfViewController addOverlayViewDataSource:_overlayManager];
    /** Register as DocumentDelegate to receive tap */
    [pdfViewController addDocumentDelegate:_overlayManager];
    /** Set the DocumentViewController to obtain access the the conversion methods */
    [_overlayManager setDocumentViewController:(MFDocumentViewController <FPKOverlayManagerDelegate> *)pdfViewController];
    NSDictionary *dimensions= @{@"documentName": documentName}; //<-parse framework analytic dimensions
    [pdfViewController setDismissBlock:^{
        [Appirater userDidSignificantEvent:YES];
        NSLog(@"user did close reader so we will add user did sugnificant event");
        [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication]statusBarOrientation] duration:0];
        
        [PFAnalytics trackEvent:@"will close pdf" dimensions:dimensions];
        [self dismissViewControllerAnimated:YES completion:Nil];
    }];
    [PFAnalytics trackEvent:@"will open pdf" dimensions:dimensions];
    [self presentViewController:pdfViewController animated:YES completion:nil];
}

#pragma mark - Orientations
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (isIpad)
    {
        NSLog(@"willRotateToInterfaceOrientation");
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 80, 10, 80)];
        }else {
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 10, 10, 10)];
        }
    }else{
        NSLog(@"willRotate iphone");
    }
}

#pragma mark - NewsstandDownloaderDelegate methods
-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    NKAssetDownload *dnl = connection.newsstandAssetDownload;
    int tileIndex = [[dnl.userInfo objectForKey:@"Index"] intValue];
    IssueCell* cell = (IssueCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:tileIndex inSection:0]];
    
    cell.circularProgressView.progress = 1.f*totalBytesWritten/expectedTotalBytes;
    [cell.imageView setAlpha:0.5f+0.5f*totalBytesWritten/expectedTotalBytes];
    [cell updateCellInformationWithStatus:NKIssueContentStatusDownloading];
}

-(void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
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
    NSLog(@"remove all issues");
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    for (NKIssue *issue in nkLib.issues) {
        [self removeThumbnailFolderOfIssue:issue];
    }
    [nkLib.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [nkLib removeIssue:(NKIssue *)obj];
    }];
    [self.publisher addIssuesInNewsstandLibrary];
    [self.collectionView reloadData];
}

#pragma mark - StoreManagerDelegate
-(void)subscriptionCompletedWith:(BOOL)success{
    if (success) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Спасибо" message:@"Подписка оформлена!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [PFAnalytics trackEvent:@"subscribed"];
    }
}

#pragma mark- UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([self userHasRatedCurrentVersion])
    {
        switch (buttonIndex) {
            case 0:
            case 1:
            {
                //subscribe to magazine
                StoreManager *storeManager=[AppDelegate instance].storeManager;
                if ([storeManager isSubscribed]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Внимание" message:@"Бесплатная подписка уже была оформленна." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                    
                }else{
                    [storeManager subscribeToMagazine];
                }
            }
                break;
            case 2:
            {
              [self trashContent];
            }
                break;
            default:
                break;
        }
    }else{
        switch (buttonIndex) {
            case 0:
            {
                //rate app
                [Appirater rateApp];
               
                [PFAnalytics trackEvent:@"rateApp" ];
            }
                break;
            case 1:
            case 2:
            {
                //subscribe to magazine
                StoreManager *storeManager=[AppDelegate instance].storeManager;
                if ([storeManager isSubscribed]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Внимание" message:@"Бесплатная подписка уже была оформленна." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                    
                }else{
                    [storeManager subscribeToMagazine];
                }
            }
                break;
            case 3:
            {
                //remove all content
                [self trashContent];
            }
                break;
            default:
                break;
        }
    }
  
}
#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag >= 0) {
        if (buttonIndex ==0) {
            [self downloadIssueAtIndex:alertView.tag];
        }
    }
}

- (BOOL)userHasRatedCurrentVersion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAppiraterRatedCurrentVersion];
}

@end
