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
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI;

// This special business unit can be used in test or debug builds of your application if you do not want to pollute
// actual measurements while in development.
OBJC_EXPORT SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierTEST;

/**
 *  @name Media player events
 */
typedef NS_ENUM(NSInteger, SRGAnalyticsPlayerEvent) {
    /**
     *  The player started buffering.
     */
    SRGAnalyticsPlayerEventBuffer,
    /**
     *  Playback started or resumed.
     */
    SRGAnalyticsPlayerEventPlay,
    /**
     *  Playback was paused.
     */
    SRGAnalyticsPlayerEventPause,
    /**
     *  The player started seeking.
     */
    SRGAnalyticsPlayerEventSeek,
    /**
     *  The player was stopped.
     */
    SRGAnalyticsPlayerEventStop,
    /**
     *  Playback ended normally.
     */
    SRGAnalyticsPlayerEventEnd,
    /**
     *  Heartbeat.
     */
    SRGAnalyticsPlayerEventHeartbeat
};

/**
 *  The analytics tracker is a singleton instance responsible of tracking usage of an application, sending measurements
 *  to TagCommander, comScore and NetMetrix. The usage data is simply a collection of key-values (both strings), named
 *  labels, which can then be used by data analysts.
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
 *  All kinds of events can be supplied arbitrary information. This information is primarily meant for use by TagCommander
 *  and comScore, since NetMetrix currently only records view events in a fairly basic way.
 *
 *  During a transition phase, both TagCommander and comScore will be used for measurements. As a result, measurement
 *  methods expect TagCommander and comScore labels separately (since the conventions will differ between the services).
 *  At the end of this transition phase, comScore support will be entirely removed.
 *
 *  ## Usage
 *
 *  Using SRGAnalytics in your application is intended to be as easy as possible. Note that ince the analytics tracker is
 *  a singleton, you cannot currently perform measurements related to several business units within a single application.
 *  To track application usage:
 *
 *  1. Start the tracker early in your application lifecycle, for example in your application delegate
 *     `-application:didFinishLaunchingWithOptions:` implementation, by calling the
 *     `-startWithBusinessUnitIdentifier:accountIdentifier:containerIdentifier:comScoreVirtualSite:netMetrixIdentifier:`
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
 *  @param accountIdentifier      The TagCommander account identifier.
 *  @param container              The TagCommander container.
 *  @param comScoreVirtualSite    Virtual sites are where comScore measurements are collected. The virtual site you must
 *                                use is usually supplied by the team in charge of measurements for your application.
 *  @param netMetrixIdentifier    The identifier used to group NetMetrix measurements for your application. This value
 *                                is supplied by the team in charge of measurements for your applicatiom.
 */
- (void)startWithBusinessUnitIdentifier:(NSString *)businessUnitIdentifier
                      accountIdentifier:(NSInteger)accountIdentifier
                    containerIdentifier:(NSInteger)containerIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier;

/**
 *  The SRG SSR business unit which measurements are associated with.
 */
@property (nonatomic, readonly, copy, nullable) NSString *businessUnitIdentifier;

/**
 *  The TagCommander account identifier.
 */
@property (nonatomic, readonly) NSInteger accountIdentifier;

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

@interface SRGAnalyticsTracker (HiddenEventTracking)

/**
 *  Send a hidden event with the specified title.
 *
 *  @param title The event title.
 *
 *  @discussion If the title is empty, no event will be sent.
 */
- (void)trackHiddenEventWithTitle:(NSString *)title;

/**
 *  Send a hidden event with the specified title.
 *
 *  @param title          The event title.
 *  @param labels         Information to be sent along the event and which is meaningful for your application measurements.
 *  @param comScoreLabels comScore information to be sent along the event and which is meaningful for your application
 *                        measurements.
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix). If the title is `nil`, no event will be sent.
 */
- (void)trackHiddenEventWithTitle:(NSString *)title
                           labels:(nullable NSDictionary<NSString *, NSString *> *)labels
                   comScoreLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreLabels;

@end

/**
 *  @name Page view tracking
 */

@interface SRGAnalyticsTracker (PageViewTracking)

/**
 *  Track a page view (not associated with a push notification).
 *
 *  @param title                The page title.
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy.
 *                              If the page view levels array is `nil` or empty, an 'app' default level will be used.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 *
 *              Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix). If the title is `nil`, no event will be sent.
 */
- (void)trackPageViewWithTitle:(nullable NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels;

/**
 *  Track a page view.
 *
 *  @param title                The page title.
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy. If the 
 *                              page view levels array is `nil` or empty, an 'app' default level will be used.
 *  @param labels               Additional custom labels.
 *  @param comScoreLabels       Custom comScore information to be sent along the event and which is meaningful for your application
 *                              measurements.
 *  @param fromPushNotification `YES` iff the view is opened from a push notification.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 *
 *              Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix). If the title is `nil`, no event will be sent.
 */
- (void)trackPageViewWithTitle:(nullable NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels
                        labels:(nullable NSDictionary<NSString *, NSString *> *)labels
                comScoreLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreLabels
          fromPushNotification:(BOOL)fromPushNotification;

@end

/**
 *  @name Player tracking
 */

@interface SRGAnalyticsTracker (PlayerTracking)

/**
 *  Track a media player event.
 *
 *  @param event                 The event type.
 *  @param position              The playback position at which the event occurs, in milliseconds.
 *  @param labels                Additional custom labels.
 *  @param comScoreLabels        Custom comScore information to be sent along the event and which is meaningful for your application
 *                               measurements.
 *  @param comScoreSegmentLabels Custom comScore segment information to be sent along the event and which is meaningful to your application
 *                               measurements.
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix).
 */
- (void)trackPlayerEvent:(SRGAnalyticsPlayerEvent)event
              atPosition:(NSTimeInterval)position
              withLabels:(nullable NSDictionary<NSString *, NSString *> *)labels
          comScoreLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreLabels
   comScoreSegmentLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreSegmentLabels;

@end

@interface SRGAnalyticsTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
