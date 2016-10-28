![SRG Media Player logo](README-images/logo.png)

## About

The SRG Analytics library for iOS is the easiest way to fulfill SRG application analytics needs:

* The library automatically sends comScore, view counts and NET-Metrix events
* When using the [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS), it also tracks all associated Stream Sense events

## Compatibility

The library is suitable for applications running on iOS 8 and above.

## Installation

The library can be added to a project through [CocoaPods](http://cocoapods.org/) version 1.0 or above. Create a `Podfile` with the following contents:

* The SRG specification repository:
    
```
#!ruby
    source 'https://github.com/SRGSSR/srgpodspecs-ios.git'
```
    
* The `SRGAnalytics` dependency:

```
#!ruby
    pod 'SRGAnalytics', '<version>'
```

* To add optional support for the [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS):

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

* `ComscoreVirtualSite` (mandatory): virtual site where comScore view and hidden events will be sent
* `StreamSenseVirtualSite` (optional): virtual site where streamSense events will be sent. If not set, uses `ComscoreVirtualSite`
* `NetmetrixAppID` (mandatory): NET-Metrix application identifier

By using custom build settings variables, it is possible to provide different values for different configurations (Debug, Beta, Release, etc.) with a single `Info.plist` file.

### Installed applications tracking

The library automatically tracks which SRG SSR applications are installed on a user device, and sends this information to comScore. For this mechanism to work properly, though, your application **must** declare all official SRG SSR application URL schemes as being supported in its `Info.plist` file. This is achieved as follows:

* Open your application `Info.plist` file
* Add the `LSApplicationQueriesSchemes` key if it does not exist, and ensure that the associated array of values **is a superset of all URL schemes** found at the [following URL](http://pastebin.com/raw/RnZYEWCA). The schemes themselves must be extracted from all `ios` dictionary keys (e.g. `playrts`, `srfplayer`)

If this setup is not done appropriately, application installations will be reported incorrectly to comScore, and an error message will be logged. This situation is not catastropic but should be fixed when possible to ensure accurate measurements.

Since the list available from the above URL might change from time to time, the warning might resurface later to remind you to update your `Info.plist` file accordingly. Be sure to check your application logs.

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