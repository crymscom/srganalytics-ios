//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTSAnalyticsPageViewDataSource.h"
#import "RTSAnalyticsMediaPlayerDataSource.h"

/**
 *  RTSAnalyticsTracker is used to track view events and stream measurements for SRG/SSR apps.
 *
 *  Analytics Tracker takes care of sending Comscore and Netmetrix page view events and Streamsense stream measurements.
 */
@interface RTSAnalyticsTracker : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing an Analytics Tracker
 *  --------------------------------------------
 */

/**
 *  Singleton instance of the tracker.
 *
 *  @return Tracker's Instance
 */
+ (instancetype)sharedTracker;

/**
 *  Starts the tracker for page views and streams played with RTSMediaPlayerController.
 *
 *  @param dataSource the datasource which provides labels/playlist/clip for Streamsense tracker. (Mandatory)
 *
 *  @discussion the tracker uses values set in application Info.plist to track Comscore, Streamsense and Netmetrix measurement. 
 *  Add an Info.plist dictionary named `RTSAnalytics` with 4 keypairs :
 *              ComscoreVirtualSite    : string - mandatory
 *              StreamsenseVirtualSite : string - mandatory
 *              NetmetrixAppID         : string - NetmetrixAppID MUST be set ONLY for application in production.
 *	            NetmetrixDomain        : string - optionnal - if not set, the domain will use the calculated BusinessUnit string based on the application bundleIdentifier.
 *
 *  The application MUST call `-startTrackingWithMediaDataSource:` ONLY in `-application:didFinishLaunchingWithOptions:`.
 */
- (void)startTrackingWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource OS_NONNULL_ALL;

/**
 *  --------------------------------------------
 *  @name View Tracking
 *  --------------------------------------------
 */

/**
 *  Track a view event with specified dataSource. 
 *  It will retrieve the page view labels dictionary from methods defined in `RTSAnalyticsPageViewDataSource` protocol.
 *
 *  @param dataSource the dataSource implementing the `RTSAnalyticsPageViewDataSource` protocol. (Mandatory)
 *
 *  @discussion the method is automatically called by UIViewController implementing `RTSAnalyticsPageViewDataSource` protocol, @see `RTSAnalyticsPageViewDataSource`.
 *  The method can be called manually to send view events when changing page content without presenting a new UIViewController:
 *  by ex. when using UISegmentedControl, or when filtering data using the same UIViewController instance.
 *
 *  The methods is also automatically called when the app becomes active again. A reference of the last page view datasource is kept by the tracker.
 */
- (void)trackPageViewForDataSource:(id<RTSAnalyticsPageViewDataSource>)dataSource;

/**
 *  Track a view event identified by its title and levels labels. 
 *  Helper method which call `-(void)trackPageViewTitle:levels:fromPushNotification:` with no custom labels and fromPush value to `NO`
 *
 *  @param title    the page title tracked by Comscore. (Mandatory)
 *  @param levels   each levels value will be set as `srg_nX` labels and concatenated into `category` label. (Optional)
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels;

/**
 *  Track a view event identified by its title, levels labels and origin (user opening the page view from push notification or not).
 *
 *  @param title        the page title tracked by Comscore (set as `srg_title` label). (Mandatory)
 *                      The title value is "normalized" using `-(NSString *)comScoreFormattedString` from `NSString+RTSAnalyticsUtils` category.
 *                      An empty or nil title will be replaced with `Untitled` value.
 *  @param levels       a list of strings. Each level will be set as srg_nX (srg_n1, srg_n2, ...) label and will be concatenated in `category` label. (Optional)
 *  @param customLabels a dictionary of key values that will be set a labels when sending view events. Persistent labels can be overrided by those custom labels values.
 *  @param fromPush     YES, if the UIViewController has been opened from a push notification, NO otherwise.
 *
 *  @discussion if the levels array is nil or empty, then one level called `srg_n1` is added with default value `app`.
 *  Each level value is "normalized" using `-(NSString *)comScoreFormattedString` from `NSString+RTSAnalyticsUtils` category.
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels customLabels:(NSDictionary *)customLabels fromPushNotification:(BOOL)fromPush;

@end
