//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

/**
 *  The comScore SDK does not expose success/failure callbacks when sending requests so we hook here to provide a notification.
 *  This notification may be used for logging and integration tests.
 */
@interface CSRequest : NSObject
- (BOOL)send;
@end

@interface CSRequest (RTSNotification)
// The implementation swizzles `send` for posting the `ComScoreRequestDidFinishNotification` notification.
@end
