//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController+SRGAnalytics.h"

#import "SRGMediaPlayerTracker.h"

@implementation SRGMediaPlayerViewController (SRGAnalytics)

#pragma mark Helpers

+ (NSDictionary *)fullInfoWithAnalyticsLabels:(NSDictionary<NSString *, NSString *> *)analyticsLabels userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    if (analyticsLabels) {
        fullUserInfo[SRGAnalyticsMediaPlayerLabelsKey] = analyticsLabels;
    }
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

#pragma mark Object lifecycle

- (instancetype)initWithContentURL:(NSURL *)contentURL analyticsLabels:(NSDictionary<NSString *,NSString *> *)analyticsLabels userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerViewController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    return [self initWithContentURL:contentURL userInfo:fullUserInfo];
}

@end
