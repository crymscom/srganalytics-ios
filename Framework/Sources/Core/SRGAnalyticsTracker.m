//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "NSDictionary+SRGAnalytics.h"
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

#pragma mark Description

- (NSString *)description
{
    if (self.started) {
        return [NSString stringWithFormat:@"<%@: %p; businessUnitIdentifier: %@; netMetrixIdentifier: %@>",
                [self class],
                self,
                self.businessUnitIdentifier,
                self.netMetrixIdentifier];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p (not started yet)>", [self class], self];
    }
}

@end
