//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Supported business units
 */
typedef NSString * SRGAnalyticsBusinessUnitIdentifier NS_STRING_ENUM;

OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRSI;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTR;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTS;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRF;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRG;
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI;

// This special business unit can be used to test measurement information.
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierTEST;

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
 *     `-application:didFinishLaunchingWithOptions:` implementation, by calling the
 *     `-startWithBusinessUnitIdentifier:containerIdentifier:comScoreVirtualSite:netMetrixIdentifier:`
 *     method.
 *  1. To track page views related to view controllers, have them conform to the `SRGAnalyticsViewTracking` protocol.
 *     View controllers conforming to this protocol are automatically tracked by default, but this behavior can be
 *     tailored to your needs, especially if the time at which the measurement is made (when the view appears) is 
 *     inappropriate. Please refer to the `SRGAnalyticsViewTracking` documentation for more information. If your
 *     application uses plain views (not view controllers) which must be tracked as well, you can still perform
 *     manual tracking via the `-[SRGAnalyticsTracker trackPageViewTitle:levels:labels:comScoreLabels:fromPushNotification:]` 
 *     method.
 *  1. When you need to track specific functionalities in your application (e.g. the use of some interface button
 *     or of some feature of your application), send a hidden event using one of the `-trackHiddenEvent...` methods
 *     available from `SRGAnalyticsTracker`.
 *  1. If you need to track media playback, you must add the SRGAnalytics_MediaPlayer subframework to your project
 *     (@see `SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h` for more information). You are still responsible
 *     of providing most metadata associated with playback (e.g. title or duration of what is being played).
 *  1. If medias you play are retrieved using our data provider library, you must add the SRGAnalytics_DataProvider 
 *     subframework to your project as well (@see `SRGMediaPlayerController+SRGAnalytics_DataProvider.h` for more 
 *     information). In this case, all mandatory stream measurement metadata will be automatically sent.
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
 *  During tests, or if you do not want to pollute real measurements during development, you can use the special
 *  `SRGAnalyticsBusinessUnitIdentifierTEST` business unit. This business unit:
 *    - Disables TagCommander (the container identifier is ignored).
 *    - Disables NetMetrix event sending.
 *    - Still sends comScore events to the specified virtual site.
 *    - Adds an `srg_test` label to comScore measurements, specifying the time at which the tracker was started as a 
 *      timestamp (yyyy-MM-dd@HH:mm). This label can be used to identify application sesssions and to gather measurements 
 *      related to a session if needed.
 *
 *  The [JASS proxy](https://github.com/SRGSSR/jass) tool is provided to let you peek at the comScore analytics data sent 
 *  by your application during development or tests.
 
 *  @param businessUnitIdentifier The SRG SSR business unit for statistics measurements. Constants for the officially
 *                                supported business units are provided at the top of this file. A constant for use
 *                                during development or tests is supplied as well.
 *  @param containerIdentifier    The TagCommander container identifier.
 *  @param comScoreVirtualSite    Virtual sites are where comScore measurements are collected. The virtual site you must
 *                                use is usually supplied by the team in charge of measurements for your application.
 *  @param netMetrixIdentifier    The identifier used to group NetMetrix measurements for your application. This value
 *                                is supplied by the team in charge of measurements for your applicatiom.
 */
- (void)startWithBusinessUnitIdentifier:(SRGAnalyticsBusinessUnitIdentifier)businessUnitIdentifier
                    containerIdentifier:(NSInteger)containerIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier;

/**
 *  The SRG SSR business unit which measurements are associated with.
 */
@property (nonatomic, readonly, copy, nullable) SRGAnalyticsBusinessUnitIdentifier businessUnitIdentifier;

/**
 *  The TagCommander container identifier.
 */
@property (nonatomic, readonly) NSInteger containerIdentifier;

/**
 *  The comScore virtual site where statistics are gathered (`nil` if the tracker has not been started).
 */
@property (nonatomic, readonly, copy, nullable) NSString *comScoreVirtualSite;

/**
 *  The NetMetrix identifier which is used (`nil` if the tracker has not been started).
 */
@property (nonatomic, readonly, copy, nullable) NSString *netMetrixIdentifier;

/**
 *  Return `YES` iff the tracker has been started.
 */
@property (nonatomic, readonly, getter=isStarted) BOOL started;

@end

/**
 *  @name Hidden event tracking
 */

/**
 *  Additional hidden event labels.
 */
@interface SRGAnalyticsHiddenEventLabels : NSObject

/**
 *  The event type (this concept is loosely defined, please discuss expected values for your application with the
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 *  The event value (this concept is loosely defined, please discuss expected values for your application with the
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *value;

/**
 *  The event source (this concept is loosely defined, please discuss expected values for your application with the
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
 *                              If the page view levels array is `nil` or empty, an 'app' default level will be used.
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
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy. If the 
 *                              page view levels array is `nil` or empty, an 'app' default level will be used.
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
