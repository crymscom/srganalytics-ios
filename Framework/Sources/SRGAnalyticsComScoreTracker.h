//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

/**
 *  The `object` is the `NSURLRequest` that was sent to comScore.
 *  The `userInfo` contains the `ComScoreRequestSuccessUserInfoKey` which is a BOOL NSNumber indicating if the request succeeded or failed.
 *  The `userInfo` also contains the `ComScoreRequestLabelsUserInfoKey` which is a NSDictionary representing all the labels.
 */
FOUNDATION_EXTERN NSString * const SRGAnalyticsComScoreRequestDidFinishNotification;
FOUNDATION_EXTERN NSString * const SRGAnalyticsComScoreRequestLabelsUserInfoKey;
