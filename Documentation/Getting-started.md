Getting started
===============

The SRG Analytics library is made of several frameworks:

* A main `SRGAnalytics.framework` which supplies the singleton responsible of gathering measurements (tracker).
* A companion optional `SRGAnalytics_MediaPlayer.framework` responsible of stream measurements for applications using our [SRG MediaPlayer library](https://github.com/SRGSSR/SRGMediaPlayer-iOS).
* A companion optional `SRGAnalytics_DataProvider.framework` transparently forwarding stream measurement analytics labels received from Integration Layer services by the [SRG DataProvider library](https://github.com/SRGSSR/srgdataprovider-ios).

## Starting the tracker

Before measurements can be collected, the tracker singleton responsible of all analytics data gathering must be started. You should start the tracker as soon as possible, usually in your application delegate `-application:didFinishLaunchingWithOptions:` method implementation. Startup requires a single configuration parameter to be provided:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:3
                                                                                             comScoreVirtualSite:@"srf-vsite"
                                                                                             netMetrixIdentifier:@"srf-app-identifier"];
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
                                                     
    // ...
}
```

The various setup parameters to use must be obtained by the team responsible of measurements for your application. You must set the configuration `centralized` boolean to `YES` if measurements for your application are analyzed by the SRG SSR General direction. 

For unit tests, you can also set the `unitTesting` flag to emit notifications which can be used to check when analytics information is sent, and whether it is correct.

Once the tracker has been started, you can perform measurements.

## Measurement information

Measurement information, often referred to as labels, is provided in the form of string dictionaries. Part of the information sent in events follows SRG measurement guidelines and is handled internally, but you can add arbitrary information for your own measurement purposes if needed (see below how this is done for the various events your application can generate).

Be careful when using custom labels, though, and ensure your custom keys do not match reserved values by using appropriate naming conventions (e.g. a prefix).

## Measuring page views

View controllers represent the units of screen interaction in an application, this is why page view measurements are primarily made on view controllers. All methods and protocols for view controller tracking have been gathered in the `UIViewController+SRGAnalytics.h` file.

View controller measurement is an opt-in, in other words no view controller is tracked by default. For a view controller to be tracked, you the recommended approach is to have it conform to the `SRGAnalyticsViewTracking` protocol. This protocol requires a single method to be implemented, returning the view controller name to be used for measurements. By default, once a view controller implements the `SRGAnalyticsViewTracking` protocol, it automatically generates a page view when it appears on screen, or when the application wakes up from background with the view controller displayed.

The `SRGAnalyticsViewTracking` protocol supplies optional methods to specify other custom measurement information (labels). If the required information is not available when the view controller appears, you can disable automatic tracking by implementing the optional `-srg_isTrackedAutomatically` protocol method, returning `NO`. You are then responsible of calling `-trackPageView` on the view controller when the data required by the page view is available.

If a view can be opened from a push notification, you must implement the `-srg_openedFromPushNotification` method and return `YES` when the view controller was actually opened from a push notification.

#### Remark

If your application needs to track views instead of view controllers, you can still perform tracking using the `-[SRGAnalyticsTracker trackPageViewWithTitle:levels:labels:fromPushNotification:]` method.

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

- (SRGAnalyticsPageViewLabels *)srg_pageViewLabels
{
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"MYAPP_CATEGORY" : @"general",
                           @"MYAPP_TIME" : @"1499319314" };
    labels.comScoreCustomInfo = @{ @"myapp_category" : @"gen" };
    return labels;
}

@end
```

When the view is opened or if the view is visible on screen when waking up the application, this information will be automatically sent.

Note that the labels might differ depending on the service they are sent to. Be sure to apply the conventions required for measurements of your application. Moreover, custom information requires the corresponding variables to be defined for TagCommander first (unlike comScore information which can be freely defined).

## Measuring application functionalities

To measure any kind of application functionality, you can use hidden events. Those can be emitted by calling the corresponding methods on the tracker singleton itself. For example, you could send the following event when the user taps on a video full-screen button within your application:

```objective-c
[[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithName:@"full-screen"];
```

Custom labels can also be used to send any additional measurement information you could need, and which might be different for TagCommander and comScore.

## Measuring SRG MediaPlayer media consumption

To measure media consumption for [SRG MediaPlayer](https://github.com/SRGSSR/SRGMediaPlayer-iOS) controllers, you need to add the `SRGAnalytics_MediaPlayer.framework` companion framework to your project. As soon the framework has been added, it starts tracking any `SRGMediaPlayerController` instance by default. 

You can disable tracking by setting the `SRGMediaPlayerController` `tracked` property to `NO`. If you don't want the player to send any media playback events, you should perform this setup before actually beginning playback. You can still toggle the property on or off at any time if needed.

Two levels of measurement information (labels) can be provided:

* Labels associated with the content being played, and which can be supplied when playing the media. Dedicated methods are available from `SRGMediaPlayerController+SRGAnalytics.h`.
* Labels associated with a segment being played, and which are supplied by having segments implement the `SRGAnalyticsSegment` protocol instead of `SRGSegment`.

When playing a segment, segment labels are superimposed to content labels. You can therefore decide to selectively override content labels by having segments return labels with matching names, if needed. 

### Example

You could have a segment return the following information:

```objective-c
@interface Segment : NSObject <SRGAnalyticsSegment>

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;

@property (nonatomic, readonly, copy) NSString *name;

// ...

@end

@implementation Segment

- (SRGAnalyticsPlayerLabels *)srg_analyticsLabels
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"MYAPP_MEDIA_ID" : self.name };
    labels.comScoreCustomInfo = @{ @"myapp_media_id" : self.name };
    return labels;
}

// ...

@end

```

and play some content, associating measurement labels with it:

```objective-c
Segment *segment = [[Segment alloc] initWithName:@"Subject" timeRange:...];
NSURL *URL = ...;

SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
labels.customInfo = @{ @"MYAPP_MEDIA_ID" : @"My media". @"MYAPP_PRODUCER" : @"RTS" };
labels.comScoreCustomInfo = @{ @"myapp_media_id" : self.name };

SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
[mediaPlayerController playURL:URL 
                        atTime:kCMTimeZero 
                  withSegments:@[segment] 
               analyticsLabels:labels
                      userInfo:nil];
```

When playing the content, tracking information sent to TagCommander will contain:

```
MYAPP_MEDIA_ID = My media
MYAPP_PRODUCER = RTS
```

but when playing the segment (after the user selects it), this information will be overridden as follows:

```
MYAPP_MEDIA_ID = Subject
MYAPP_PRODUCER = RTS
```

The mechanism is the same for information sent to comScore.

## Automatic media consumption measurement labels using the SRG DataProvider library

Our services directly supply the custom analytics labels which need to be sent with media consumption measurements. If you are using [our SRG DataProvider library](https://github.com/SRGSSR/srgdataprovider-ios) in your application, be sure to add the `SRGAnalytics_SRGDataProvider.framework` companion framework to your project as well, which will take care of all the process for you.

This framework adds a category `SRGMediaPlayerController (SRGAnalytics_DataProvider)`, which adds playback methods for media compositions to `SRGMediaPlayerController`. To play a media composition retrieved from an `SRGDataProvider` and have all measurement information automatically associated with the playback, simply call:

```objective-c
SRGRequest *request = [mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodHLS quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
    // Deal with errors, or play the URL with a media player
}];
```

on an `SRGMediaPlayerController` instance. Note that the play method returns an `SRGRequest` which must be resumed so that a token is retrieved before attempting to play the media.

Nothing more is required for correct media consumption measurements. During playback, all analytics labels for the content and its segments will be transparently managed for you.

## Measurements of other media players

If your application cannot use [SRG MediaPlayer](https://github.com/SRGSSR/SRGMediaPlayer-iOS) for media playback, you must perform media streaming measurements manually. To track playback for a media, instantiate an `SRGAnalyticsPlayerTracker` object and retain it somewhere during playback. When an event must be recorded, call the tracking method available from its public interface, specifying which kind of event must be generated and, optionally, additional labels. 

For example, you can emit a play event 6 seconds after playback started by calling:

```objective-c
[[SRGAnalyticsTracker sharedTracker] trackPlayerEvent:SRGAnalyticsPlayerEventPlay
                                           atPosition:6000
                                           withLabels:nil];
```

When using this lower-level API, though, you are entirely responsible of following SRG SSR guidelines for playback measurements. For example, you need to supply correct segment labels if the user has chosen to play a specific part of your media (none in the example above). Read [our internal documentation](https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/195595938/Implementation+Concept+-+draft) for more information.

Correctly conforming to all SRG SSR guidelines is not a trivial task, though. Please contact us if you need help.

## Thread-safety

The library is intended to be used from the main thread only. Trying to use if from background threads results in undefined behavior.
