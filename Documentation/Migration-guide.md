Migrating from verson 1.x to version 2
======================================

Version 2 of the SRG Analytics library introduces several changes which require you to migrate your existing code base. 

## Carthage

Support for CocoaPods has been removed. Since the framework requires at least iOS 8, using CocoaPods does not make sense anymore. Carthage is both simple and elegant, and will therefore be used in the future for integration into your project. Refer to the [official documentation](https://github.com/Carthage/Carthage) for more information about how to use the tool (don't be afraid, this is very simple).

## Prefix changes

For historical reasons, all classes were prefixed with `RTS`, which was misleading. This prefix has now been replaced with `SRG`. Be sure to update existing references in your code (a simple text search suffices).

## Reduced complexity

Several data sources were previously available to customize measurement data (labels). These mechanisms have been completely eliminated in favor of simple dictionaries. Instead of having a data source indirectly supplying labels when required, you now:

* Supply labels associated with the content being played when actually playing it (see `SRGMediaPlayerController+SRGAnalytics.h`)
* Attach segment labels to segments themselves (see `SRGAnalyticsSegment` protocol)

Moreover, you could previously generate view events from the tracker interface, which was redundant with the view controller tracking mechanism available from a `UIViewController` category and a companion protocol. To make tracker use more intuitive, view event management has therefore been completely removed from the tracker public interface.

## Tracker initialization

In versions 1.x of the library, tracker configuration was made in two different places:

* When calling the tracker start method
* In the `Info.plist` file

Having configuration in two places was not atomic. This is why configuration is now entirely specified when starting the tracker.

The debug mode boolean was also removed. A dedicated test business unit `SRGAnalyticsBusinessUnitIdentifierTEST` has been introduced instead.

## Media player tracker initialization

Media tracker initialization is now entirely automatic (it uses the settings of the main tracker), no start method call is required anymore. Just add the dedicated framework to your project and you are ready to go.
