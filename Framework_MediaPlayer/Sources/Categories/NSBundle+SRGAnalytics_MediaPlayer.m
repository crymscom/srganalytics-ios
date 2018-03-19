//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGAnalytics.h"

#import "SRGMediaPlayerTracker.h"

#import <UIKit/UIKit.h>

@implementation NSBundle (SRGAnalytics_MediaPlayer)

+ (NSBundle *)srg_analyticsMediaPlayerBundle
{
    static NSBundle *s_bundle;
    static dispatch_once_t s_once;
    dispatch_once(&s_once, ^{
        s_bundle = [NSBundle bundleForClass:[SRGMediaPlayerTracker class]];
    });
    return s_bundle;
}

@end
