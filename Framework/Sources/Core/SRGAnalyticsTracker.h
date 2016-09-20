//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Official SRGSSR business units
 */

OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRSI;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRTR;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierRTS;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierSRF;
OBJC_EXPORT NSString * const SRGAnalyticsBusinessUnitIdentifierSWI;

/**
 *  The analytics tracker is a singleton instance responsible of tracking usage of an application.
 *
 *  TODO: Describe use and available events
 */
@interface SRGAnalyticsTracker : NSObject

/**
 *  ---------------------------------------
 *  @name Initializing an Analytics Tracker
 *  ---------------------------------------
 */

/**
 *  Singleton instance of the tracker.
 *
 *  @return Tracker's Instance
 */
+ (instancetype)sharedTracker;

/**
 *  Start tracking page events
 *
 *  @param businessUnit  the SRGSSR business unit for statistics measurements
 *  @param debugMode     if set to YES, an `srg_test` field is added to the labels with a timestamp (yyyy-MM-dd@HH:mm) as value. This value does not
 *                       change while the application is running and can therefore be used to identify requests belonging to the same session.
 *                       Methods without this parameter are equivalent to debugMode = NO
 *
 *  @discussion the tracker uses values set in application Info.plist to track Comscore and Netmetrix measurement.
 *
 *  Add an Info.plist dictionary named `SRGAnalytics` with 2 keypairs :
 *              ComscoreVirtualSite    : string - mandatory
 *              NetmetrixAppID         : string - NetmetrixAppID MUST be set ONLY for application in production.
 *
 *  Remark: The NetMetrix "test" identifier can be used for tests
 *
 *  The application MUST call `-startTrackingForBusinessUnit:...` methods ONLY in `-application:didFinishLaunchingWithOptions:`.
 */
- (void)startWithBusinessUnitIdentifier:(NSString *)businessUnitIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier
                              debugMode:(BOOL)debugMode;

/**
 *  The ComScore virtual site to be used for sending stats.
 */
@property (nonatomic, readonly, copy) NSString *comScoreVirtualSite;

/**
 *  The NetMetrix application name to be used for view event tracking.
 */
@property (nonatomic, readonly, copy) NSString *netMetrixIdentifier;

/**
 *  Track a (hidden) event identified by its title
 *
 *  @param title        The event title.
 *                      An empty or nil title will be replaced with `Untitled` value.
 */
- (void)trackHiddenEventWithTitle:(NSString *)title;

/**
 *  Track a (hidden) event identified by its title
 *
 *  @param title        The event title.
 *                      An empty or nil title will be replaced with `Untitled` value.
 */
- (void)trackHiddenEventWithTitle:(NSString *)title customLabels:(nullable NSDictionary<NSString *, NSString *> *)customLabels;

@end

@interface SRGAnalyticsTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
