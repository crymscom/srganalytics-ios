//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject <SRGAnalyticsSegment>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
