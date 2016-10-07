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

OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRSI;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRTR;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRTS;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierSRF;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierSWI;

// This special business unit can be used in test or debug builds of your application if you do not want to pollute
// actual measurements while in development
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierTEST;

/**
 *  The analytics tracker is a singleton instance responsible of tracking usage of an application, using comScore and
 *  NetMetrix. This usage is simply a collection of key-values (both strings), often referred to as labels, which
 *  can then be used for analytics measurements. 
 *
 *  This tracker implementation follows the SRG SSRG guidelines for application measurements (mostly label name
 *  conventions) and is therefore only intended for use by applications produced under the SRG SSR umbrella.
 *
 *  ## Measurements
 *
 *  Measurements are based on events emitted by the application, and collected by comScore and NetMetrix. Currently, the
 *  SRGAnalytics library supports the following kinds of events:
 *    - View events: Appearance of views (page views), which makes it possible to track which content is seen by users
 *    - Hidden events: Custom events which can be used for measuresement of application functionalities
 *    - Media playback events (available from the SRGAnalytics_MediaPlayer subframework): Measures audio and video
 *      consumption
 *
 *  All kinds of events can be supplied arbitrary information. This information is primarily meant for use by
 *  comScore. NetMetrix currently only records view events in a fairly basic way. No distinction has been made in
 *  the use of the tracker, though. Events will be transparently sent to the services which support them, with the 
 *  data meaningful for their use.
 *
 *  ## Usage
 *
 *  Using SRGAnalytics in your application is intended to be as easy as possible. Since the analytics tracker is
 *  a singleton, you cannot currently perform measurements related to several business units within a single
 *  application, though:
 *
 *  1. Start the tracker early in your application lifecycle, for example in your application delegate
 *     `-application:didFinishLaunchingWithOptions:` implementation, by calling the
 *     `-startWithBusinessUnitIdentifier:comScoreVirtualSite:netMetrixIdentifier:` method. If the tracker is not
 *     started early enough, an `NSInternalInconsistencyException` will be thrown if a measurement is being made
 *  1. To track page views, have view controllers which must be tracked conform to the `SRGAnalyticsViewTracking`
 *     protocol. View controllers conforming to this protocol are automatically tracked by default, but this behavior 
 *     can be tailored to your needs, especially if the time at which the measurement is made (when the view
 *     appears) is inappropriate. Please refer to the `SRGAnalyticsViewTracking` documentation for more information
 *  1. When you need to track specific functionalities in your applications (e.g. the use of some interface button
 *     or of some feature of your application), send a hidden event using one of the `-trackHiddenEvent...` methods
 *     available from `SRGAnalyticsTracker`
 *  1. If you need to track media playback, you must add the SRGAnalytics_MediaPlayer subframework to your project
 *     (@see `SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h` for more information)
 *  1. If you retrieve data using our data provider library, you must add the SRGAnalytics_DataProvider subframework 
 *     to your project (@see `SRGMediaPlayerController+SRGAnalytics_DataProvider.h` for more information)
 */
@interface SRGAnalyticsTracker : NSObject

/**
 *  Tracker singleton
 */
+ (instancetype)sharedTracker;

/**
 *  Start the tracker. This is required to specify for which business unit you are tracking events, as well as to
 *  where they must be sent on the comScore and NetMetrix services. Attempting to track view, hidden or stream events
 *  without starting the tracker has no effect.
 *
 *  During tests, or if you do not want to pollute real measurements during development, you can use the special
 *  `SRGAnalyticsBusinessUnitIdentifierTEST` business unit. This business unit:
 *    - Disables NetMetrix event sending
 *    - Still sends comScore events to the specified virtual site
 *    - Adds an `srg_test` label to measurements, specifying the time at which the tracker was started as a timestamp 
 *      (yyyy-MM-dd@HH:mm). This label can be used to identify application sesssions and to gather measurements related
 *      to a session if needed
 *
 *  The [JASS proxy](https://github.com/SRGSSR/jass) tool is provided to let you peek at the analytics data sent by your 
 *  application during development or tests.
 *
 *  @discussion If the tracker is not started when a measurement is being made, an `NSInternalInconsistencyException`
 *              exception will be thrown, inviting you to start it (or to do so earlier)
 *
 *  @param businessUnitIdentifier The SRG SSR business unit for statistics measurements. Constants for the officially
 *                                supported business units are provided at the top of this file. A constant for use
 *                                during development or tests is supplied as well
 *  @param comScoreVirtualSite    Virtual sites are where comScore measurements are collected. The virtual site you must
 *                                use is usually supplied by the team in charge of measurements for your application
 *  @param netMetrixIdentifier    The identifier used to group NetMetrix measurements for your application. This value
 *                                is supplied by the team in charge of measurements for your applicatiom
 */
- (void)startWithBusinessUnitIdentifier:(NSString *)businessUnitIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier;

/**
 *  The comScore virtual site where statistics are gathered (nil if the tracker has not been started)
 */
@property (nonatomic, readonly, copy, nullable) NSString *comScoreVirtualSite;

/**
 *  The NetMetrix identifier which is used (nil if the tracker has not been started)
 */
@property (nonatomic, readonly, copy, nullable) NSString *netMetrixIdentifier;

/**
 *  Return YES iff the tracker has been started
 */
@property (nonatomic, readonly, getter=isStarted) BOOL started;

/**
 *  @name Hidden event tracking
 */

/**
 *  Send a hidden event with the specified title
 *
 *  @param title        The event title
 *
 *  @discussion If the title is empty, no event will be sent
 */
- (void)trackHiddenEventWithTitle:(NSString *)title;

/**
 *  Send a hidden event with the specified title
 *
 *  @param title        The event title
 *  @param customLabels Custom information to be sent along the event and meaningful for measurements
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix). If the title is nil, no event will be sent
 */
- (void)trackHiddenEventWithTitle:(NSString *)title customLabels:(nullable NSDictionary<NSString *, NSString *> *)customLabels;

@end

@interface SRGAnalyticsTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
