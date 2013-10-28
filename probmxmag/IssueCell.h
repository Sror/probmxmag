//
//  IssueCell.h
//  probmxmag
//
//  Created by Aleksey Ivanov on 28.10.13.
//  Copyright (c) 2013 Aleksey Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NewsstandKit/NewsstandKit.h>
@interface IssueCell : UICollectionViewCell
@property (weak,nonatomic) IBOutlet UIImageView *imageView;
@property (weak,nonatomic) IBOutlet UITextView *textView;
@property (weak,nonatomic) IBOutlet UILabel *issueTitle;
@property (weak,nonatomic) IBOutlet UIButton *downloadOrShowButton;
@property (weak,nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak,nonatomic) IBOutlet UIProgressView *progressView;

-(void)updateCellInformationWithStatus:(NKIssueContentStatus)status;
@end
