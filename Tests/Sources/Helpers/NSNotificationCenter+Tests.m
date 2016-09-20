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
    return [self addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return;
        }
        
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return;
        }
        
        block(event, labels);
    }];
}

@end
