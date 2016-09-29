Getting started
===============

The SRG Analytics library is made of several frameworks:

* A main `SRGAnalytics.framework` which supplies the singleton responsible of gathering measurements (tracker)
* A companion optional `SRGAnalytics_MediaPlayer.framework` responsible of stream measurements for applications using our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS)
* A companion optional `SRGAnalytics_DataProvider.framework` transparently forwarding analytics labels received when using our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios)


## Starting the tracker

Before measurements can be collected, the tracker singleton responsible of all analytics data gathering must be started. You must start the tracker as soon as possible, usually in your application delegate `-application:didFinishLaunchingWithOptions:` method implementation. For example:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                     comScoreVirtualSite:@"srg-vsite"
                                                     netMetrixIdentifier:@"srf-app-identifier"];
                                                     
    // ...
                                                     
    return YES;
}
```

Once the tracker has been started, you can perform measurements. You can use the special `SRGAnalyticsBusinessUnitIdentifierTEST` for tests or during development.

### Remark

If the tracker is not started, or not soon enough, an `NSInternalInconsistencyException` will be thrown when a measurement is performed. This exception is a programmer error hint and will never be encountered if startup was correctly made.

## Measurement information

Measurement information is often referred to as labels. Labels are plain dictionaries of string keys and values. Part of the information sent in events follows SRG measurement guidelines and is handled internally, but you can add arbitrary information for your own measurement purposes, if needed (see below how this is done for the various events your application can generate).

Be careful when using custom labels, though, and ensure your custom keys do not match reserved values by using appropriate naming conventions (e.g. a prefix).

## Measuring page views

View controllers represent the units of screen interaction in an application, this is why page view measurements are made on view controllers. All necessary methods and protocols have been gathered in the `UIViewController+SRGAnalytics.h` file.

View controller measurement is an opt-in, in other words no view controller is tracked by default. For a view controller to be tracked, you need to conform it to the `SRGAnalyticsViewTracking` protocol. This protocol requires a single method to be implemented, returning the view controller name to be used for measurements. By default, once a view controller implements the `SRGAnalyticsViewTracking` protocol, it automatically generates a page view when it did appear on screen, or if it is displayed when the application wakes up from background.

The `SRGAnalyticsViewTracking` protocol supplies optional methods to specify other custom measurement information (labels). If this information (or the title to be used) is not available when the view controller appears, you can disable automatic tracking by implementing the optional `-srg_isTrackedAutomatically` protocol method, returning `NO`. You are then responsible of calling `-trackPageView` on the view controller when you want to perform measurements.

If a view can be opened from a push notification, you must implement the `-srg_openedFromPushNotification` method and return `YES` when the view controller was actually opened from a push notification.

### Example

Consider you have a `HomeViewController` view controller you want to track. First make it conform to the `SRGAnalyticsViewTracking` protocol:

```objective-c
@interface HomeViewController : UIViewController <SRGAnalyticsViewTracking>

@end
```

and implement the methods you need to supply measurement information:

```objective-c
@implementation HomeViewController

// Mandatory
- (NSString *)srg_pageViewTitle
{
	return @"home";
}

- (NSDictionary<NSString *, NSString *> *)srg_pageViewCustomLabels
{
	return @{ @"myapp_category" : @"general" };
}

@end
```

When the view is opened or if the view is visible on screen when waking up the application, this information will be automatically sent.

## Measuring application functionalities

To measure the use of other application functionalities, you can use hidden events. Those can be emitted by calling the corresponding methods on the tracker singleton itself. For example, you could send the following event when the user taps on a video full-screen button within your application:

```objective-c
[[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"full-screen" customLabels:@{ @"myapp_enabled" : @"true" }];
```

Custom labels can be used to send any additional measurement information you could need.

## Measuring media consumption

To measure media consumption, you need to add the `SRGAnalytics_MediaPlayer.framework` companion framework to your project. As soon the framework has been added, it starts tracking any `SRGMediaPlayerController` instance by default. 

You can disable tracking by setting the `SRGMediaPlayerController` `tracked` property to `NO`. If you don't want the player to send any media playback events, you do so before beginning playback. You can still toggle the property on or off at any time.

Two levels of custom measurement information (labels) can be provided:

* Labels associated with the content being played, and which can be supplied when playing the media
* Labels associated with a segment being played

When playing a segment, segment labels are superimposed to content labels. You can therefore decide to selectively override content labels by having segments return labels with matching names, if needed.

To provide custom labels, implement the `SRGAnalyticsMediaPlayerTrackingDelegate` and provide the delegate when using one of the playback methods available from the `SRGMediaPlayerController (SRGAnalytics)` category.
