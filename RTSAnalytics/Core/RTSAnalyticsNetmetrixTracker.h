//
//  Created by Frédéric Humbert-Droz on 10/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

/**
 *  Posted when the request's response is received. The `object` of the notification is a NSURLRequest.
 */
FOUNDATION_EXTERN NSString * const RTSAnalyticsNetmetrixRequestDidFinishNotification;

/**
 * A NSNumber (boolean) indicating success in the user info dictionary of `RTSAnalyticsNetmetrixRequestDidFinishNotification`.
 */
FOUNDATION_EXTERN NSString * const RTSAnalyticsNetmetrixRequestSuccessUserInfoKey;

/**
 *  A NSError in the user info dictionary of `RTSAnalyticsNetmetrixRequestDidFinishNotification`. This key is not present if the request succeeded.
 */
FOUNDATION_EXTERN NSString * const RTSAnalyticsNetmetrixRequestErrorUserInfoKey;

/**
 *  A NSURLResponse in the user info dictionary of `RTSAnalyticsNetmetrixRequestDidFinishNotification`.
 */
FOUNDATION_EXTERN NSString * const RTSAnalyticsNetmetrixRequestResponseUserInfoKey;
