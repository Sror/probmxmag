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
#import <Parse/Parse.h>

#define kPostNotificationReceived @"com.yourkioskapp.probmxmag.notificationReceived"

@implementation NewsstandDownloader
@synthesize publisher;
@synthesize delegate;
//@synthesize publisher;


-(id)initWithPublisher:(Publisher*)thePublisher
{
    self = [super init];
    
    if(self)
    {
        self.publisher = thePublisher;
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kPostNotificationReceived object:nil];
    }
    
    return self;
}


-(void)handleNotification:(NSNotification*)notification
{
    NSLog(@"myhandleNotification in newsstandDownloader : %@", notification);
    
   // [self fetchContent];
}


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
                                [NSNumber numberWithInt:index],@"Index",issueName,@"issueName",
                                nil]];
}


-(void)removeZipFileFrom:(NSString*)path{
    NSError *removingError;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&removingError];
    if (removingError) {
        NSLog(@"Error to remove file:%@",removingError.localizedDescription);
    }else{
        NSLog(@"success removing file %@", path);
    }
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
    NSString *issueName = [asset issue].name;
    NSString *fileName= [issueName stringByAppendingString:@".pdf"];
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.yourkioskapp.probmxmag.unzipQueue",nil);
    
    
    //.PDF issue file
    if ([[destinationURL absoluteString] hasSuffix:@"pdf"]) {
        NSError *error;
        NSLog(@"PDF file suffix found");
        [[NSFileManager defaultManager] moveItemAtPath:[destinationURL path] toPath:[[fileURL path] stringByAppendingPathComponent:fileName] error:&error];
        if (error) {
            NSLog(@"error to move pdf file: %@",error.localizedDescription);
        }
        [delegate connectionDidFinishDownloading:connection destinationURL:destinationURL];
    }

    // .ZIP issue file
    if ([[destinationURL absoluteString] hasSuffix:@"zip"])
    {
        NSLog(@"ZIP file suffix found!");
        dispatch_async(queue, ^{
            NSLog(@"unZippingFile from %@ to %@ ",[destinationURL path],[fileURL path]);
            [SSZipArchive unzipFileAtPath:[destinationURL path] toDestination:[fileURL path]];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"unzip success in block");
                NSError *error;
                NSArray *files= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[fileURL path] error:&error];
                NSLog(@"files in destinationPath %@",files );
                
                [self removeZipFileFrom:[destinationURL path]];
                [delegate connectionDidFinishDownloading:connection destinationURL:destinationURL];
            });
        });
    }
    
    NSDictionary*dimensions=@{@"file":[[destinationURL absoluteString]lastPathComponent],
                              @"issueName": issueName}; //parse framework analytic dimension
    [PFAnalytics trackEvent:@"finish downloading" dimensions:dimensions];
   
    
}

-(void)updateIssueIconWithImage:(UIImage*)coverImage{
    if (coverImage) {
        NSLog(@"setting new newsstand icon");
        [[UIApplication sharedApplication] setNewsstandIconImage:coverImage];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    }
}

@end


