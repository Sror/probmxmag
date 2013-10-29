//
//  NewsstandDownloader.m
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 29.09.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "NewsstandDownloader.h"
#import "Publisher.h"
#import "SSZipArchive.h"

#define kPostNotificationReceived @"com.yourkioskapp.newsstand.template.NewsstandTemplate.notificationReceived"

@implementation NewsstandDownloader

@synthesize delegate;
@synthesize publisher;
+(NewsstandDownloader*)sharedInstance{
    static dispatch_once_t once;
    static NewsstandDownloader *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance =[[self alloc]init];
    });
    return sharedInstance;
}
/*
-(id)initWithPublisher:(Publisher*)thePublisher
{
    self = [super init];
    
    if(self)
    {
        self.publisher = thePublisher;
        
     //   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myhandleNotification:) name:kPostNotificationReceived object:nil];
    }
    
    return self;
}
 */
/*
-(void)myhandleNotification:(NSNotification*)notification
{
    NSLog(@"myhandleNotification in newsstandDownloader : %@", notification);
    
    [self fetchContent];
}
 */
/*
-(void)fetchContent{
    NSLog(@"fetching content from remote notification");
    [publisher getIssuesListSynchronous];
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];

    //download latest issue
    //was    NKIssue *nkIssue = [nkLib issueWithName:[publisher nameOfIssueAtIndex:numberOfIssues - 1]];
    NKIssue *nkIssue=[nkLib issueWithName:[publisher nameOfIssueAtIndex:0]];
    
    if([nkIssue status] == NKIssueContentStatusNone)
    {
        [self downloadIssueAtIndex:0];
    }
}
*/

-(void)downloadIssueAtIndex:(NSInteger)index {
    NSLog(@"NewsstandDownloader downloadIssueAtIndex %d",index);
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NSString* issueName = [publisher nameOfIssueAtIndex:index];
    NKIssue *nkIssue = [nkLib issueWithName:issueName];
    
    NSURL *downloadURL = [publisher contentURLForIssueWithName:nkIssue.name];
    
    if(!downloadURL) return;
    
    NSURLRequest *req = [NSURLRequest requestWithURL:downloadURL];
    NKAssetDownload *assetDownload = [nkIssue addAssetWithRequest:req];
    [assetDownload downloadWithDelegate:self];
    [assetDownload setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:index],@"Index",
                                nil]];
}


#pragma mark -

-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    
    [delegate updateProgressOfConnection:connection withTotalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
}


- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes
{
    //NSLog(@"connection:(NSURLConnection *)connection didWriteData");
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [delegate connection:connection didWriteData:bytesWritten totalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes
{
    NSLog(@"connection:(NSURLConnection *)connectionDidResumeDownloading");
    
    [delegate connectionDidResumeDownloading:connection totalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
    
}


- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *) destinationURL
{
    NSLog(@"connectionDidFinishDownloading file to %@",destinationURL);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    NKAssetDownload *asset = [connection newsstandAssetDownload];
    NSURL* fileURL = [[asset issue] contentURL];
   
    NSString *fileSuffix = nil;
    if ([[destinationURL absoluteString]hasSuffix:@"zip"]) {
        fileSuffix = @"zip";
        NSLog(@"Zip file suffix founded!");
    }
    
    NSLog(@"unZippingFile from %@ to %@ ",[destinationURL path],[fileURL path]);
    
    if (![SSZipArchive unzipFileAtPath:[destinationURL path] toDestination:[fileURL path]]) {
        NSLog(@"error to unzip file!");
    }
    //remove downloaded zip file
    NSError *removingError;
    [[NSFileManager defaultManager] removeItemAtPath:[destinationURL path] error:&removingError];
    if (removingError) {
        NSLog(@"Error to remove file:%@",removingError.localizedDescription);
    }else{
        NSLog(@"success removing file");
    }
    // update the Newsstand icon
    int index=[self.publisher indexOfIssue:[asset issue]];
    [self.publisher setCoverOfIssueAtIndex:index completionBlock:^(UIImage *img) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNewsstandIconImage:img];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        });
    }];
    
   // [self updateIssueIconWithImage:[publisher coverImageForIssue:[asset issue]]];
    
    [delegate connectionDidFinishDownloading:connection destinationURL:destinationURL];
    
}

-(void)updateIssueIconWithImage:(UIImage*)coverImage{
    if (coverImage) {
        NSLog(@"setting new newsstand icon");
        [[UIApplication sharedApplication] setNewsstandIconImage:coverImage];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    }
}

@end

