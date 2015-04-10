//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTSAnalyticsMediaPlayerDataSource.h"

@interface RTSAnalyticsTracker : NSObject

/**
 *  Singleton instance of the tracker
 *
 *  @return Instance
 */
+ (instancetype)sharedTracker;

/**
 *  <#Description#>
 */
- (void)startTrackingWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;


@end
