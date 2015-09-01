//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "ViewController.h"
#import <SRGAnalytics/SRGAnalytics.h>

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
	return self.title;
}

- (NSArray *)pageViewLevels
{
	return self.levels;
}

- (NSDictionary *)pageViewCustomLabels
{
	return self.customLabels;
}

@end
