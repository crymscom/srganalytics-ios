//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSAnalyticsTrackerConfig.h"
#import "RTSAnalyticsDataSource.h"

@interface RTSAnalyticsTracker : NSObject

- (instancetype)initWithConfig:(RTSAnalyticsTrackerConfig *)config dataSource:(id<RTSAnalyticsDataSource>)dataSource;

- (void)startLoggingInternalComScoreTasks;
- (void)stopLoggingInternalComScoreTasks;

@end
