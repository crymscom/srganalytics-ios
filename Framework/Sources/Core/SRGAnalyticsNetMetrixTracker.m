//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNetMetrixTracker.h"

#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNotifications.h"
#import "SRGAnalyticsTracker.h"

#import <UIKit/UIKit.h>

@interface SRGAnalyticsNetMetrixTracker ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *businessUnitIdentifier;

@end

@implementation SRGAnalyticsNetMetrixTracker

#pragma mark Object lifecycle

- (instancetype)initWithIdentifier:(NSString *)identifier businessUnitIdentifier:(NSString *)businessUnitIdentifier
{
    if (self = [super init]) {
        self.identifier = identifier;
        self.businessUnitIdentifier = businessUnitIdentifier;
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)netMetrixDomain
{
    // HTTPs domains as documented here: https://srfmmz.atlassian.net/wiki/display/SRGPLAY/HTTPS+Transition
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSString *> *s_domains;
    dispatch_once(&s_onceToken, ^{
        s_domains = @{ SRGAnalyticsBusinessUnitIdentifierRSI : @"rsi-ssl",
                       SRGAnalyticsBusinessUnitIdentifierRTR : @"rtr-ssl",
                       SRGAnalyticsBusinessUnitIdentifierRTS : @"rts-ssl",
                       SRGAnalyticsBusinessUnitIdentifierSRF : @"sftv-ssl",
                       SRGAnalyticsBusinessUnitIdentifierSWI : @"sinf-ssl" };
    });
    return s_domains[self.businessUnitIdentifier] ?: self.businessUnitIdentifier;
}

#pragma mark View tracking

- (void)trackView
{
    NSString *netMetrixURLString = [NSString stringWithFormat:@"https://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", self.netMetrixDomain, self.identifier, self.device];
    NSURL *netMetrixURL = [NSURL URLWithString:netMetrixURLString];
    
    if ([self.businessUnitIdentifier isEqualToString:SRGAnalyticsBusinessUnitIdentifierTEST]) {
        // Send the notification when the request is made (as is done with comScore). Notifications are intended to test
        // whether events are properly sent, not whether they are properly received
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsNetmetrixRequestNotification
                                                            object:nil
                                                          userInfo:@{ SRGAnalyticsNetmetrixURLKey : netMetrixURL }];
    }
    
    if (! [self.businessUnitIdentifier isEqualToString:SRGAnalyticsBusinessUnitIdentifierTEST]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:netMetrixURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"image/gif" forHTTPHeaderField:@"Accept"];
        
        // Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
        NSString *systemVersion = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; CPU %@ %@ like Mac OS X)", self.device, self.operatingSystem, systemVersion];
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        SRGAnalyticsLogDebug(@"NetMetrix", @"Request %@ started", request.URL);
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            SRGAnalyticsLogDebug(@"NetMetrix", @"Request %@ ended with error %@", request.URL, error);
        }] resume];
    }
    else {
        SRGAnalyticsLogDebug(@"NetMetrix", @"Requests are disabled for the test business unit");
    }
}

#pragma mark Information

- (NSString *)device
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"phone";
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return @"tablet";
    }
    else {
        return @"universal";
    }
}

- (NSString *)operatingSystem
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"iPhone OS";
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return @"iPad OS";
    }
    else {
        return @"OS";
    }
}

@end
