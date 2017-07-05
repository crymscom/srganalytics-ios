//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "NSString+SRGAnalytics.h"
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
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierSWI = @"swi";
SRGAnalyticsBusinessUnitIdentifier const SRGAnalyticsBusinessUnitIdentifierTEST = @"test";

@interface SRGAnalyticsTracker ()

@property (nonatomic, copy) NSString *businessUnitIdentifier;
@property (nonatomic, copy) NSString *comScoreVirtualSite;
@property (nonatomic) NSInteger accountIdentifier;
@property (nonatomic) NSInteger containerIdentifier;
@property (nonatomic, copy) NSString *netMetrixIdentifier;
@property (nonatomic, getter=isStarted) BOOL started;

@property (nonatomic) TagCommander *tagCommander;
@property (nonatomic) SRGAnalyticsNetMetrixTracker *netmetrixTracker;
@property (nonatomic) CSStreamSense *streamSense;

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

#pragma mark Object lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Start

- (void)startWithBusinessUnitIdentifier:(NSString *)businessUnitIdentifier
                    comScoreVirtualSite:(NSString *)comScoreVirtualSite
                      accountIdentifier:(NSInteger)accountIdentifier
                    containerIdentifier:(NSInteger)containerIdentifier
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier
{    
    self.businessUnitIdentifier = businessUnitIdentifier;
    self.comScoreVirtualSite = comScoreVirtualSite;
    self.accountIdentifier = accountIdentifier;
    self.containerIdentifier = containerIdentifier;
    self.netMetrixIdentifier = netMetrixIdentifier;
    
    self.started = YES;
    
    [self startComscoreTracker];
    [self startNetmetrixTracker];
    
    self.tagCommander = [[TagCommander alloc] initWithSiteID:(int)accountIdentifier andContainerID:(int)containerIdentifier];
    
    // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
    self.streamSense = [[CSStreamSense alloc] init];
    [self.streamSense setKeepAliveInterval:9 * 60];
}

- (void)startComscoreTracker
{
    [CSComScore setAppContext];
    [CSComScore setSecure:YES];
    [CSComScore setCustomerC2:@"6036016"];
    [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
    [CSComScore enableAutoUpdate:60 foregroundOnly:NO];     //60 is the Comscore default interval value
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (appName) {
        [CSComScore setAutoStartLabels:@{ @"name": appName }];
    }
    [CSComScore setLabels:[self comscoreGlobalLabels]];
    
    [self startLoggingInternalComScoreTasks];
    [self sendApplicationList];
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
    
    NSMutableDictionary<NSString *, NSString *> *globalLabels = [@{ @"ns_ap_an": appName,
                                                                    @"ns_ap_lang": [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
                                                                    @"ns_ap_ver": appVersion,
                                                                    @"srg_unit": self.businessUnitIdentifier.uppercaseString,
                                                                    @"srg_ap_push": @"0",
                                                                    @"ns_site": @"mainsite",                                    // The 'mainsite' is a constant value. If wrong, everything is screwed.
                                                                    @"ns_vsite": self.comScoreVirtualSite } mutableCopy];       // The virtual site 'vsite' is associated with the app. It is created by comScore
    
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

#pragma mark Page view tracking (private)

- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(NSArray<NSString *> *)levels
                  customLabels:(NSDictionary<NSString *,NSString *> *)customLabels
          comScoreCustomLabels:(NSDictionary<NSString *,NSString *> *)comScoreCustomLabels
          fromPushNotification:(BOOL)fromPushNotification
{
    if (title.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing title. No event will be sent");
        return;
    }
    
    [self trackComScorePageViewWithTitle:title levels:levels customLabels:comScoreCustomLabels fromPushNotification:fromPushNotification];
    [self trackTagCommanderPageViewWithTitle:title levels:levels customLabels:customLabels fromPushNotification:fromPushNotification];
    [self.netmetrixTracker trackView];
}

- (void)trackComScorePageViewWithTitle:(NSString *)title
                                levels:(NSArray<NSString *> *)levels
                          customLabels:(NSDictionary<NSString *, NSString *> *)customLabels
                  fromPushNotification:(BOOL)fromPushNotification
{
    NSAssert(title.length != 0, @"A title is required");
    
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    [labels srg_safelySetObject:title forKey:@"srg_title"];
    [labels srg_safelySetObject:@(fromPushNotification) forKey:@"srg_ap_push"];
    
    NSString *category = @"app";
    
    if (! levels) {
        [labels srg_safelySetObject:category forKey:@"srg_n1"];
    }
    else if (levels.count > 0) {
        __block NSMutableString *levelsComScoreFormattedString = [NSMutableString new];
        [levels enumerateObjectsUsingBlock:^(NSString * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *levelKey = [NSString stringWithFormat:@"srg_n%@", @(idx + 1)];
            NSString *levelValue = [object description];
            
            if (idx < 10) {
                [labels srg_safelySetObject:levelValue forKey:levelKey];
            }
            
            if (levelsComScoreFormattedString.length > 0) {
                [levelsComScoreFormattedString appendString:@"."];
            }
            [levelsComScoreFormattedString appendString:levelValue.srg_comScoreFormattedString];
        }];
        
        category = [levelsComScoreFormattedString copy];
    }
    
    [labels srg_safelySetObject:category forKey:@"category"];
    [labels srg_safelySetObject:[NSString stringWithFormat:@"%@.%@", category, title.srg_comScoreFormattedString] forKey:@"name"];
    
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [labels srg_safelySetObject:[object description] forKey:[key description]];
    }];
    
    [CSComScore viewWithLabels:labels];
}

- (void)trackTagCommanderPageViewWithTitle:(NSString *)title
                                    levels:(NSArray<NSString *> *)levels
                              customLabels:(NSDictionary<NSString *, NSString *> *)customLabels
                      fromPushNotification:(BOOL)fromPushNotification
{
    NSAssert(title.length != 0, @"A title is required");
    
    [self.tagCommander addData:@"TITLE" withValue:title];
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.tagCommander addData:key withValue:object];
    }];
    [self.tagCommander sendData];
}

#pragma mark Hidden event tracking

- (void)trackHiddenEventWithTitle:(NSString *)title
{
    [self trackHiddenEventWithTitle:title customLabels:nil comScoreCustomLabels:nil];
}

- (void)trackHiddenEventWithTitle:(NSString *)title
                     customLabels:(NSDictionary *)customLabels
             comScoreCustomLabels:(NSDictionary<NSString *,NSString *> *)comScoreCustomLabels
{
    if (title.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing title. No event will be sent");
        return;
    }
    
    [self trackComScoreHiddenEventWithTitle:title customLabels:comScoreCustomLabels];
    [self trackHiddenTagCommanderEventWithTitle:title customLabels:customLabels];
}

- (void)trackComScoreHiddenEventWithTitle:(NSString *)title customLabels:(NSDictionary<NSString *, NSString *> *)customLabels
{
    NSAssert(title.length != 0, @"A title is required");
    
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    [labels srg_safelySetObject:title forKey:@"srg_title"];
    
    [labels srg_safelySetObject:@"app" forKey:@"category"];
    [labels srg_safelySetObject:[NSString stringWithFormat:@"app.%@", title.srg_comScoreFormattedString] forKey:@"name"];
    
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [labels srg_safelySetObject:[object description] forKey:[key description]];
    }];
    
    [CSComScore hiddenWithLabels:labels];
}

- (void)trackHiddenTagCommanderEventWithTitle:(NSString *)title customLabels:(NSDictionary<NSString *, NSString *> *)customLabels
{
    NSAssert(title.length != 0, @"A title is required");
    
    [self.tagCommander addData:@"TITLE" withValue:title];
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.tagCommander addData:key withValue:object];
    }];
    [self.tagCommander sendData];
}

#pragma mark Player tracking

- (void)trackPlayerEvent:(SRGAnalyticsPlayerEvent)event
              atPosition:(NSTimeInterval)position
        withCustomLabels:(NSDictionary<NSString *, NSString *> *)customLabels
    comScoreCustomLabels:(NSDictionary<NSString *, NSString *> *)comScoreCustomLabels
comScoreCustomClipLabels:(nullable NSDictionary<NSString *,NSString *> *)comScoreCustomClipLabels
{
    [self trackComScorePlayerEvent:event atPosition:position withCustomLabels:comScoreCustomLabels customClipLabels:comScoreCustomClipLabels];
    [self trackTagCommanderPlayerEvent:event atPosition:position withCustomLabels:customLabels];
}

- (void)trackComScorePlayerEvent:(SRGAnalyticsPlayerEvent)event
                      atPosition:(NSTimeInterval)position
                withCustomLabels:(NSDictionary<NSString *, NSString *> *)customLabels
                customClipLabels:(NSDictionary<NSString *, NSString *> *)customClipLabels
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_streamSenseEvents;
    dispatch_once(&s_onceToken, ^{
        s_streamSenseEvents = @{ @(SRGAnalyticsPlayerEventBuffer) : @(CSStreamSenseBuffer),
                                 @(SRGAnalyticsPlayerEventPlay) : @(CSStreamSensePlay),
                                 @(SRGAnalyticsPlayerEventPause) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerEventSeek) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerEventStop) : @(CSStreamSenseEnd),
                                 @(SRGAnalyticsPlayerEventEnd) : @(CSStreamSenseEnd) };
    });
    
    NSNumber *eventType = s_streamSenseEvents[@(event)];
    if (! eventType) {
        return;
    }
    
    [[self.streamSense labels] removeAllObjects];
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.streamSense setLabel:key value:object];
    }];
    
    // Reset custom clip labels to avoid inheriting from a previous segment. Do not reset otherwise internal hidden
    // comScore labels (e.g. ns_st_pa) would be incorrect afterwards
    [[[self.streamSense clip] labels] removeAllObjects];
    [customClipLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [[self.streamSense clip] setLabel:key value:object];
    }];
    
    [self.streamSense notify:eventType.intValue position:position labels:nil /* already set on the stream and clip objects */];
}

- (void)trackTagCommanderPlayerEvent:(SRGAnalyticsPlayerEvent)event
                          atPosition:(NSTimeInterval)position
                    withCustomLabels:(NSDictionary<NSString *,NSString *> *)customLabels
{

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
            NSDictionary *labels = @{ @"srg_evgroup" : @"Installed Apps",
                                      @"srg_evname" : [sortedInstalledApplications componentsJoinedByString:@","] };
            [CSComScore hiddenWithLabels:labels];
        });
    }] resume];
}

#pragma mark Logging

- (void)startLoggingInternalComScoreTasks
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comScoreRequestDidFinish:)
                                                 name:SRGAnalyticsComScoreRequestNotification
                                               object:nil];
    
    // +[CSComScore setPixelURL:] is dispatched on an internal comScore queue, so calling +[CSComScore pixelURL]
    // right after doesn’t work, we must also dispatch it on the same queue!
    [[[CSComScore core] taskExecutor] execute:^{
        const SEL selectors[] = {
            @selector(appName),
            @selector(pixelURL),
            @selector(publisherSecret),
            @selector(customerC2),
            @selector(version),
            @selector(labels)
        };
        
        NSMutableString *message = [NSMutableString new];
        for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
            SEL selector = selectors[i];
            [message appendFormat:@"%@: %@\n", NSStringFromSelector(selector), [CSComScore performSelector:selector]];
        }
        [message deleteCharactersInRange:NSMakeRange(message.length - 1, 1)];
        SRGAnalyticsLogDebug(@"tracker", @"%@", message);
    } background:YES];
}

#pragma mark Notifications

- (void)comScoreRequestDidFinish:(NSNotification *)notification
{
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
    NSUInteger maxKeyLength = [[[labels allKeys] valueForKeyPath:@"@max.length"] unsignedIntegerValue];
    
    NSMutableString *dictionaryRepresentation = [NSMutableString new];
    for (NSString *key in [[labels allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [dictionaryRepresentation appendFormat:@"%@ = %@\n", [key stringByPaddingToLength:maxKeyLength withString:@" " startingAtIndex:0], labels[key]];
    }
    
    NSString *ns_st_ev = labels[@"ns_st_ev"];
    NSString *ns_ap_ev = labels[@"ns_ap_ev"];
    NSString *type = labels[@"ns_st_ty"];
    NSString *typeSymbol = @"\U00002753"; // BLACK QUESTION MARK ORNAMENT
    
    if ([type.lowercaseString isEqual:@"audio"]) {
        typeSymbol = @"\U0001F4FB"; // RADIO
    }
    else if ([type.lowercaseString isEqual:@"video"]) {
        typeSymbol = @"\U0001F4FA"; // TELEVISION
    }
    
    if ([labels[@"ns_st_li"] boolValue]) {
        typeSymbol = [typeSymbol stringByAppendingString:@"\U0001F6A8"];
    }
    
    NSString *event = ns_st_ev ? [typeSymbol stringByAppendingFormat:@" %@", ns_st_ev] : ns_ap_ev;
    NSString *name = ns_st_ev ? [NSString stringWithFormat:@"%@ / %@", labels[@"ns_st_pl"], labels[@"ns_st_ep"]] : labels[@"name"];
    SRGAnalyticsLogDebug(@"tracker", @"Event %@ with name %@ and labels %@", event, name, labels);
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
