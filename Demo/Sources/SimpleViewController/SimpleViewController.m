//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimpleViewController.h"
#import <SRGAnalytics/SRGAnalytics.h>

@interface SimpleViewController () <SRGAnalyticsViewTracking>

@end

@implementation SimpleViewController

- (IBAction)dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - SRGAnalyticsViewTracking

- (NSString *)srg_pageViewTitle
{
	return self.title;
}

- (NSArray *)srg_pageViewLevels
{
	return self.levels;
}

- (NSDictionary *)srg_pageViewCustomLabels
{
	return self.customLabels;
}

@end
