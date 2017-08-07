//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controllers whose usage must be tracked should conform to the `SRGAnalyticsViewTracking` protocol, which
 *  describes the data to send with such events. The only method required by this protocol is `srg_pageViewTitle`, 
 *  which provides the name to be used for the view events.
 *
 *  By default, if a view controller conforms to the `SRGAnalyticsViewTracking` protocol, a view event will
 *  automatically be sent when it is presented (when `-viewWillAppear:` is called), or when the application 
 *  returns from background while the view controller is visible.
 *
 *  If you want to control when page view events are sent, however, you can implement the optional `srg_isTrackedAutomatically`
 *  method to return `NO`, disabling the mechanism described above. In this case you are responsible of calling the
 *  `-[UIViewController trackPageView]` method appropriately when you want the measurement event to be recorded. This 
 *  approach is useful when the labels are not available at the time `-viewDidAppear:` is called, e.g. if they are 
 *  retrieved from a web service request started when the view controller gets displayed.
 *
 *  If you prefer, you can also perform page view tracking using the corresponding methods available from
 *  `SRGAnalyticsTracker`.
 */
@protocol SRGAnalyticsViewTracking <NSObject>

/**
 *  The page view title to use for view event measurement.
 *
 *  @return The page view title. If this value is empty, no event will be sent.
 */
@property (nonatomic, readonly, copy) NSString *srg_pageViewTitle;

@optional

/**
 *  By default any view controller conforming `SRGAnalyticsViewTracking` is automatically tracked. You can disable
 *  this behavior by implementing the following method and return `NO`. In such cases, you are responsible of calling
 *  the `-[UIViewController trackPageView]` method manually when a view event must be recorded.
 *
 *  @return `YES` iff automatic tracking must be enabled, `NO` otherwise.
 */
@property (nonatomic, readonly, getter=srg_isTrackedAutomatically) BOOL srg_trackedAutomatically;

/**
 *  Return the levels (position in the view hierarchy) to be sent for view event measurement.
 *
 *  @return The array of levels, in increasing depth order.
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> *srg_pageViewLevels;

/**
 *  Additional information (labels) which must be sent with a view event. By default no custom labels are sent.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsPageViewLabels *srg_pageViewLabels;

/**
 *  Return `YES` if the the view controller was opened from a push notification. If not implemented, it is assumed the
 *  view controller was not opened from a push notification.
 *
 *  @return `YES` if the presented view controller has been opened from a push notification, `NO` otherwise.
 */
@property (nonatomic, readonly, getter=srg_isOpenedFromPushNotification) BOOL srg_openedFromPushNotification;

@end

/**
 *  Analytics extensions for manual view controller tracking. This is especially useful when the `srg_trackedAutomatically`
 *  method has been implemented and returns `NO` (see above).
 */
@interface UIViewController (SRGAnalytics)

/**
 *  Call this method to send a page view event manually.
 */
- (void)srg_trackPageView;

@end

NS_ASSUME_NONNULL_END
