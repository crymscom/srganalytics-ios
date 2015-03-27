//
//  RTSAnalyticsProviderConfig.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 27/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTrackerConfig.h"

@interface RTSAnalyticsTrackerConfig ()
@property(nonatomic, strong) NSString *businessUnit;
@property(nonatomic, strong) NSString *comScoreVirtualSite;
@property(nonatomic, strong) NSString *streamSenseVirtualSite;
@end

@implementation RTSAnalyticsTrackerConfig

+ (RTSAnalyticsTrackerConfig *)configWithBusinessUnit:(NSString *)businessUnit
                                  comScoreVirtualSite:(NSString *)comScoreVSite
                               streamSenseVirtualSite:(NSString *)streamSenseVSite
{
    RTSAnalyticsTrackerConfig *config = [[RTSAnalyticsTrackerConfig alloc] init];
    config.businessUnit = businessUnit;
    config.comScoreVirtualSite = comScoreVSite;
    config.streamSenseVirtualSite = streamSenseVSite;
    return config;
}

- (NSString *)appName
{
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
}

- (NSString *)version
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSDictionary *)comScoreGlobalLabels
{
    NSDictionary *labels = @{@"ns_ap_an": [self appName],
                             @"ns_ap_ver": [self version],
                             @"srg_unit": self.businessUnit,
                             @"srg_ap_push": @"0",
                             @"ns_site": @"mainsite",
                             @"ns_vsite": self.comScoreVirtualSite};

    return labels;
}

@end
