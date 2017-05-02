//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "NSDictionary+SRGAnalytics.h"
#import "NSString+SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNetMetrixTracker.h"
#import "SRGAnalyticsNotifications.h"
#import "UIViewController+SRGAnalytics.h"

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
                      accountIdentifier:(int)accountIdentifier
                    containerIdentifier:(int)containerIdentifier
                    netMetrixIdentifier:(NSString *)netMetrixIdentifier
{    
    self.businessUnitIdentifier = businessUnitIdentifier;
    self.accountIdentifier = accountIdentifier;
    self.containerIdentifier = containerIdentifier;
    self.netMetrixIdentifier = netMetrixIdentifier;
    
    self.started = YES;
    
    [self startNetmetrixTracker];
    self.tagCommander = [[TagCommander alloc] initWithSiteID:accountIdentifier andContainerID:containerIdentifier];
}

- (void)startNetmetrixTracker
{
    self.netmetrixTracker = [[SRGAnalyticsNetMetrixTracker alloc] initWithIdentifier:self.netMetrixIdentifier
                                                              businessUnitIdentifier:self.businessUnitIdentifier];
}

#pragma mark Page view tracking (private)

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray<NSString *> *)levels customLabels:(NSDictionary<NSString *, NSString *> *)customLabels fromPushNotification:(BOOL)fromPushNotification
{
    if (title.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing title. No event will be sent");
        return;
    }
    
    [self.tagCommander addData:@"EVENT_NAME" withValue:title];
    [self.tagCommander addData:@"HIT_TYPE" withValue:@"screen"];
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.tagCommander addData:key withValue:object];
    }];
    [self.tagCommander sendData];
    
    [self.netmetrixTracker trackView];
}

#pragma mark Hidden event tracking

- (void)trackHiddenEventWithTitle:(NSString *)title
{
    [self trackHiddenEventWithTitle:title customLabels:nil];
}

- (void)trackHiddenEventWithTitle:(NSString *)title customLabels:(NSDictionary *)customLabels
{
    if (title.length == 0) {
        SRGAnalyticsLogWarning(@"tracker", @"Missing title. No event will be sent");
        return;
    }
    
    [self.tagCommander addData:@"EVENT_NAME" withValue:title];
    [self.tagCommander addData:@"HIT_TYPE" withValue:@"click"];
    [customLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.tagCommander addData:key withValue:object];
    }];
    [self.tagCommander sendData];
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
