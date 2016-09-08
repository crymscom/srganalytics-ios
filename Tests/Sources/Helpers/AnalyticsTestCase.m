//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation AnalyticsTestCase

// Expectation for global hidden event notifications (player notifications are all event notifications, we don't want to have a look
// at view events here)
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(HiddenEventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreRequestLabelsUserInfoKey];
        
        NSString *event = labels[@"ns_type"];
        if (! [event isEqualToString:@"hidden"]) {
            return NO;
        }
        
        // Discard heartbeats (though hidden events, they are outside our control)
        if ([labels[@"ns_st_ev"] isEqualToString:@"hb"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

@end
