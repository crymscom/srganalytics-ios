//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import "CustomMediaPlayerViewController.h"

@interface CustomMediaPlayerViewController () <RTSAnalyticsMediaPlayerDelegate>

@end

@implementation CustomMediaPlayerViewController

#pragma mark - RTSAnalyticsMediaPlayerDelegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO: Fragile since coupled to internal implementation details, but for tests
    UISlider *slider = [self valueForKey:@"timeSlider"];
    NSAssert(slider, @"Expect slider called timeSlider. Update to match internal implementation details");
    slider.accessibilityLabel = @"slider";
}

- (BOOL) shouldTrackMediaWithIdentifier:(NSString *)identifier
{
	return [identifier hasSuffix:@"VODCell"] || [identifier hasSuffix:@"DVRCell"];
}

@end
