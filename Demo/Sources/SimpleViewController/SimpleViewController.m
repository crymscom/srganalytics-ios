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

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.srg_trackedAutomatically = YES;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.srg_trackedAutomatically) {
        self.title = @"Manual tracking";
        [self performSelector:@selector(srg_trackPageView)
                   withObject:nil
                   afterDelay:1.f];
    }
}

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
