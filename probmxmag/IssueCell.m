//
//  IssueCell.m
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#define TITLE_DOWNLOAD @"СКАЧАТЬ"
#define TITLE_READ @"ЧИТАТЬ"
#define TITLE_CANCEL @"ОТМЕНА"

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
        //ЧИТАТЬ
        [self.downloadOrShowButton setAlpha:0.5];
        [self.delButton setAlpha:0.5];
        [self.downloadOrShowButton.layer setBorderWidth:1.0];
        [self.downloadOrShowButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.circularProgressView setAlpha:0.0];
        [self.downloadOrShowButton setTitle:TITLE_READ forState:UIControlStateNormal];
        [self.downloadOrShowButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        //[self.downloadOrShowButton setBackgroundColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1]];
        [self.downloadOrShowButton setAlpha:1.0];
        
        //create delButton border without left border
        CALayer *rightBorder = [CALayer layer];
        CALayer *topBorder = [CALayer layer];
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0, self.delButton.frame.size.height-1, self.delButton.frame.size.width, 1);
        bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
        topBorder.frame = CGRectMake(0, 0, self.delButton.frame.size.width, 1);
        topBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
        rightBorder.frame = CGRectMake(self.delButton.frame.size.width, 0, 1, self.delButton.frame.size.height);
        rightBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
        
        [self.delButton.layer addSublayer:topBorder];
        [self.delButton.layer addSublayer:bottomBorder];
        [self.delButton.layer addSublayer:rightBorder];
        [self.delButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.delButton.imageView setAlpha:0.5];
        [self.delButton setAlpha:1];
        
        
        [self.imageView setAlpha:1.0];
        
    } else {
        //ЗАГРУЗКА
        if(status==NKIssueContentStatusDownloading) {
           // [self.circularProgressView setTintColor:[UIColor lightGrayColor]];
            
            [self.circularProgressView setAlpha:1.0];
            [self.circularProgressView stopSpinProgressBackgroundLayer];
            //[self.imageView setAlpha:0.5];
            [self.downloadOrShowButton setAlpha:0.5];
            [self.delButton setAlpha:0.5];
            [self.downloadOrShowButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [self.downloadOrShowButton setTitle:TITLE_CANCEL forState:UIControlStateNormal];
            [self.downloadOrShowButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [self.downloadOrShowButton setAlpha:1.0];
            [self.delButton setAlpha:0.0];
         
        } else {
            //СКАЧАТЬ
            [self.delButton setAlpha:0.0];
            
            [self.circularProgressView setProgress:0.0];
            [self.circularProgressView setAlpha:0.0];
            [self.imageView setAlpha:1];
            [self.downloadOrShowButton setAlpha:0.5];
            [self.downloadOrShowButton.layer setBorderWidth:1.0];
            [self.downloadOrShowButton.layer setBorderColor:[UIColor blackColor].CGColor];
            [self.downloadOrShowButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
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
