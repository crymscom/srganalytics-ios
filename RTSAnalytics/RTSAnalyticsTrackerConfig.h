//
//  RTSAnalyticsProviderConfig.h
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 27/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTSAnalyticsTrackerConfig : NSObject

@property(nonatomic, strong, readonly) NSString *businessUnit;
@property(nonatomic, strong, readonly) NSString *comScoreVirtualSite;
@property(nonatomic, strong, readonly) NSString *streamSenseVirtualSite;

+ (RTSAnalyticsTrackerConfig *)configWithBusinessUnit:(NSString *)businessUnit
                                  comScoreVirtualSite:(NSString *)comScoreVSite
                               streamSenseVirtualSite:(NSString *)streamSenseVSite;

- (NSString *)appName;
- (NSString *)version;

- (NSDictionary *)comScoreGlobalLabels;

@end
