//
//  IssueCell.m
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#define TITLE_DOWNLOAD @"СКАЧАТЬ"
#define TITLE_READ @"ЧИТАТЬ"

#import "IssueCell.h"

@implementation IssueCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)updateCellInformationWithStatus:(NKIssueContentStatus)status
{
    if(status==NKIssueContentStatusAvailable) {
        [self.downloadOrShowButton setTitle:TITLE_READ forState:UIControlStateNormal];
        [self.downloadOrShowButton setAlpha:1.0];
        [self.progressView setAlpha:0.0];
        [self.imageView setAlpha:1.0];
        
    } else {
        if(status==NKIssueContentStatusDownloading) {
            [self.progressView setAlpha:1.0];
            [self.imageView setAlpha:0.5];
         
        } else {
            [self.progressView setProgress:0.0];
            [self.progressView setAlpha:0.0];
            [self.imageView setAlpha:1];
            [self.downloadOrShowButton setTitle:TITLE_DOWNLOAD forState:UIControlStateNormal];
            [self.downloadOrShowButton setAlpha:1.0];     
        }
        
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
