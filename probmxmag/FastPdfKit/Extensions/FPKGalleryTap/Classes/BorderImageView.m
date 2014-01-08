//
//  BorderImageView.m
//  Overlay
//
//  Created by Matteo Gavagnin on 10/21/11.
//  Copyright (c) 2011 MobFarm S.r.l. All rights reserved.
//

#import "BorderImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BorderImageView

-(void)setSelected:(BOOL)selected withColor:(UIColor *)color{
    if (selected) {
        NSLog(@"setting border width to 1");
        [self.layer setBorderColor:[color CGColor]];
        [self.layer setBorderWidth:1.0];
    } else {
        NSLog(@"setting border width to 0.0");
         [self.layer setBorderWidth:0.0];
       // [self.layer setBorderColor:[color CGColor]];
       // [self.layer setBorderWidth:0.0];
    }
}

@end
