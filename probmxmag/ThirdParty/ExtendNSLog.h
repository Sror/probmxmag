//
//  ExtendNSLog.h
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 15.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef DEBUG
#define NSLog(args...) ExtendLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
#define NSLog(x...)
#endif
void ExtendLog(const char *file, int lineNumber,const char*functionName,NSString *format,...);

@interface ExtendNSLog : NSObject

@end
