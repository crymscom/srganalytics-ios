//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleViewController : UIViewController <SRGAnalyticsViewTracking>

- (instancetype)initWithTitle:(nullable NSString *)title
                       levels:(nullable NSArray<NSString *> *)levels
                 customLabels:(nullable NSDictionary<NSString *, NSString *> *)customLabels
   openedFromPushNotification:(BOOL)openedFromPushNotification
         trackedAutomatically:(BOOL)trackedAutomatically;

@end

@interface SimpleViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
