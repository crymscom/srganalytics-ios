Migrating from version 2 to version 3
=======================================

Version 3 of the SRG Analytics library introduces TagCommander support, as well as breaking changes requiring you to migrate your existing code base.

## Dependencies

TagCommander `TCCore.framework` and `TCSDK.framework` now need to be linked with your project.

## Tracker initialization

Tracker setup is now performed via a configuration object. A container identifier is required for TagCommander measurements. Contact your measurement team for more information about which one your application must use.

## Labels

You need to migrate custom data you previously sent to comScore so that it is now sent to TagCommander. 

Since TagCommander requires variables to be explicitly defined on its portal to collect the associated data, you might need to discuss custom labels you previously used with your measurement team. 

In particular, hidden events are therefore now provided with three predefined variables (type, value and source) which you should now use most of the time to convey custom data. There is still possibility to send arbitrary values to TagCommander, but those need to be discussed with your measurement team first.

## comScore to TagCommander transition

During the initial comScore to TagCommander transition, both services will coexist. Labels you currently send to comScore must therefore still be transmitted during the transition phase, so that analysts can check the consistency of the reports they produce.

New label classes `SRGAnalyticsHiddenEventLabels` and `SRGAnalyticsPageViewLabels` have been introduced to send this information to both services with a single unified formalism. All tracking methods and protocols have been updated and now work with such objects instead of the raw dictionaries used in version 2.

When the transition is complete, a minor version of the SRG Analytics library will be released, at which point you will be able to remove all comScore-related logic from your project.

Migrating from version 1 to version 2
=======================================

Version 2 of the SRG Analytics library introduces several changes which require you to migrate your existing code base. 

## Carthage

Support for CocoaPods has been removed. Since the framework requires at least iOS 8, using CocoaPods does not make sense anymore. Carthage is both simple and elegant, and will therefore be used in the future for integration into your project. Refer to the [official documentation](https://github.com/Carthage/Carthage) for more information about how to use the tool (don't be afraid, this is very simple).

## Prefix changes

For historical reasons, all classes were prefixed with `RTS`, which was misleading. This prefix has now been replaced with `SRG`. Be sure to update existing references in your code (a simple text search suffices).

## Reduced complexity

Several data sources were previously available to customize measurement data (labels). These mechanisms have been completely eliminated in favor of simple dictionaries. Instead of having a data source indirectly supplying labels when required, you now:

* Supply labels associated with the content being played when actually playing it (see `SRGMediaPlayerController+SRGAnalytics.h`).
* Attach segment labels to segments themselves (see `SRGAnalyticsSegment` protocol).

## Tracker initialization

In versions 1.x of the library, tracker configuration was made in two different places:

* When calling the tracker start method.
* In the `Info.plist` file.

Having configuration in two places was not atomic. This is why configuration is now entirely specified when starting the tracker.

The debug mode boolean was also removed. A dedicated test business unit `SRGAnalyticsBusinessUnitIdentifierTEST` has been introduced instead.

## Media player tracker initialization

Media tracker initialization is now entirely automatic (it uses the settings of the main tracker), no start method call is required anymore. Just add the dedicated framework to your project and you are ready to go.
