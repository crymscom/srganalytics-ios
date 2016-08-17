![SRG Media Player logo](README-images/logo.png)

## About

The SRG Analytics library for iOS is the easiest way to fulfill SRG application analytics needs:

* The library automatically sends comScore, view counts and NET-Metrix events
* When using the [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS), it also tracks all associated Stream Sense events

## Compatibility

The library is suitable for applications running on iOS 8 and above.

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage)  by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srganalytics-ios"
```

Then run `carthage update` to update the dependencies. You will need to manually add one or several of the `.framework`s generated in the `Carthage/Build/iOS` folder to your projet, depending on your needs:

* Add `SRGAnalytics.framework` as well as `ComScore.framework`. If you only need view and hidden event tracking, these are the only frameworks required
* If you need media player tracking, add `SRGAnalytics_MediaPlayer.framework` as well. Do not forget to add the `SRGMediaPlayer.framework` available from the same directory if your project wasn't already linking against it

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

## Usage

The following discusses how the library can be added to most applications.

### Initalization

In the method `-application:didFinishLaunchingWithOptions:` method of your application delegate, call:

```
#!objective-c
    [[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:businessUnit];

```

where `businessUnit` is one of the SRG business units as declared by the `SSRBusinessUnit` enum. This call initializes the analytics tracker, which is the central access point for event tracking. The `RTSAnalyticsTracker` provides all the needed methods for view and event tracking.

If you have included `SRGAnalytics_MediaPlayer.framework` for media player tracking, also call the `-startStreamMeasurementWithMediaDataSource:` method to track associated events:

```
#!objective-c
    [[RTSAnalyticsTracker sharedTracker] startStreamMeasurementWithMediaDataSource:dataSource];

```

providing a `dataSource` conforming to the `RTSAnalyticsMediaPlayerDataSource` protocol. This data source lets you customize which labels are sent to Stream Sense but, in general, simply calling the above method is all which is required to track media player events.

### Configuration

Your app `Info.plist` file must contains a dictionary section called `RTSAnalytics` containing the following key-value pairs: 

* `ComscoreVirtualSite` (mandatory): virtual site where comScore view and hidden events will be sent
* `StreamSenseVirtualSite` (optional): virtual site where streamSense events will be sent. If not set, uses `ComscoreVirtualSite`. Only used if `SRGAnalytics_MediaPlayer.framework` is included
* `NetmetrixAppID` (mandatory): NET-Metrix application identifier

By using custom build settings variables, it is possible to provide different values for different configurations (Debug, Beta, Release, etc.) with a single `Info.plist` file.

### Tracking view counts for view controllers

Each view controller which requires page view tracking must conform to the  `RTSAnalyticsPageViewDataSource` protocol, and implement the associated required method. View events will then automatically be sent when your view controller is presented. 

In some cases, though, it might make sense to disable this automatic view event tracking, e.g. when you need more fine-grained control over how and when view events are sent. This can be achieved by implementing the `-isTrackedAutomatically` method of the above protocol to return `NO`. You must then manually call `-[UIViewController trackPageView]` on a view controller when a corresponding page view must be recorded.

Further optional information can be provided when a page view event is sent, have a look at the `RTSAnalyticsPageViewDataSource` header file for more information.

### Tracking media players

By default all media players are tracked, and associated Stream Sense events sent. You can disable this behavior by setting the `tracked` property of a media player controller to `NO`. 

Note that `RTSMediaPlayerViewController` instances are automatically tracked. Since the underlying controller is currently not publicly exposed, you cannot change this default behavior at the moment.

### Hidden events

You can track any user behavior or functionality within your application using hidden events and custom labels. For example, you might want to track when the user activates some functionality or taps on some button of your interface.

To send a hidden event, use `-trackHiddenEventWithTitle:` or `-trackHiddenEventWithTitle:customLabels:` methods of `RTSAnalyticsTracker`. You can provide any kind of helpful information in the associated labels depending on the measurements you want to make.

### Push notifications

To track view controllers opened through push notifications, implement the optional `-pageViewFromPushNotification` method of the `RTSAnalyticsPageViewDataSource` protocol and return `YES` iff opened from a push notification.

## License

See the [LICENSE](LICENSE) file for more information.