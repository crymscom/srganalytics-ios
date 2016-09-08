//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForName:SRGAnalyticsComScoreRequestDidFinishNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreRequestLabelsUserInfoKey];
        
        NSString *event = labels[@"ns_type"];
        if (! [event isEqualToString:@"hidden"]) {
            return;
        }
        
        block(event, labels);
    }];
}

@end
