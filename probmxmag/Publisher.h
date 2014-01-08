//
//  Publisher.h
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 27.09.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NewsstandKit/NewsstandKit.h>

extern  NSString *PublisherDidUpdate;
extern  NSString *PublisherFailedUpdate;
extern  NSString *PublisherMustUpdateIssueList;
//extern  NSString *XMLNAFLocation;

@interface Publisher : NSObject

@property (nonatomic, strong) NSArray *issues;
@property (nonatomic,readonly,getter = isReady) BOOL ready;

+(Publisher*)sharedInstance;

-(void)addIssuesInNewsstandLibrary;
-(void)getIssuesList;
-(void)getIssuesListSynchronous;

-(NSInteger)numberOfIssues;
-(NSInteger)indexOfIssue:(NKIssue*)issue;
-(NSString *)nameOfIssueAtIndex:(NSInteger)index;
-(NSString *)titleOfIssueAtIndex:(NSInteger)index;
-(UIImage *)coverImageForIssueAtIndex:(NSInteger)index retina:(BOOL)isRetina;
-(NSString*)issueDescriptionAtIndex:(NSInteger)index;
-(void)setCoverOfIssueAtIndex:(NSInteger)index forRetina:(BOOL)isRetina  completionBlock:(void(^)(UIImage *img))block ;
-(NSURL *)contentURLForIssueWithName:(NSString *)name;

//-(UIImage *)coverImageForIssue:(NKIssue *)nkIssue;

-(UIImage*)headerImageForIssueAtIndex:(NSInteger)index forRetina:(BOOL)isRetina;
-(void)setHeaderImageOfIssueAtIndex:(NSUInteger)index forRetina:(BOOL)isRetina completionBlock:(void(^)(UIImage *img))block;

@end
