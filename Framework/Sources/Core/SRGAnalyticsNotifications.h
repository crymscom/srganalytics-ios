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
 *
 */

// TODO: Move to a separate file

/**
 *  Posted when the request's response is received. The `object` of the notification is a NSURLRequest.
 */
OBJC_EXTERN NSString *const SRGAnalyticsNetmetrixRequestNotification;

/**
 * A NSNumber (boolean) indicating success in the user info dictionary of `SRGAnalyticsNetmetrixRequestNotification`.
 */
OBJC_EXTERN NSString *const SRGAnalyticsNetmetrixRequestSuccessUserInfoKey;

/**
 *  A NSError in the user info dictionary of `SRGAnalyticsNetmetrixRequestNotification`. This key is not present if the request succeeded.
 */
OBJC_EXTERN NSString *const SRGAnalyticsNetmetrixRequestErrorUserInfoKey;

/**
 *  A NSURLResponse in the user info dictionary of `SRGAnalyticsNetmetrixRequestNotification`.
 */
OBJC_EXTERN NSString *const SRGAnalyticsNetmetrixRequestResponseUserInfoKey;

OBJC_EXTERN NSString *const SRGAnalyticsComScoreRequestNotification;
OBJC_EXTERN NSString *const SRGAnalyticsLabelsKey;
