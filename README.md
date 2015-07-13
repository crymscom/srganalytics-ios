![SRG Media Player logo](https://bitbucket.org/rtsmb/srganalytics-ios/raw/develop/README-images/logo.png)

## About

The SRG Analytics library for iOS provides a simple way to provide all necessary SRG SSR app analytics. It automatically sends comScore, viewCount and netMetrix events. When using a SRG MediaPlayer, it also tracks all the streamSense events.

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

* To add the SRGMediaPlayer support:

```
#!ruby
    pod 'SRGAnalytics/MediaPlayer'
```

It is preferable to not provide a version number for the sub-spec SRGMediaPlayer.

Then run `pod install` to update the dependencies.

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).


## Usage

In your app delegate, in the method `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`, simply add:


```
#!objective-c
    [[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:<put here one of the SRG SSR business unit>
                                                        launchOptions:launchOptions
                                                      mediaDataSource:<put here the instance of your data provider>];

```

Moreover, your app Info.plist file must contains a dictionary section called 'RTSAnalytics' (this will soon be made compatible with 'SRGAnalytics' naming as well), containing values for the following keys: 'ComscoreVirtualSite', 'NetmetrixAppID', 'StreamsenseVirtualSite'. By using custom build settings variables, it is possible to provide different values for different configurations (Debug, Beta, Release etc...)

**Important Note:** By default, the flag 'production' is set to 'NO' to avoid sending useless statistics. It means that none of the statistics will be sent in such state. If you want to test your app in 'beta' stage, set this flag to 'YES' and provide dedicated 'site' values to the keys above.


## License

See the [LICENSE](LICENSE) file for more information.