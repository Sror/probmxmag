//
//  Publisher.m
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 27.09.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "Publisher.h"
#import <NewsstandKit/NewsstandKit.h>
#import "Reachability.h"
#import "XMLParser.h"

//test for JSON//
//#import "Constants.h"

#define CacheDirectory [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

NSString *PublisherDidUpdate = @"PublisherDidUpdate";
NSString *PublisherFailedUpdate = @"PublisherFailedUpdate";
NSString *PublisherMustUpdateIssueList =  @"PublisherMustUpdateIssueList";


//NSString *XMLIssuesLocationIpad = @"https://googledrive.com/host/0B6E2Hn-m7yvANE95XzhNY2FVRm8/issues_ipad.xml";
//NSString *XMLIssuesLocationIphone = @"https://googledrive.com/host/0B6E2Hn-m7yvANE95XzhNY2FVRm8/issues_iphone.xml";

NSString *XMLIssuesLocationIpad = @"http://probmxmag.ru/probmxmagapp/issues_ipad.xml";
NSString *XMLIssuesLocationIphone = @"http://probmxmag.ru/probmxmagapp/issues_iphone.xml";


@implementation Publisher
@synthesize ready;

+(Publisher*)sharedInstance {
    static dispatch_once_t once;
    static Publisher *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance =[[self alloc]init];
    });
    
    return sharedInstance;
}

-(id)init {
    self = [super init];
    if(self) {
        ready = NO;
        self.issues = nil;
    }
    return self;
}


-(NSString*)getIssuesLocation {
    
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? XMLIssuesLocationIpad : XMLIssuesLocationIphone;
}


-(void)getIssuesList {
    NSLog(@"publisher get issues list");
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    //Without internet connection implementation
    if (networkStatus == NotReachable)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSLog(@"networkStatus is NOT reachable");
        NSString* cachedIssuesName = [CacheDirectory stringByAppendingPathComponent:@"cachedIssues.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedIssuesName])
        {
            NSLog(@"there is! cachedIssues.plist file");
            self.issues = [NSArray arrayWithContentsOfFile:cachedIssuesName];
            ready = YES;
            [self addIssuesInNewsstandLibrary];
            [[NSNotificationCenter defaultCenter] postNotificationName:PublisherDidUpdate object:self];
        }else{
            //there is not cached plist of issues so post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:PublisherFailedUpdate object:self];
        }
    //With internet connection implementation
    }else{
         NSLog(@"network status is Reachable!");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                       ^{
                           NSArray *tmpIssuesArray=nil;
                           XMLParser *parser=[[XMLParser alloc] init];
                           [parser parseXMLFileAtURL:[NSURL URLWithString:[self getIssuesLocation]]];
                           if ([parser isDone])
                           {
                               NSLog(@"parser is done");
                               tmpIssuesArray = [parser parsedItems];
                           }
                           if (!tmpIssuesArray)
                           {
                               NSLog(@"error to get issues list, check the URL to XML file");
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [[NSNotificationCenter defaultCenter] postNotificationName:PublisherFailedUpdate object:self];
                               });
                               
                           }else{
                               NSLog(@"writing issue list to cachedissues.plist");
                               NSString* cachedIssuesName = [CacheDirectory stringByAppendingPathComponent:@"cachedIssues.plist"];
                               [tmpIssuesArray writeToFile:cachedIssuesName atomically:YES];
                               self.issues = [[NSArray alloc] initWithArray:tmpIssuesArray];
                              
                               ready = YES;
                               [self addIssuesInNewsstandLibrary];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [[NSNotificationCenter defaultCenter] postNotificationName:PublisherDidUpdate object:self];
                               });
                           }
                       });
    }
    
}

-(void)getIssuesListSynchronous {
    NSLog(@"getIssuesListSynchronous");
    NSArray *tmpIssues = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:[self getIssuesLocation]]];
    if(!tmpIssues) {
    } else {
        self.issues = [[NSArray alloc] initWithArray:tmpIssues];
        ready = YES;
        [self addIssuesInNewsstandLibrary];
        
    }
}

-(void)addIssuesInNewsstandLibrary
{
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    [self.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *name = [(NSDictionary *)obj objectForKey:@"name"];
        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            NSDate *issueDate=[(NSDictionary *)obj objectForKey:@"date"];
            if (issueDate) {
               //was nkIssue = [nkLib addIssueWithName:name date:issueDate];
                [nkLib addIssueWithName:name date:issueDate];
            }
            
        }
    }];
}

-(NSInteger)numberOfIssues {
    if([self isReady] && self.issues) {
        return [self.issues count];
    } else {
        return 0;
    }
}
-(NSDictionary *)issueAtIndex:(NSInteger)index {
    return [self.issues objectAtIndex:index];
}
-(NSInteger)indexOfIssue:(NKIssue*)issue{
  
    NKLibrary *nkLib=[NKLibrary sharedLibrary];
    return [[nkLib issues]indexOfObject:issue];
}
-(NSString *)nameOfIssueAtIndex:(NSInteger)index {
    return [[self issueAtIndex:index] objectForKey:@"name"];
}
-(NSString *)titleOfIssueAtIndex:(NSInteger)index {
    return [[self issueAtIndex:index] objectForKey:@"title"];
}
-(NSString*)issueDescriptionAtIndex:(NSInteger)index{
    return  [[self.issues objectAtIndex:index]objectForKey:@"description"];
}

-(NSString*)coverImageURLForIssueAtIndex:(NSInteger)index forRetina:(BOOL)isRetina{
    NSDictionary *issueInfo= self.issues[index];
    NSString* coverPath = isRetina ?  issueInfo[@"cover_large"] : issueInfo[@"cover_small"];
    return coverPath;
}
-(NSString*)headerImageURLForIssueAtIndex:(NSInteger)index forRetina:(BOOL)isRetina{
    NSDictionary *issueInfo= self.issues[index];
    NSString* headerPath = isRetina ?  issueInfo[@"header_large"] : issueInfo[@"header_small"];
    return headerPath;
}

-(NSURL *)contentURLForIssueWithName:(NSString *)name {
    __block NSURL *contentURL=nil;
    [self.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *aName = [(NSDictionary *)obj objectForKey:@"name"];
        if([aName isEqualToString:name]) {
            contentURL = [NSURL URLWithString:[(NSDictionary *)obj objectForKey:@"link"]];
            *stop=YES;
        }
    }];
    NSLog(@"Content URL for issue with name %@ is %@",name,contentURL);
    return contentURL;
}

@end
