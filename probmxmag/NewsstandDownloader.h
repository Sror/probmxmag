//
//  NewsstandDownloader.h
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 29.09.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NewsstandKit/NewsstandKit.h>

#import "Publisher.h"


@protocol NewsstandDownloaderDelegate;

@interface NewsstandDownloader : NSObject <NSURLConnectionDownloadDelegate>



-(id)initWithPublisher:(Publisher*)thePublisher;

-(void)handleNotification:(NSNotification*)notification;

//-(void)fetchContent;

@property (nonatomic, assign) id<NewsstandDownloaderDelegate> delegate;
@property (nonatomic, strong) Publisher* publisher;

-(void)downloadIssueAtIndex:(NSInteger)index;
-(void)updateIssueIconWithImage:(UIImage*)coverImage;

@end

@protocol NewsstandDownloaderDelegate <NSObject>

-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes;

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes;

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes;


- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *) destinationURL;


@end