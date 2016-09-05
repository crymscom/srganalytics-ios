//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

/**
 *  Category on `SRGAnalyticsTracker` which implements Comscore logging methods.
 * 
 *  Comscore SDK does not provide an easy way to debug sent labels for view events and stream measurements.
 *  `SRGAnalyticsTracker+Logging` allows to print in the debugger console the request status and all labels sent by the Comscore SDK.
 *
 *  @see `CSRequest+SRGNotification` category
 */
@interface SRGAnalyticsTracker (Logging)

/**
 *  Start logging events to the `SRGAnalyticsLogger`
 */
- (void)startLoggingInternalComScoreTasks;

@end
