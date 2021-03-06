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
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return;
        }
        
        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForPlayerSingleHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerSingleHiddenEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerSingleHiddenEvents = @[@"play", @"pause", @"seek", @"stop", @"eof"];
        });
        
        NSString *event = labels[@"event_id"];
        if ([s_playerSingleHiddenEvents containsObject:event]) {
            block(event, labels);
        }
        else {
            return;
        }
    }];
}

- (id<NSObject>)addObserverForComScoreHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
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
