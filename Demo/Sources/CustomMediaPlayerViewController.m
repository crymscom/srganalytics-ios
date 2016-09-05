//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import "CustomMediaPlayerViewController.h"

@implementation CustomMediaPlayerViewController

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    return [super initWithContentURL:contentURL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO: Fragile since coupled to internal implementation details, but for tests
    UISlider *slider = [self valueForKey:@"timeSlider"];
    NSAssert(slider, @"Expect slider called timeSlider. Update to match internal implementation details");
    slider.accessibilityLabel = @"slider";
}

@end
