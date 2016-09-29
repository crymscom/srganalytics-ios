//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaPlayerTestTrackingDelegate : NSObject <SRGAnalyticsMediaPlayerTrackingDelegate>

- (instancetype)initWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
