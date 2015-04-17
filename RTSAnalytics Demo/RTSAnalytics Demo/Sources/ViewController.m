//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "ViewController.h"
#import <RTSAnalytics/RTSAnalytics.h>

@interface ViewController () <RTSAnalyticsPageViewDataSource>

@end

@implementation ViewController

- (IBAction)dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - RTSAnalyticsPageViewDataSource

- (NSString *)pageViewTitle
{
	return @"Title";
}

@end
