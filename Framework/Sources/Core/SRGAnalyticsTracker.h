//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@protocol SRGAnalyticsPageViewDataSource;

/**
 * SRG/SSR Business units
 */
typedef NS_ENUM(NSInteger, SSRBusinessUnit) {
	/**
	 *  Business unit for Schweizer Radio und Fernsehen (SRF)
	 *
	 *  - Comscore value   : "sfr"
	 *  - Netmetrix domain : "sfr"
	 */
	SSRBusinessUnitSRF,
	
	/**
	 *  Business unit for Radio Télévision Suisse (RTS)
	 *
	 *  - Comscore value   : "rts"
	 *  - Netmetrix domain : "rts"
	 */
	SSRBusinessUnitRTS,
	
	/**
	 *  Business unit for Radiotelevisione svizzera (RSI)
	 *
	 *  - Comscore value   : "rsi"
	 *  - Netmetrix domain : "SRGi"
	 */
	SSRBusinessUnitRSI,
	
	/**
	 *  Business unit for Radiotelevisiun Svizra Rumantscha (RTR)
	 *
	 *  - Comscore value   : "rtr"
	 *  - Netmetrix domain : "rtr"
	 */
	SSRBusinessUnitRTR,
	
	/**
	 *  Business unit for Swissinfo (SWI)
	 *
	 *  - Comscore value   : "swi"
	 *  - Netmetrix domain : "swissinf"
	 */
	SSRBusinessUnitSWI
	
};

/**
 *  -------------------
 *  @name Notifications
 *  -------------------
 */

/**
 *  Posted when the request's response is received. The `object` of the notification is a NSURLRequest.
 */
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixRequestDidFinishNotification;

/**
 * A NSNumber (boolean) indicating success in the user info dictionary of `SRGAnalyticsNetmetrixRequestDidFinishNotification`.
 */
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixRequestSuccessUserInfoKey;

/**
 *  A NSError in the user info dictionary of `SRGAnalyticsNetmetrixRequestDidFinishNotification`. This key is not present if the request succeeded.
 */
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixRequestErrorUserInfoKey;

/**
 *  A NSURLResponse in the user info dictionary of `SRGAnalyticsNetmetrixRequestDidFinishNotification`.
 */
OBJC_EXTERN NSString * const SRGAnalyticsNetmetrixRequestResponseUserInfoKey;

OBJC_EXTERN NSString * const SRGAnalyticsWillSendRequestNotification;
OBJC_EXTERN NSString * const SRGAnalyticsLabelsKey;

/**
 *  SRGAnalyticsTracker is used to track view and hidden events for SRGSSR apps
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
 *  The application MUST call `-startTrackingForBusinessUnit:...` methods ONLY in `-application:didFinishLaunchingWithOptions:`.
 */
- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
             withComScoreVirtualSite:(NSString *)comScoreVirtualSite
                 netMetrixIdentifier:(NSString *)netMetrixIdentifier
                           debugMode:(BOOL)debugMode;

/**
 *  --------------------
 *  @name Tracker Object
 *  --------------------
 */

/**
 *  The ComScore virtual site to be used for sending stats.
 */
@property (nonatomic, readonly, strong) NSString *comScoreVirtualSite;

/**
 *  The NetMetrix application name to be used for view event tracking.
 */
@property (nonatomic, readonly, strong) NSString *netMetrixIdentifier;

/**
 *  Return the business unit identifier
 *
 *  @param businessUnit the business unit
 *
 *  @return the corresponding identifier
 */
- (NSString *)businessUnitIdentifier:(SSRBusinessUnit)businessUnit;

/**
 *  Returns the business unit depending on its identifier
 *
 *  @param buIdentifier the identifier string like 'srf', 'SRG', 'rsi', 'rtr', 'swi'
 *
 *  @return the corresponding business unit
 */
- (SSRBusinessUnit)businessUnitForIdentifier:(NSString *)buIdentifier;

/**
 *  -------------------
 *  @name View Tracking
 *  -------------------
 */

/**
 *  Track a view event with specified dataSource. 
 *  It will retrieve the page view labels dictionary from methods defined in `SRGAnalyticsPageViewDataSource` protocol.
 *
 *  @param dataSource the dataSource implementing the `SRGAnalyticsPageViewDataSource` protocol. (Mandatory)
 *
 *  @discussion the method is automatically called by view controllers conforming the `SRGAnalyticsPageViewDataSource` protocol, 
 *  @see `SRGAnalyticsPageViewDataSource`. The method can be called manually to send view events when changing page content 
 *  without presenting a new view controller:, e.g. when using UISegmentedControl, or when filtering data using the same view
 *  controller instance.
 *
 *  The methods is also automatically called when the app becomes active again. A reference of the last page view datasource is 
 *  kept by the tracker.
 */
- (void)trackPageViewForDataSource:(id<SRGAnalyticsPageViewDataSource>)dataSource;

/**
 *  Track a view event identified by its title and levels labels. 
 *  Helper method which calls `-(void)trackPageViewTitle:levels:fromPushNotification:` with no custom labels and fromPush value to `NO`
 *
 *  @param title    the page title tracked by Comscore. (Mandatory)
 *  @param levels   each levels value will be set as `srg_nX` labels and concatenated into the `category` label. (Optional)
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels;

/**
 *  Track a view event identified by its title, levels labels and origin (user opening the page view from a push notification or not).
 *
 *  @param title        the page title tracked by Comscore (set as `srg_title` label). (Mandatory)
 *                      The title value is "normalized" using `srg_comScoreFormattedString` from `NSString+SRGAnalyticsUtils` category.
 *                      An empty or nil title will be replaced with `Untitled` value.
 *  @param levels       a list of strings. Each level will be set as srg_nX (srg_n1, srg_n2, ...) label and will be concatenated in `category` 
 *                      label. (Optional)
 *  @param customLabels a dictionary of key values that will be set a labels when sending view events. Persistent labels can be overrided with those 
 *                      custom labels values.
 *  @param fromPush     YES, if the view controller has been opened from a push notification, NO otherwise.
 *
 *  @discussion if the levels array is nil or empty, then one level called `srg_n1` is added with default value `app`.
 *  Each level value is "normalized" using `srg_comScoreFormattedString` from `NSString+SRGAnalyticsUtils` category.
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels customLabels:(NSDictionary *)customLabels fromPushNotification:(BOOL)fromPush;

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
- (void)trackHiddenEventWithTitle:(NSString *)title customLabels:(NSDictionary *)customLabels;

@end
