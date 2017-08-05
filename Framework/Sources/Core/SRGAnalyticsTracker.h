//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The analytics tracker is a singleton instance responsible of tracking usage of an application, sending measurements
 *  to TagCommander, comScore and NetMetrix. The usage data is simply a collection of key-values (both strings), named
 *  labels, which can then be used by data analysts in studies and reports.
 *
 *  The analytics tracker implementation follows the SRG SSRG guidelines for application measurements (mostly label name
 *  conventions) and is therefore only intended for use by applications produced under the SRG SSR umbrella.
 *
 *  ## Measurements
 *
 *  The SRG Analytics library supports three kinds of measurements:
 *    - View events: Appearance of views (page views), which makes it possible to track which content is seen by users.
 *    - Hidden events: Custom events which can be used for measuresement of application functionalities.
 *    - Media playback events: Measurements for audio and video consumption.
 *
 *  For all kinds of measurements, required information must be provided through mandatory parameters, and optional
 *  labels can be provided through an optional labels object. In all cases, mandatory and optional information is
 *  correctly routed to the analytics services. Raw dictionaries can also be filled with custom information if needed.
 *
 *  ## Usage
 *
 *  Using SRGAnalytics in your application is intended to be as easy as possible. Note that since the analytics tracker is
 *  a singleton, you cannot currently perform measurements related to several business units within a single application.
 *
 *  To track application usage:
 *
 *  1. Start the tracker early in your application lifecycle, for example in your application delegate
 *     `-application:didFinishLaunchingWithOptions:` implementation, by calling the `-startWithConfiguration:` method. 
 *     This method expect a single configuration object containing all analytics setup information.
 *  1. To track page views related to view controllers, have them conform to the `SRGAnalyticsViewTracking` protocol.
 *     View controllers conforming to this protocol are automatically tracked by default, but this behavior can be
 *     tailored to your needs, especially if the time at which the measurement is made (when the view appears) is 
 *     inappropriate. Please refer to the `SRGAnalyticsViewTracking` documentation for more information. If your
 *     application uses plain views (not view controllers) which must be tracked as well, you can still perform
 *     manual tracking via the `-[SRGAnalyticsTracker trackPageViewWithTitle:levels:labels:fromPushNotification:]`
 *     method.
 *  1. When you need to track specific functionalities in your application (e.g. the use of some interface button
 *     or of some feature of your application), send a hidden event using one of the `-trackHiddenEvent...` methods
 *     available from `SRGAnalyticsTracker`.
 *  1. If you need to track playback using SRG MediaPlayer, you must add the SRGAnalytics_MediaPlayer subframework 
 *     to your project (@see `SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h` for more information). You are 
 *     still responsible of providing most metadata associated with playback (e.g. title or duration of what is 
 *     being played) when calling one of the playback methods provided in this subframework.
 *  1. If medias you play are retrieved using our data provider library, you must add the SRGAnalytics_DataProvider 
 *     subframework to your project as well (@see `SRGMediaPlayerController+SRGAnalytics_DataProvider.h` for more 
 *     information). In this case, all mandatory stream measurement metadata will be automatically provided when
 *     playing the content through one of the playback methods provided in this subframework.
 *
 *  You can also perform manual media player tracking when your player implementation does not rely on SRG MediaPlayer,
 *  @see `SRGAnalyticsPlayerTracker` for more information.
 */
@interface SRGAnalyticsTracker : NSObject

/**
 *  The tracker singleton.
 */
+ (instancetype)sharedTracker;

/**
 *  Start the tracker. This is required to specify for which business unit you are tracking events, as well as to
 *  where they must be sent on the comScore, NetMetrix and TagCommander services. Attempting to track view, hidden 
 *  or stream events without starting the tracker has no effect.
 *
 *  @param configuration The configuration to use. This configuration is copied and cannot be changed afterwards.
 */
- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration;

/**
 *  The tracker configuration with which the tracker was started.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsConfiguration *configuration;

@end

/**
 *  @name Hidden event tracking
 */

/**
 *  Additional hidden event labels.
 */
@interface SRGAnalyticsHiddenEventLabels : NSObject

/**
 *  The event type (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 *  The event value (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *value;

/**
 *  The event source (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *source;

/**
 *  Additional custom information, mapping variables to values. See https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/197019081
 *  for a full list of possible variable names.
 *
 *  You should rarely need to provide custom information with measurements, as this requires the variable name to be
 *  declared on TagCommander portal first (otherwise the associated value will be discarded).
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *customInfo;

/**
 *  Additional custom information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomInfo;

@end

@interface SRGAnalyticsTracker (HiddenEventTracking)

/**
 *  Send a hidden event with the specified name.
 *
 *  @param name The event name.
 *
 *  @discussion If the name is empty, no event will be sent.
 */
- (void)trackHiddenEventWithName:(NSString *)name;

/**
 *  Send a hidden event with the specified name.
 *
 *  @param name           The event name.
 *  @param labels         Information to be sent along the event and which is meaningful for your application measurements.
 *
 *  @discussion If the name is `nil`, no event will be sent.
 */
- (void)trackHiddenEventWithName:(NSString *)name
                          labels:(nullable SRGAnalyticsHiddenEventLabels *)labels;

@end

/**
 *  @name Page view tracking
 */

/**
 *  Additional page view labels.
 */
@interface SRGAnalyticsPageViewLabels : NSObject

/**
 *  Additional custom information, mapping variables to values. See https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/197019081
 *  for a full list of possible variable names.
 *
 *  You should rarely need to provide custom information with measurements, as this requires the variable name to be
 *  declared on TagCommander portal first (otherwise the associated value will be discarded).
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *customInfo;

/**
 *  Additional custom information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomInfo;

@end

@interface SRGAnalyticsTracker (PageViewTracking)

/**
 *  Track a page view (not associated with a push notification).
 *
 *  @param title                The page title. If the title is `nil`, no event will be sent.
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 */
- (void)trackPageViewWithTitle:(nullable NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels;

/**
 *  Track a page view.
 *
 *  @param title                The page title. If the title is `nil`, no event will be sent.
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy.
 *  @param labels               Additional custom labels.
 *  @param fromPushNotification `YES` iff the view is opened from a push notification.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 */
- (void)trackPageViewWithTitle:(nullable NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels
                        labels:(nullable SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification;

@end

@interface SRGAnalyticsTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
