//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controllers whose appearance must be tracked by comScore and NetMetrix view events must conform to the
 *  `SRGAnalyticsViewTracking` protocol. The only method required by this protocol is `srg_pageViewTitle`, which
 *  provides the name to be used for the view events.
 *
 *  Optional methods can be implemented to provide more information and custom measurement information (labels).
 *
 *  By default, if a view controller conforms to the `SRGAnalyticsViewTracking` protocol, a view event will
 *  automatically be sent when its `-viewDidAppear:` method is called or when the application returns from
 *  background while the view controller is visible. 
 *
 *  If you want to control when such events are sent, however, you can implement the optional `trackedAutomatically`
 *  property to return NO, disabling the mechanisms described above. In such cases, you are responsible of calling the 
 *  `-[UIViewController trackPageView]` method appropriately when required.
 */
@protocol SRGAnalyticsViewTracking <NSObject>

/**
 *  The page view label to use for view event measurement.
 *
 *  @return The page view title. If this value is empty or nil, the default `untitled` value will be used
 */
@property (nonatomic, readonly, copy, nullable) NSString *srg_pageViewTitle;

@optional

/**
 *  If this method is implemented and returns NO, automatic tracking in `-viewDidAppear:` will be disabled. In this case,
 *  call `-[UIViewController trackPageView]` manually.
 *
 *  If this method is not implemented, the behavior defaults to automatic tracking.
 *
 *  @return YES iff automatic tracking must be enabled, NO otherwise
 */
@property (nonatomic, readonly, getter=srg_isTrackedAutomatically) BOOL srg_trackedAutomatically;

/**
 *  Returns the levels (position in the view hierarchy) to be sent for view event measurement.
 *
 *  If the page view levels array is nil or empty, an `app` default level will be used. Up to 10 levels can be set, any
 *  additional level will be dropped.
 *
 *  @return The array of levels, in increasing depth order
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> *srg_pageViewLevels;

/**
 *  Additional information (labels) which must be sent with a view event. By default no custom labels are sent.
 *
 *  @return The dictionary of labels
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix)
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *srg_pageViewCustomLabels;

/**
 *  Return YES if the the view controller was opened from a push notification. If not implemented, it is assumed the
 *  view controller was not opened from a push notification.
 *
 *  @return YES if the presented view controller has been opened from a push notification, NO otherwise
 */
@property (nonatomic, readonly, getter=srg_isOpenedFromPushNotification) BOOL srg_openedFromPushNotification;

@end

/**
 *  Analytics extensions for manual view controller tracking. This is especially useful when the `srg_trackedAutomatically`
 *  method has been implemented and returns NO (see above)
 */
@interface UIViewController (SRGAnalytics)

/**
 *  Call this method to send a page view event manually
 */
- (void)trackPageView;

@end

NS_ASSUME_NONNULL_END
