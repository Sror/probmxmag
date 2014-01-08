//
//  XMLParser.m
//
//
//

#import "XMLParser.h"
//#import "MenuViewController_Kiosk.h"
#define XML_DATE_FORMAT @"yyyy-MM-dd'T'HH:mm:ss'Z"
#define XML_ISSUE_NAME_TAG @"name"
#define XML_ISSUE_DATE_TAG @"date"
#define XML_ISSUE_PDF_LINK_TAG @"link"
#define XML_ISSUE_COVER_LARGE_TAG @"cover_large"
#define XML_ISSUE_COVER_SMALL_TAG @"cover_small"
#define XML_ISSUE_TITLE_TAG @"title"
#define XML_ISSUE_DESCRIPTION_TAG @"description"
#define XML_ISSUE_HEADER_LARGE_TAG @"header_large"
#define XML_ISSUE_HEADER_SMALL_TAG @"header_small"
#define XML_PDF_TAG @"pdf"


@interface XMLParser()

@property (nonatomic, retain) NSMutableArray * documents;
@property (nonatomic, retain) NSMutableDictionary * currentItem;
@property (nonatomic, copy ) NSString *currentString;
@property(nonatomic,copy) NSMutableString *muString;

@property (nonatomic, readwrite) BOOL downloadError;
@property (nonatomic, readwrite) BOOL endOfDocumentReached;

@end

@implementation XMLParser

@synthesize currentString;
@synthesize muString;
@synthesize documents;
@synthesize currentItem;
@synthesize downloadError, endOfDocumentReached;

-(BOOL)isDone {
    
    return ((!self.downloadError)&&(self.endOfDocumentReached)&&(self.documents));
}

-(NSMutableArray *)parsedItems {
    return self.documents;
}

- (void)parseXMLFileAtURL:(NSURL *)url {
	NSLog(@"parseXMLFileAtURL %@",url);
	NSXMLParser * xmlParser = nil;
    NSData * xmlData = nil;
    //NSString *xmlDataString = nil;
    self.downloadError = NO;
    self.endOfDocumentReached = NO;
    xmlData = [NSData dataWithContentsOfURL:url];
    xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
    //////
    /*
    NSError *error;
    NSString * dataString = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"dataString %@",dataString);
    
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    xmlParser          = [[NSXMLParser alloc] initWithData:data];
     */
    xmlParser = [[NSXMLParser alloc]initWithData:xmlData];
    
	[xmlParser setDelegate:self];
    [xmlParser setShouldProcessNamespaces:NO];
    [xmlParser setShouldReportNamespacePrefixes:NO];
    [xmlParser setShouldResolveExternalEntities:NO];
    [xmlParser parse]; // Start parsing.
}
-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    NSMutableArray * documentsArray = [[NSMutableArray alloc] init];
	self.documents = documentsArray;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	self.downloadError = YES;
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    NSMutableDictionary * dictionary = nil;
	if ([elementName isEqualToString:XML_PDF_TAG]) {
		// Create a new dictionary and release the old one (if necessary).
		dictionary = [[NSMutableDictionary alloc] init];
		self.currentItem = dictionary;
	}
    if ([elementName isEqualToString:@"description"]) {
        muString = [[NSMutableString alloc]init];;
    }
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	//<name>
    if ([elementName isEqualToString:XML_ISSUE_NAME_TAG]) {
        [self.currentItem setValue:currentString forKey:XML_ISSUE_NAME_TAG];
    }
    //<header_large>
    if ([elementName isEqualToString:XML_ISSUE_HEADER_LARGE_TAG]) {
        [self.currentItem setValue:currentString forKey:XML_ISSUE_HEADER_LARGE_TAG];
    }
    //<header_small>
    if ([elementName isEqualToString:XML_ISSUE_HEADER_SMALL_TAG]) {
        [self.currentItem setValue:currentString forKey:XML_ISSUE_HEADER_SMALL_TAG];
    }
    //<date>
    if ([elementName isEqualToString:XML_ISSUE_DATE_TAG]) {
        NSDateFormatter *df=[[NSDateFormatter alloc] init];
        [df setDateFormat:XML_DATE_FORMAT];
       
        NSDate *date = [df dateFromString:currentString];
        [self.currentItem setValue:date forKey:XML_ISSUE_DATE_TAG];
        
    }
    //<title>
	if ([elementName isEqualToString:XML_ISSUE_TITLE_TAG]) {
		[self.currentItem setValue:currentString forKey:XML_ISSUE_TITLE_TAG];
	}
    //<link>
    if ([elementName isEqualToString:XML_ISSUE_PDF_LINK_TAG]) {
		[self.currentItem setValue:currentString forKey:XML_ISSUE_PDF_LINK_TAG];
	}
    //<description>
    if ([elementName isEqualToString:XML_ISSUE_DESCRIPTION_TAG]) {
        [self.currentItem setValue:muString forKey:XML_ISSUE_DESCRIPTION_TAG];
        muString = nil;
        
    }
    //<cover_large>
    if ([elementName isEqualToString:XML_ISSUE_COVER_LARGE_TAG]) {
		[self.currentItem setValue:currentString forKey:XML_ISSUE_COVER_LARGE_TAG];
	}
    //<cover_small>
    if ([elementName isEqualToString:XML_ISSUE_COVER_SMALL_TAG]) {
		[self.currentItem setValue:currentString forKey:XML_ISSUE_COVER_SMALL_TAG];
	}
    //</pdf>
    if ([elementName isEqualToString:XML_PDF_TAG]) {
		[self.documents addObject:currentItem];
	}
  
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	self.currentString = string;
    if (![string isEqualToString:@""]) {
        [muString appendString:string];
    }

}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.endOfDocumentReached = YES;
}

@end