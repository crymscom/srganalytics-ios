//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The following notifications can be used if you need to track when comScore and NetMetrix requests are made, 
 *  and which information is actually sent to these services. This can be useful for test case implementations,
 *  but applications in production should not use these notifications.
 */

// Notification sent when a request is made to comScore
OBJC_EXTERN NSString * const SRGAnalyticsComScoreRequestNotification;

// Information available for `SRGAnalyticsComScoreRequestNotification`
OBJC_EXTERN NSString * const SRGAnalyticsComScoreLabelsKey;                 // Key for accessing the comScore labels (as an NSDictionary<NSString *, NSString *>) available from the user info

// Notification sent when a request is made to NetMetrix
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixRequestNotification;

// Information available for `SRGAnalyticsNetmetrixRequestNotification`
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixURLKey;

NS_ASSUME_NONNULL_END
