//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker+SRGAnalytics_Identity.h"

#import "SRGAnalyticsTracker+Private.h"

#import <objc/runtime.h>

static void *s_analyticsIdentityServiceKey = &s_analyticsIdentityServiceKey;

@implementation SRGAnalyticsTracker (SRGAnalytics_Identity)

#pragma mark Startup

- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration{
    [self startWithConfiguration:configuration];
}

#pragma mark Getters and Setters

- (SRGIdentityService *)identityService
{
    return objc_getAssociatedObject(self, s_analyticsIdentityServiceKey);
}

- (void)setIdentityService:(SRGIdentityService *)identityService
{
    SRGIdentityService *currentIdentityService = objc_getAssociatedObject(self, s_analyticsIdentityServiceKey);;
    
    if (currentIdentityService) {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGIdentityServiceDidUpdateAccountNotification
                                                    object:currentIdentityService];
    }
    
    objc_setAssociatedObject(self, s_analyticsIdentityServiceKey, identityService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self updateWithAccount:identityService.account];
    
    if (identityService) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didUpdateAccount:)
                                                   name:SRGIdentityServiceDidUpdateAccountNotification
                                                 object:identityService];
    }
}

#pragma mark Account data

- (void)updateWithAccount:(SRGAccount *)account
{
    NSMutableDictionary<NSString *, NSString *> *globalLabels = [self.globalLabels mutableCopy] ?: [NSMutableDictionary dictionary];
    globalLabels[@"user_id"] = account.uid;
    globalLabels[@"user_is_logged"] = account.uid ? @"true" : @"false";
    self.globalLabels = [globalLabels copy];
}

#pragma mark Notifications

- (void)didUpdateAccount:(NSNotification *)notification
{
    SRGAccount *account = notification.userInfo[SRGIdentityServiceAccountKey];
    [self updateWithAccount:account];
}

@end
