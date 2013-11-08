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
//NSString *PublisherMustUpdateIssuesList= @"PublisherMustUpdateIssuesList";
//NSString *XMLNAFLocation = @"https://googledrive.com/host/0B6E2Hn-m7yvAN2NVZkRKejVXVDg/NAFexample.xml";
NSString *XMLIssuesLocationIpad = @"http://gdurl.com/6OPR";
NSString *XMLIssuesLocationIphone = @"https://googledrive.com/host/0B6E2Hn-m7yvAN2NVZkRKejVXVDg/issues_iphone.xml";

@implementation Publisher
@synthesize ready;

+(Publisher*)sharedInstance{
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
/*

//////////TEST FOR JSON/////
-(void)getIssueJSON{
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:NEWSSTAND_MANIFEST_URL]];
        [self performSelectorOnMainThread:@selector(fetchedData:)
                               withObject:data waitUntilDone:YES];
    });
}

- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
  
    
    NSLog(@"json: %@", json);
}
//////////TEST FOR JSON/////
*/

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
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedIssuesName]) {
            NSLog(@"there is! cachedIssues.plist file");
            self.issues = [NSArray arrayWithContentsOfFile:cachedIssuesName];
            ready = YES;
            [self addIssuesInNewsstandLibrary];
            [[NSNotificationCenter defaultCenter] postNotificationName:PublisherDidUpdate object:self];
        }else{
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
                               NSLog(@"self.issues count %d",[self.issues count] );
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

-(UIImage *)coverImageForIssueAtIndex:(NSInteger)index retina:(BOOL)isRetina{
    
    //return local image if exist in CacheDirectory
    NSDictionary* issueInfo = [self.issues objectAtIndex:index];
    NSString *coverPath = nil;
    if (isRetina) {
        coverPath = [issueInfo objectForKey:@"cover_large"];
    }else{
        coverPath = [issueInfo objectForKey:@"cover_small"];
    }
    //NSString *coverPath=[issueInfo objectForKey:@"cover_large"];
    NSString *coverName=[coverPath lastPathComponent];
    /* was
    NSString *coverName = [self getBothLastComponentsFromPath:coverPath];
    NSLog(@"coverName %@",coverName);
     */
    NSString *coverFilePath = [CacheDirectory stringByAppendingPathComponent:coverName];
   
    UIImage *image = [UIImage imageWithContentsOfFile:coverFilePath];
    return image;
}
-(UIImage*)headerImageForIssueAtIndex:(NSInteger)index forRetina:(BOOL)isRetina {
    NSLog(@"headerImageForIssueAtIndex");
    NSDictionary *issueInfo=[self.issues objectAtIndex:index];
    NSString *headerPath = nil;
    if (isRetina) {
        headerPath = [issueInfo objectForKey:@"header_large"];
    }else{
        headerPath = [issueInfo objectForKey:@"header_small"];
    }
    //was NSString *headerPath=[issueInfo objectForKey:@"header"];
   
    NSString *headerFileName=[headerPath lastPathComponent];
    
    NSString *headerFilePath =[CacheDirectory stringByAppendingPathComponent:headerFileName];
    UIImage *headerImage=[UIImage imageWithContentsOfFile:headerFilePath];
    return headerImage;
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
/*
-(NSString*)getBothLastComponentsFromPath:(NSString*)path
{
    NSLog(@"getBothLastComponentsFromPath");
    NSString *filePath = [path lastPathComponent];
    NSLog(@"path lastpathComponent %@",[path lastPathComponent]);
    NSArray* components = [path pathComponents];
    NSLog(@"components count %d",[components count]);
    if([components count] > 1)
    {
        int count = [components count];
        filePath = [NSString stringWithFormat:@"%@/%@", [components objectAtIndex:count - 2], [components objectAtIndex:count - 1]];
        NSLog(@"filePath: %@",filePath);
    }
    
    return filePath;
}
*/
-(void)setCoverOfIssueAtIndex:(NSInteger)index  forRetina:(BOOL)isRetina completionBlock:(void(^)(UIImage *img))block {
    NSURL *coverURL= nil;
    if (isRetina) {
        coverURL = [NSURL URLWithString:[[self issueAtIndex:index]objectForKey:@"cover_large"]];
    }else{
        coverURL = [NSURL URLWithString:[[self issueAtIndex:index]objectForKey:@"cover_small"]];
    }
    //NSURL* coverURL = [NSURL URLWithString:[[self issueAtIndex:index]objectForKey:@"cover_large"]];
    NSString* coverFileName=[coverURL lastPathComponent];
   
    NSString *coverFilePath = [CacheDirectory stringByAppendingPathComponent:coverFileName];
    UIImage *image = [UIImage imageWithContentsOfFile:coverFilePath];
    if(image) {
        block(image);
    } else {
        //background downloading issue cover image
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                       ^{
                           NSData *imageData = [NSData dataWithContentsOfURL:coverURL];
                           UIImage *image = [UIImage imageWithData:imageData];
                           if(image) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               [imageData writeToFile:coverFilePath atomically:YES];
                              // NSLog(@"cover image has written to %@",coverFilePath);
                               block(image);
                           }
                       });
    }
}
-(void)setHeaderImageOfIssueAtIndex:(NSUInteger)index forRetina:(BOOL)isRetina completionBlock:(void(^)(UIImage *img))block {
    NSLog(@"setHeaderImageOfIssueAtIndex %d forRetina %d",index, (int)isRetina);
    NSURL *headerURL =nil;
    if (isRetina==YES) {
        headerURL = [NSURL URLWithString:[[self issueAtIndex:0] objectForKey:@"header_large"]];
    }else{
        headerURL = [NSURL URLWithString:[[self issueAtIndex:0] objectForKey:@"header_small"]];
    }
    //NSURL* headerURL = [NSURL URLWithString:[[self issueAtIndex:0] objectForKey:@"header"]];
    NSString *headerFileName = [headerURL lastPathComponent];
    NSString *headerFilePath = [CacheDirectory stringByAppendingPathComponent:headerFileName];
    UIImage *image =[UIImage imageWithContentsOfFile:headerFilePath];
    if (image)
    {
        block(image);
    }else{
        //background downloading issue cover image
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                       ^{
                           NSData *imageData = [NSData dataWithContentsOfURL:headerURL];
                           UIImage *image = [UIImage imageWithData:imageData];
                           if(image) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               [imageData writeToFile:headerFilePath atomically:YES];
                               NSLog(@"header image has written to %@",headerFilePath);
                               block(image);
                           }
                       });
    }

}
/*
-(UIImage *)coverImageForIssue:(NKIssue *)nkIssue
{
    NSLog(@"coverImageForIssue");
    NSString *name = nkIssue.name;
    for(NSDictionary *issueInfo in self.issues) {
       
        if([name isEqualToString:[issueInfo objectForKey:@"name"]])
        {
            NSString *coverPath = [issueInfo objectForKey:@"SOURCE"];
            NSString *coverName= [ coverPath lastPathComponent];
            //was NSString *coverName = [self getBothLastComponentsFromPath:coverPath];
            NSString *coverFilePath = [CacheDirectory stringByAppendingPathComponent:coverName];
            UIImage *image = [UIImage imageWithContentsOfFile:coverFilePath];
            return image;
        }
    }
    NSLog(@"returning nil image cover for issue %@",nkIssue);
    return nil;

}
 */
/*
-(NSString *)downloadPathForIssue:(NKIssue *)nkIssue {
    NSLog(@"downloadPathForIssue %@",[[nkIssue.contentURL path] stringByAppendingPathComponent:[nkIssue.name stringByAppendingString:@".pdf"]]);
    return [[nkIssue.contentURL path] stringByAppendingPathComponent:[nkIssue.name stringByAppendingString:@".pdf"]];
}
*/
@end
