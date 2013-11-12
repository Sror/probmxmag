//
//  ExtendNSLog.m
//  NewsstandTemplate
//
//  Created by Aleksey Ivanov on 15.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import "ExtendNSLog.h"


void ExtendLog(const char *file, int lineNumber,const char*functionName,NSString *format,...)
{
    va_list ap;
    va_start(ap, format);
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    NSString *fileName = [[NSString stringWithUTF8String:file]lastPathComponent];
    fprintf(stderr, "(%s) (%s:%d) %s",functionName , [fileName UTF8String],lineNumber ,[body UTF8String]);
}

@implementation ExtendNSLog

@end
