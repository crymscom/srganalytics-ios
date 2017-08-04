//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "NSBundle+SRGAnalytics.h"
#import "NSMutableDictionary+SRGAnalytics.h"
#import "NSString+SRGAnalytics.h"
#import "SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNetMetrixTracker.h"
#import "SRGAnalyticsNotifications.h"
#import "UIViewController+SRGAnalytics.h"

#import <ComScore/ComScore.h>
#import <ComScore/CSTaskExecutor.h>
#import <TCSDK/TCSDK.h>

SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRSI = @"rsi";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTR = @"rtr";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierRTS = @"rts";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRF = @"srf";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSRG = @"srg";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI = @"swi";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierTEST = @"test";

@interface SRGAnalyticsTracker ()

@property (nonatomic, copy) NSString *businessUnitIdentifier;
@property (nonatomic) NSInteger containerIdentifier;
@property (nonatomic, copy) NSString *comScoreVirtualSite;
@property (nonatomic, copy) NSString *netMetrixIdentifier;
@property (nonatomic, getter=isStarted) BOOL started;

@property (nonatomic) TagCommander *tagCommander;
@property (nonatomic) SRGAnalyticsNetMetrixTracker *netmetrixTracker;
@property (nonatomic) CSStreamSense *streamSense;

@end

@implementation SRGAnalyticsHiddenEventLabels

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"event_type"];
    [dictionary srg_safelySetString:self.value forKey:@"event_value"];
    [dictionary srg_safelySetString:self.source forKey:@"event_source"];
    
    if (self.customInfo) {
        [dictionary addEntriesFromDictionary:self.customInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"srg_evgroup"];
    [dictionary srg_safelySetString:self.value forKey:@"srg_evvalue"];
    [dictionary srg_safelySetString:self.source forKey:@"srg_evsource"];
    
    if (self.comScoreCustomInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreCustomInfo];
    }
    
    return [dictionary copy];
}

@end

@implementation SRGAnalyticsPageViewLabels

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    if (self.customInfo) {
        [dictionary addEntriesFromDictionary:self.customInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    if (self.comScoreCustomInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreCustomInfo];
    }
    
    return [dictionary copy];
}

@end

@implementation SRGAnalyticsTracker

#pragma mark Class methods

+ (instancetype)sharedTracker
{
    static SRGAnalyticsTracker *s_sharedInstance = nil;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_sharedInstance = [SRGAnalyticsTracker new];
    });
    return s_sharedInstance;
}

#pragma mark Getters and setters

// FIXME: Once the pilot phase is over, remove this implementation so that the container can be freely set
- (NSInteger)containerIdentifier
{
    return 10;
}

#pragma mark Start

- (void)startWithBusinessUnitIdentifier:(SRGAnalyticsBusinessUnitIdentifier)businessUnitIdentifier
                    containerIdentifier:(NSInteger)containerIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier
{
    self.businessUnitIdentifier = businessUnitIdentifier;
    self.containerIdentifier = containerIdentifier;
    self.comScoreVirtualSite = comScoreVirtualSite;
    self.netMetrixIdentifier = netMetrixIdentifier;
    
    self.started = YES;
    
    [self startTagCommanderTracker];
    [self startComscoreTracker];
    [self startNetmetrixTracker];
    
    [self sendApplicationList];
}

- (void)startTagCommanderTracker
{
    NSParameterAssert(self.businessUnitIdentifier);
    
    if (! [self.businessUnitIdentifier isEqualToString:SRGAnalyticsBusinessUnitIdentifierTEST]) {
        static NSDictionary<SRGAnalyticsBusinessUnitIdentifier, NSNumber *> *s_accountIdentifiers = nil;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            // FIXME: Once the pilot phase is over and the official account identifiers are available, use them. For the
            //        pilot phase, only 3601 is available
            s_accountIdentifiers = @{ SRGAnalyticsBusinessUnitIdentifierRSI : @3601,        // @3668,
                                      SRGAnalyticsBusinessUnitIdentifierRTR : @3601,        // @3666,       // Under the SRG umbrella
                                      SRGAnalyticsBusinessUnitIdentifierRTS : @3601,        // @3669,
                                      SRGAnalyticsBusinessUnitIdentifierSRF : @3601,        // @3667,
                                      SRGAnalyticsBusinessUnitIdentifierSRG : @3601,        // @3666,
                                      SRGAnalyticsBusinessUnitIdentifierSWI : @3601         // @3670
                                      };
        });
        self.tagCommander = [[TagCommander alloc] initWithSiteID:s_accountIdentifiers[self.businessUnitIdentifier].intValue andContainerID:(int)self.containerIdentifier];
        [self.tagCommander addPermanentData:@"app_library_version" withValue:SRGAnalyticsMarketingVersion()];
        [self.tagCommander addPermanentData:@"navigation_environment" withValue:[NSBundle srg_isProductionVersion] ? @"prod" : @"preprod"];
    }
}

- (void)startComscoreTracker
{
    [CSComScore setAppContext];
    [CSComScore setSecure:YES];
    [CSComScore setCustomerC2:@"6036016"];
    [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
    [CSComScore enableAutoUpdate:60 foregroundOnly:NO];     //60 is the Comscore default interval value
    
    NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (applicationName) {
        [CSComScore setAutoStartLabels:@{ @"name": applicationName }];
    }
    
    [CSComScore setLabels:[self comscoreGlobalLabels]];
    
    // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
    self.streamSense = [[CSStreamSense alloc] init];
    [self.streamSense setKeepAliveInterval:9 * 60];
}

- (void)startNetmetrixTracker
{
    self.netmetrixTracker = [[SRGAnalyticsNetMetrixTracker alloc] initWithIdentifier:self.netMetrixIdentifier
                                                              businessUnitIdentifier:self.businessUnitIdentifier];
}

#pragma mark Labels

- (NSDictionary<NSString *, NSString *> *)comscoreGlobalLabels
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
    NSString *appLanguage = mainBundle.preferredLocalizations.firstObject ?: @"fr";
    NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSMutableDictionary<NSString *, NSString *> *globalLabels = [@{ @"ns_ap_an" : appName,
                                                                    @"ns_ap_lang" : [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
                                                                    @"ns_ap_ver" : appVersion,
                                                                    @"srg_unit" : self.businessUnitIdentifier.uppercaseString,
                                                                    @"srg_ap_push" : @"0",
                                                                    @"ns_site" : @"mainsite",                                          // The 'mainsite' is a constant value. If wrong, everything is screwed.
                                                                    @"ns_vsite" : self.comScoreVirtualSite,                            // The virtual site 'vsite' is associated with the app. It is created by comScore
                                                                    @"ns_st_pu" : SRGAnalyticsMarketingVersion() } mutableCopy];
    
    if ([self.businessUnitIdentifier isEqualToString:SRGAnalyticsBusinessUnitIdentifierTEST]) {
        static NSString *s_debugTimestamp;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd'@'HH:mm:ss";
            s_debugTimestamp = [dateFormatter stringFromDate:[NSDate date]];
        });
        globalLabels[@"srg_test"] = s_debugTimestamp;
    }
    return [globalLabels copy];
}

#pragma mark General event tracking (internal use only)

- (void)trackEventWithLabels:(NSDictionary<NSString *, NSString *> *)labels
              comScoreLabels:(NSDictionary<NSString *, NSString *> *)comScoreLabels
{
    [self trackTagCommanderEventWithLabels:labels];
    [self trackComScoreEventWithLabels:comScoreLabels];
}

- (void)trackComScoreEventWithLabels:(NSDictionary<NSString *, NSString *> *)labels
{
    [CSComScore hiddenWithLabels:labels];
}

- (void)trackTagCommanderEventWithLabels:(NSDictionary<NSString *, NSString *> *)labels
{
    SRGAnalyticsLogDebug(@"tracker", @"Event sent with labels: %@", labels);
    
    // TagCommander is not initialized in test mode
    if (self.tagCommander) {
        [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
            [self.tagCommander addData:key withValue:object];
        }];
        [self.tagCommander sendData];
    }
    else {
        // Only custom labels are sent in the notification userInfo. Internal predefined TagCommander variables are not sent,
        // as they are not needed for tests (they are part of what is guaranteed by the TagCommander SDK). For a complete list of
        // predefined variables, see https://github.com/TagCommander/pods/blob/master/TCSDK/PredefinedVariables.md
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsRequestNotification
                                                            object:self
                                                          userInfo:@{ SRGAnalyticsLabelsKey : labels }];
    }
}

#pragma mark Page view tracking

- (void)trackPageViewWithTitle:(NSString *)title levels:(NSArray<NSString *> *)levels
{
    [self trackPageViewWithTitle:title levels:levels labels:nil fromPushNotification:NO];
}

- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(NSArray<NSString *> *)levels
                        labels:(SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
{
    if (title.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing title. No event will be sent");
        return;
    }
    
    [self trackTagCommanderPageViewWithTitle:title levels:levels labels:labels fromPushNotification:fromPushNotification];
    [self trackComScorePageViewWithTitle:title levels:levels labels:labels fromPushNotification:fromPushNotification];
    
    [self.netmetrixTracker trackView];
}

- (void)trackComScorePageViewWithTitle:(NSString *)title
                                levels:(NSArray<NSString *> *)levels
                                labels:(SRGAnalyticsPageViewLabels *)labels
                  fromPushNotification:(BOOL)fromPushNotification
{
    NSAssert(title.length != 0, @"A title is required");
    
    NSMutableDictionary *pageViewLabels = [NSMutableDictionary dictionary];
    [pageViewLabels srg_safelySetString:title forKey:@"srg_title"];
    [pageViewLabels srg_safelySetString:@(fromPushNotification).stringValue forKey:@"srg_ap_push"];
    
    NSString *category = @"app";
    
    if (! levels) {
        [pageViewLabels srg_safelySetString:category forKey:@"srg_n1"];
    }
    else if (levels.count > 0) {
        __block NSMutableString *levelsComScoreFormattedString = [NSMutableString new];
        [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *levelKey = [NSString stringWithFormat:@"srg_n%@", @(idx + 1)];
            NSString *levelValue = [object description];
            
            if (idx < 10) {
                [pageViewLabels srg_safelySetString:levelValue forKey:levelKey];
            }
            
            if (levelsComScoreFormattedString.length > 0) {
                [levelsComScoreFormattedString appendString:@"."];
            }
            [levelsComScoreFormattedString appendString:levelValue.srg_comScoreFormattedString];
        }];
        
        category = [levelsComScoreFormattedString copy];
    }
    
    [pageViewLabels srg_safelySetString:category forKey:@"category"];
    [pageViewLabels srg_safelySetString:[NSString stringWithFormat:@"%@.%@", category, title.srg_comScoreFormattedString] forKey:@"name"];
    
    NSDictionary<NSString *, NSString *> *comScoreDictionary = [labels comScoreLabelsDictionary];
    if (comScoreDictionary) {
        [pageViewLabels addEntriesFromDictionary:comScoreDictionary];
    }
    
    [CSComScore viewWithLabels:pageViewLabels];
}

- (void)trackTagCommanderPageViewWithTitle:(NSString *)title
                                    levels:(NSArray<NSString *> *)levels
                                    labels:(SRGAnalyticsPageViewLabels *)labels
                      fromPushNotification:(BOOL)fromPushNotification
{
    NSAssert(title.length != 0, @"A title is required");
    
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetString:@"screen" forKey:@"event_id"];
    [fullLabels srg_safelySetString:@"app" forKey:@"navigation_property_type"];
    [fullLabels srg_safelySetString:title forKey:@"content_title"];
    [fullLabels srg_safelySetString:self.businessUnitIdentifier.uppercaseString forKey:@"navigation_bu_distributer"];
    [fullLabels srg_safelySetString:fromPushNotification ? @"true" : @"false" forKey:@"accessed_after_push_notification"];
    
    [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 7) {
            *stop = YES;
            return;
        }
        
        NSString *levelKey = [NSString stringWithFormat:@"navigation_level_%@", @(idx + 1)];
        [fullLabels srg_safelySetString:object forKey:levelKey];
    }];
    
    NSDictionary<NSString *, NSString *> *dictionary = [labels labelsDictionary];
    if (dictionary) {
        [fullLabels addEntriesFromDictionary:dictionary];
    }
    
    [self trackTagCommanderEventWithLabels:[fullLabels copy]];
}

#pragma mark Hidden event tracking

- (void)trackHiddenEventWithName:(NSString *)name
{
    [self trackHiddenEventWithName:name labels:nil];
}

- (void)trackHiddenEventWithName:(NSString *)name
                          labels:(SRGAnalyticsHiddenEventLabels *)labels
{
    if (name.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing name. No event will be sent");
        return;
    }
    
    [self trackTagCommanderHiddenEventWithName:name labels:labels];
    [self trackComScoreHiddenEventWithName:name labels:labels];
}

- (void)trackComScoreHiddenEventWithName:(NSString *)name labels:(SRGAnalyticsHiddenEventLabels *)labels
{
    NSAssert(name.length != 0, @"A name is required");
    
    NSMutableDictionary *hiddenEventLabels = [NSMutableDictionary dictionary];
    [hiddenEventLabels srg_safelySetString:name forKey:@"srg_title"];
    [hiddenEventLabels srg_safelySetString:@"app" forKey:@"category"];
    [hiddenEventLabels srg_safelySetString:[NSString stringWithFormat:@"app.%@", name.srg_comScoreFormattedString] forKey:@"name"];
    
    NSDictionary<NSString *, NSString *> *comScoreDictionary = [labels comScoreLabelsDictionary];
    if (comScoreDictionary) {
        [hiddenEventLabels addEntriesFromDictionary:comScoreDictionary];
    }
    
    [CSComScore hiddenWithLabels:hiddenEventLabels];
}

- (void)trackTagCommanderHiddenEventWithName:(NSString *)name labels:(SRGAnalyticsHiddenEventLabels *)labels
{
    NSAssert(name.length != 0, @"A name is required");
    
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetString:@"click" forKey:@"event_id"];
    [fullLabels srg_safelySetString:name forKey:@"event_name"];
    
    NSDictionary<NSString *, NSString *> *dictionary = [labels labelsDictionary];
    if (dictionary) {
        [fullLabels addEntriesFromDictionary:dictionary];
    }
    
    [self trackTagCommanderEventWithLabels:[fullLabels copy]];
}

#pragma mark Application list measurement

- (void)sendApplicationList
{
    // Tracks which SRG SSR applications are installed on the user device
    //
    // Specifications are available at: https://srfmmz.atlassian.net/wiki/display/INTFORSCHUNG/App+Overlapping+Measurement
    //
    // This measurement is not critical and is therefore performed only once the tracker starts. If it fails for some reason
    // (no network, for example), the measurement will be attempted again the next time the application is started
    NSURL *applicationListURL = [NSURL URLWithString:@"https://pastebin.com/raw/RnZYEWCA"];
    [[[NSURLSession sharedSession] dataTaskWithURL:applicationListURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SRGAnalyticsLogError(@"tracker", @"The application list could not be retrieved. Reason: %@", error);
            return;
        }
        
        NSError *parseError = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (! JSONObject || ! [JSONObject isKindOfClass:[NSArray class]]) {
            SRGAnalyticsLogError(@"tracker", @"The application list format is incorrect");
            return;
        }
        NSArray<NSDictionary *> *applicationDictionaries = JSONObject;
        
        // -canOpenURL: should only be called from the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Extract URL schemes and installed applications
            NSMutableSet<NSString *> *URLSchemes = [NSMutableSet set];
            NSMutableSet<NSString *> *installedApplications = [NSMutableSet set];
            for (NSDictionary *applicationDictionary in applicationDictionaries) {
                NSString *application = applicationDictionary[@"code"];
                NSString *URLScheme = applicationDictionary[@"ios"];
                
                if (URLScheme.length == 0 || ! application) {
                    SRGAnalyticsLogInfo(@"tracker", @"URL scheme or application name missing in %@. Skipped", applicationDictionary);
                    continue;
                }
                
                [URLSchemes addObject:URLScheme];
                
                NSString *URLString = [NSString stringWithFormat:@"%@://probe-for-srganalytics", URLScheme];
                if (! [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:URLString]]) {
                    continue;
                }
                
                [installedApplications addObject:application];
            }
            
            // Since iOS 9, to be able to open a URL in another application (and thus to be able to test for URL scheme
            // support), the application must declare the schemes it supports via its Info.plist file (under the
            // `LSApplicationQueriesSchemes` key). If we are running on iOS 9 or above, check that the app list is consistent
            // with the remote list, and log an error if this is not the case
            NSArray<NSString *> *declaredURLSchemesArray = [NSBundle mainBundle].infoDictionary[@"LSApplicationQueriesSchemes"];
            NSSet<NSString *> *declaredURLSchemes = declaredURLSchemesArray ? [NSSet setWithArray:declaredURLSchemesArray] : [NSSet set];
            if (! [URLSchemes isSubsetOfSet:declaredURLSchemes]) {
                SRGAnalyticsLogError(@"tracker", @"The URL schemes declared in your application Info.plist file under the "
                                     "'LSApplicationQueriesSchemes' key must at list contain the scheme list available at "
                                     "https://pastebin.com/raw/RnZYEWCA (the schemes are found under the 'ios' key, or "
                                     "a script is available in the SRGAnalytics repository to collect it). Please "
                                     "update your Info.plist file to make this message disappear");
            }
            
            if (installedApplications.count == 0) {
                SRGAnalyticsLogWarning(@"tracker", @"No identified application installed. Nothing to be done");
                return;
            }
            
            NSArray *sortedInstalledApplications = [installedApplications.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.value = [sortedInstalledApplications componentsJoinedByString:@","];
            labels.comScoreCustomInfo = @{@"srg_evgroup": @"Installed Apps",
                                          @"srg_evname": labels.value};
            
            [self trackHiddenEventWithName:@"installed_apps" labels:labels];
        });
    }] resume];
}

#pragma mark Description

- (NSString *)description
{
    if (self.started) {
        return [NSString stringWithFormat:@"<%@: %p; businessUnitIdentifier: %@; comScoreVirtualSite: %@; netMetrixIdentifier: %@>",
                [self class],
                self,
                self.businessUnitIdentifier,
                self.comScoreVirtualSite,
                self.netMetrixIdentifier];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p (not started yet)>", [self class], self];
    }
}

@end
