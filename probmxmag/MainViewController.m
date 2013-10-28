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
@interface MainViewController () {
    BOOL isIpad;
}

@end

@implementation MainViewController
@synthesize headerImageView;


- (void)viewDidLoad
{
    [super viewDidLoad];
    isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    //delegates and instances
    publisher = [Publisher sharedInstance];
    newsstandDownloader = [NewsstandDownloader sharedInstance];
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
}
-(void)publisherFailed:(NSNotification *)not {
    NSLog(@"publisherFailed");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdate object:publisher];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdate object:publisher];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                    message:PublisherErrorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}
-(void)showIssues {
    self.navigationItem.title = TITLE_NAVBAR;
    self.collectionView.alpha = 1.0;
    [self.collectionView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 10;
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IssueCell *cell=(IssueCell*)[cv dequeueReusableCellWithReuseIdentifier:@"IssueCell" forIndexPath:indexPath];
    cell.backgroundColor =[UIColor clearColor];
    cell.layer.borderWidth = 1.0;
    
    NKLibrary *nkLib=[NKLibrary sharedLibrary];
    NKIssue *issue=[nkLib issueWithName:[publisher nameOfIssueAtIndex:indexPath.row]];
    [cell updateCellInformationWithStatus:issue.status];
    
    NSString *titleOfIssue=[publisher titleOfIssueAtIndex:indexPath.row];
    cell.issueTitle.text = titleOfIssue;
    NSString *description =[publisher issueDescriptionAtIndex:indexPath.row];
    cell.textView.text = description;
    
    UIImage *coverImage=[publisher coverImageForIssueAtIndex:indexPath.row];
    if(coverImage){
        [cell.imageView setImage:coverImage];
        [cell.activityIndicator stopAnimating];
    }else{
        [cell.imageView setImage:nil];
        [cell.activityIndicator startAnimating];
        [publisher setCoverOfIssueAtIndex:indexPath.row completionBlock:^(UIImage*img){
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.activityIndicator stopAnimating];
                [cell.imageView setImage:img];
            });
        }];
    }

    return cell;
}




#pragma mark - 
-(BOOL)shouldAutorotate{
    return YES;
}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (isIpad)
    {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            NSLog(@"willRotate to landscape");
            self.view.frame =CGRectMake(0, 0, 1024, 768);
            self.headerImageView.frame = CGRectMake(0, 64, 1024, 255);
            //TODO header center point
            self.headerImageView.activityIndicator.center = self.headerImageView.center;
            self.collectionView.frame = CGRectMake(0, 319, 1024, 449);
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 80, 10, 80)];
            
        }else{
            NSLog(@"willRotate to portrait mode");
            self.view.frame = CGRectMake(0, 0, 768, 1024);
            self.headerImageView.frame = CGRectMake(-128, 64, 1024, 255);
            self.headerImageView.activityIndicator.center = self.headerImageView.center;
            CGFloat center = self.headerImageView.frame.size.width/2;
            NSLog(@"center %f",center);
            
            
            self.collectionView.frame =CGRectMake(0, 319, 768, 705);
            [self.collectionViewFlowlayout setSectionInset:UIEdgeInsetsMake(10, 10, 10, 10)];
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
@end
