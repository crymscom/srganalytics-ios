//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController+SRGAnalytics.h"

#import "SRGMediaPlayerTracker.h"

@implementation SRGMediaPlayerViewController (SRGAnalytics)

#pragma mark Helpers

+ (NSDictionary *)fullInfoWithTrackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    if (trackingDelegate) {
        fullUserInfo[SRGAnalyticsMediaPlayerTrackingDelegateKey] = trackingDelegate;
    }
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL
                  trackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
                          userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerViewController fullInfoWithTrackingDelegate:trackingDelegate userInfo:userInfo];
    return [self initWithContentURL:contentURL userInfo:fullUserInfo];
}

@end
