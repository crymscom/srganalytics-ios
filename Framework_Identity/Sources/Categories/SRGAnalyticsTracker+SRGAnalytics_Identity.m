//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <objc/runtime.h>

#import "SRGAnalyticsTracker+SRGAnalytics_Identity.h"

#import "SRGAnalyticsTracker+Private.h"

static void *s_analyticsIdentityServiceKey = &s_analyticsIdentityServiceKey;

@implementation SRGAnalyticsTracker (SRGAnalytics_Identity)

#pragma mark Getters and Setters

- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration identityService:(SRGIdentityService *)identityService
{
    self.identityService = identityService;
    [self startWithConfiguration:configuration];
}

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
    
    [self setAccount:identityService.account];
    
    if (identityService) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didUpdateAccount:)
                                                   name:SRGIdentityServiceDidUpdateAccountNotification
                                                 object:identityService];
    }
}

- (void)setAccount:(SRGAccount *)account
{
    if (account.uid) {
        self.globalLabels = [self.globalLabels mtl_dictionaryByAddingEntriesFromDictionary:@{ @"user_id" : account.uid }];
    }
    else {
        self.globalLabels = [self.globalLabels mtl_dictionaryByRemovingValuesForKeys:@[ @"user_id" ]];
    }
    self.globalLabels = [self.globalLabels mtl_dictionaryByAddingEntriesFromDictionary:@{ @"user_is_logged" : (account.uid) ? @"true" : @"false" }];
}

#pragma mark Notifications

- (void)didUpdateAccount:(NSNotification *)notification
{
    SRGAccount *account = notification.userInfo[SRGIdentityServiceAccountKey];
    [self setAccount:account];
}

@end
