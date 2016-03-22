![SRG Media Player logo](README-images/logo.png)

## About

The SRG Analytics library for iOS is the easiest way to fulfill SRG application analytics needs:

* The library automatically sends comScore, view counts and NET-Metrix events
* When using the [SRG Media Player library](https://bitbucket.org/rtsmb/srgmediaplayer-ios), it also tracks all associated Stream Sense events

## Compatibility

The library is suitable for applications running on iOS 7 and above.

## Installation

The library can be added to a project through [CocoaPods](http://cocoapods.org/). Create a `Podfile` with the following contents:

* The SRG specification repository:
    
```
#!ruby
    source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
```
    
* The `SRGAnalytics` dependency:

```
#!ruby
    pod 'SRGAnalytics', '<version>'
```

* To add optional support for the [SRG Media Player library](https://bitbucket.org/rtsmb/srgmediaplayer-ios):

```
#!ruby
    pod 'SRGAnalytics/MediaPlayer'
```

It is preferable not to provide a version number for the `SRGMediaPlayer` subspec.

Then run `pod install` to update the dependencies.

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).

## Usage

The following discusses how the library can be integrated for most applications:

### Initalization

In the method `-application:didFinishLaunchingWithOptions:` method of your application delegate, simply call:

```
#!objective-c
    [[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:businessUnit];

```

where `businessUnit` is one of the SRG business units as declared by the `SSRBusinessUnit` enum. If you have included support for the SRG Media Player library, call instead:

```
#!objective-c
    [[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:businessUnit
                                                      mediaDataSource:dataSource];

```

providing a `dataSource` conforming to the `RTSAnalyticsMediaPlayerDataSource` protocol. This data source lets you further customize which labels are sent to Stream Sense. Please refer to the `RTSAnalyticsMediaPlayerDataSource` protocol documentation for more information.

### Configuration

Your app `Info.plist` file must contains a dictionary section called `RTSAnalytics` containing the following key-value pairs: 

* `ComscoreVirtualSite`: comScore virtual site
* `NetmetrixAppID`: NET-Metrix application identifier

By using custom build settings variables, it is possible to provide different values for different configurations (Debug, Beta, Release, etc.) with a single `Info.plist` file.

### Tracking view counts for view controllers

For each view controller which requires tracking, like a page view event, you have it explicitly conform to the `RTSAnalyticsPageViewDataSource` protocol, and implement the associated required method. This is all you need to do, view events will then automatically be sent when your view controller is presented.

You can provide further optional information, please have a look at the `RTSAnalyticsPageViewDataSource` header file.

### Tracking media players

By default, all media players are tracked, and associated Stream Sense events sent. You can disable this behavior by setting the `tracked` property of a media player controller to `NO`. 

Note that `RTSMediaPlayerViewController` instances are automatically tracked. Since the underlying controller is currently not publicly exposed, you cannot change this default behavior at the moment.

### Push notifications

To track view controllers opened through push notifications, implement the optional `-pageViewFromPushNotification` method of the `RTSAnalyticsPageViewDataSource` protocol and return `YES` iff opened from a push notification.

## License

See the [LICENSE](LICENSE) file for more information.