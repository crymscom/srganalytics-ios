//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controllers whose use must be tracked by comScore and NetMetrix view events must conform to the
 *  `SRGAnalyticsViewTracking` protocol, which describes the data to send with such events. The only method
 *  required by this protocol is `srg_pageViewTitle`, which provides the name to be used for the view events.
 *
 *  Optional methods can be implemented to provide more information and custom measurement information (labels).
 *
 *  By default, if a view controller conforms to the `SRGAnalyticsViewTracking` protocol, a view event will
 *  automatically be sent when its `-viewDidAppear:` method is called (only when the view controller is added
 *  to the view controller hierarchy), or when the application returns from background while the view controller
 *  is visible.
 *
 *  If you want to control when such events are sent, however, you can implement the optional `trackedAutomatically`
 *  property to return `NO`, disabling the mechanisms described above. In such cases, you are responsible of calling the
 *  `-[UIViewController trackPageView]` method appropriately when you want the measurement event to be recorded. This 
 *  approach is useful when the labels are not available at the time `-viewDidAppear:` is called, e.g. if they are 
 *  retrieved from a web service request started when the view controller gets displayed.
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
 *  If the page view levels array is `nil` or empty, an 'app' default level will be used.
 *
 *  @return The array of levels, in increasing depth order.
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> *srg_pageViewLevels;

/**
 *  Additional information (labels) which must be sent with a view event. By default no custom labels are sent.
 *
 *  @return The dictionary of labels.
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix).
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *srg_pageViewCustomLabels;

/**
 *  Additional information (labels) which must be sent with a comScore view event. By default no custom labels are sent.
 *
 *  @return The dictionary of labels.
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix).
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *srg_pageViewComScoreCustomLabels;

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
