![SRG Media Player logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## About

The SRG Analytics library for iOS makes it easy to add usage tracking information to your applications, following the SRG SSR standards.

Measurements are based on events emitted by the application, and collected by comScore and NetMetrix. Currently, the following kinds of events are supported

 * View events: Appearance of views (page views), which makes it possible to track which content is seen by users.
 * Hidden events: Custom events which can be used for measuresement of application functionalities.
 * Media playback events: Measurements for audio and video consumption in conjunction with our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS).

Moreover, if you are retrieving your data using our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios), a bridge framework is also provided so that analytics received from the service are transparently forwarded to the SRG Analytics library.
 
## Compatibility

The library is suitable for applications running on iOS 8 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 8).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage)  by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srganalytics-ios"
```

Then run `carthage update --platform iOS` to update the dependencies. You will need to manually add one or several of the `.framework`s generated in the `Carthage/Build/iOS` folder to your project, depending on your needs:

* If you need analytics only, add the following frameworks to your project:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGLogger`: The framework used for internal logging.
* If you use our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS) and want media consumption tracking as well, add the following frameworks to your project:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGAnalytics_MediaPlayer`: The media player analytics companion framework.
  * `SRGLogger`: The framework used for internal logging.
* If you use our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios) to retrieve data, add the following frameworks to your project:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `Mantle`:  The framework used to parse the data.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGAnalytics_DataProvider`: The data provider analytics companion framework.
  * `SRGAnalytics_MediaPlayer`: The media player analytics companion framework.
  * `SRGLogger`: The framework used for internal logging.
  * `SRGMediaPlayer`: The media player framework (if not already in your project).
  
For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header files using:

```objective-c
#import <SRGAnalytics/SRGAnalytics.h>	                            // For SRGAnalytics.framework
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>       // For SRGAnalytics_MediaPlayer.framework
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>     // For SRGAnalytics_DataProvider.framework
```

or directly import the modules themselves:

```objective-c
@import SRGAnalytics;                    // For SRGAnalytics.framework
@import SRGAnalytics_MediaPlayer;        // For SRGAnalytics_MediaPlayer.framework
@import SRGAnalytics_DataProvider;		 // For SRGAnalytics_DataProvider.framework
```

### Usage from Swift source files

Import the modules where needed:

```swift
import SRGAnalytics                     // For SRGAnalytics.framework
import SRGAnalytics_MediaPlayer         // For SRGAnalytics_MediaPlayer.framework
import SRGAnalytics_DataProvider        // For SRGAnalytics_DataProvider.framework
```

### Info.plist settings for application installation measurements

The library automatically tracks which SRG SSR applications are installed on a user device, and sends this information to comScore. For this mechanism to work properly, though, your application **must** declare all official SRG SSR application URL schemes as being supported in its `Info.plist` file. 

This can be achieved as follows:

* Run the `LSApplicationQueriesSchemesGenerator.swift ` script found in the `Scripts` folder. This script automatically generates an `LSApplicationQueriesSchemesGenerator.plist` file in the folder you are running it from, containing an up-to-date list of SRG SSR application schemes.
* Open the generated `plist` file and either copy the `LSApplicationQueriesSchemes` to your project `Info.plist` file, or merge it with already existing entries.

If URL schemes declared by your application do not match the current ones, application installations will not be accurately reported to comScore, and error messages will be logged when the application starts (see _Logging_ below). This situation is not catastropic but should be fixed when possible to ensure better measurements.

#### Remark

The number of URL schemes an application declares is limited to 50. Please contact us if you happen to reach this limit.

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](Documentation/Getting-started.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, with the following subsystems:

* `ch.srgssr.analytics` for `SRGAnalytics.framework` events.
* `ch.srgssr.analytics.mediaplayer` for `SRGAnalytics_MediaPlayer.framework` events.
* `ch.srgssr.analytics.dataprovider` for `SRGAnalytics_DataProvider.framework` events.

This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

## Demo project

To test what the library is capable of, run the associated demo.

## Migration from versions 1.x

For information about changes introduced with version 2 of the library, please read the [migration guide](Documentation/Migration-guide.md).

## License

See the [LICENSE](LICENSE) file for more information.