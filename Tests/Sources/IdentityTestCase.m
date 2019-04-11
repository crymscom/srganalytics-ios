//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import <libextobjc/libextobjc.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <SRGAnalytics_Identity/SRGAnalytics_Identity.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

static NSString *TestValidToken = @"0123456789";
static NSString *TestUserId = @"1234";

@interface SRGIdentityService (Private)

- (BOOL)handleCallbackURL:(NSURL *)callbackURL;

@property (nonatomic, readonly, copy) NSString *identifier;

@end

static SRGAnalyticsConfiguration *TestConfiguration(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             netMetrixIdentifier:@"test"];
    configuration.unitTesting = YES;
    return configuration;
}

static NSURL *TestWebserviceURL(void)
{
    return [NSURL URLWithString:@"https://api.srgssr.local"];
}

static NSURL *TestWebsiteURL(void)
{
    return [NSURL URLWithString:@"https://www.srgssr.local"];
}

static NSURL *TestLoginCallbackURL(SRGIdentityService *identityService, NSString *token)
{
    NSString *URLString = [NSString stringWithFormat:@"srganalytics-tests://%@?identity_service=%@&token=%@", TestWebserviceURL().host, identityService.identifier, token];
    return [NSURL URLWithString:URLString];
}

static NSURL *TestUnauthorizedCallbackURL(SRGIdentityService *identityService)
{
    NSString *URLString = [NSString stringWithFormat:@"srganalytics-tests://%@?identity_service=%@&action=unauthorized", TestWebserviceURL().host, identityService.identifier];
    return [NSURL URLWithString:URLString];
}

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface IdentityTestCase : XCTestCase

@property (nonatomic) SRGIdentityService *identityService;
@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation IdentityTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
    
    self.identityService = [[SRGIdentityService alloc] initWithWebserviceURL:TestWebserviceURL() websiteURL:TestWebsiteURL()];
    [self.identityService logout];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqual:TestWebserviceURL().host];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        if ([request.URL.host isEqualToString:TestWebsiteURL().host]) {
            if ([request.URL.path containsString:@"login"]) {
                NSURLComponents *URLComponents = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), @"redirect"];
                NSURLQueryItem *queryItem = [URLComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject;
                
                NSURL *redirectURL = [NSURL URLWithString:queryItem.value];
                NSURLComponents *redirectURLComponents = [[NSURLComponents alloc] initWithURL:redirectURL resolvingAgainstBaseURL:NO];
                NSArray<NSURLQueryItem *> *queryItems = redirectURLComponents.queryItems ?: @[];
                queryItems = [queryItems arrayByAddingObject:[[NSURLQueryItem alloc] initWithName:@"token" value:TestValidToken]];
                redirectURLComponents.queryItems = queryItems;
                
                return [[OHHTTPStubsResponse responseWithData:[NSData data]
                                                   statusCode:302
                                                      headers:@{ @"Location" : redirectURLComponents.URL.absoluteString }] requestTime:1. responseTime:OHHTTPStubsDownloadSpeedWifi];
            }
        }
        else if ([request.URL.host isEqualToString:TestWebserviceURL().host]) {
            if ([request.URL.path containsString:@"logout"]) {
                return [[OHHTTPStubsResponse responseWithData:[NSData data]
                                                   statusCode:204
                                                      headers:nil] requestTime:1. responseTime:OHHTTPStubsDownloadSpeedWifi];
            }
            else if ([request.URL.path containsString:@"userinfo"]) {
                NSString *validAuthorizationHeader = [NSString stringWithFormat:@"sessionToken %@", TestValidToken];
                if ([[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:validAuthorizationHeader]) {
                    NSDictionary<NSString *, id> *account = @{ @"id" : TestUserId,
                                                               @"publicUid" : @"4321",
                                                               @"login" : @"test@srgssr.ch",
                                                               @"displayName": @"Play SRG",
                                                               @"firstName": @"Play",
                                                               @"lastName": @"SRG",
                                                               @"gender": @"other",
                                                               @"birthdate": @"2001-01-01" };
                    return [[OHHTTPStubsResponse responseWithData:[NSJSONSerialization dataWithJSONObject:account options:0 error:NULL]
                                                       statusCode:200
                                                          headers:nil] requestTime:1. responseTime:OHHTTPStubsDownloadSpeedWifi];
                }
                else {
                    return [[OHHTTPStubsResponse responseWithData:[NSData data]
                                                       statusCode:401
                                                          headers:nil] requestTime:1. responseTime:OHHTTPStubsDownloadSpeedWifi];
                }
            }
        }
        
        // No match, return 404
        return [[OHHTTPStubsResponse responseWithData:[NSData data]
                                           statusCode:404
                                              headers:nil] requestTime:1. responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    [self.identityService logout];
    self.identityService = nil;
    
    [OHHTTPStubs removeAllStubs];
    
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testHiddenEventWithStandardStartMethod
{
    // This test requires a brand new analytics tracker
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker new];
    [analyticsTracker startWithConfiguration:TestConfiguration()];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertNil(labels[@"user_is_logged"]);
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [analyticsTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithoutIdentityService
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"false");
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventNotLogged
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"false");
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventJustLoggedWithoutAccountInformation
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue(NSThread.isMainThread);
        return YES;
    }];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"false");
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventLogged
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"true");
        XCTAssertEqualObjects(labels[@"user_id"], TestUserId);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventAfterUnauthorizedCall
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLogoutNotification object:self.identityService handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertTrue([notification.userInfo[SRGIdentityServiceUnauthorizedKey] boolValue]);
        return YES;
    }];
    
    [self.identityService handleCallbackURL:TestUnauthorizedCallbackURL(self.identityService)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"false");
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventAfterLogout
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"false");
        XCTAssertNil(labels[@"user_id"]);
        return YES;
    }];
    
    [self.identityService logout];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventLogged
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"true");
        XCTAssertEqualObjects(labels[@"user_id"], TestUserId);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view"
                                                       levels:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenPlaybackEventLogged
{
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"true");
        XCTAssertEqualObjects(labels[@"user_id"], TestUserId);
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventForTrackerStartedWithLoggedInUser
{
    [self expectationForSingleNotification:SRGIdentityServiceUserDidLoginNotification object:self.identityService handler:nil];
    [self expectationForSingleNotification:SRGIdentityServiceDidUpdateAccountNotification object:self.identityService handler:nil];
    
    [self.identityService handleCallbackURL:TestLoginCallbackURL(self.identityService, TestValidToken)];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker new];
    [analyticsTracker startWithConfiguration:TestConfiguration() identityService:self.identityService];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"user_is_logged"], @"true");
        XCTAssertEqualObjects(labels[@"user_id"], TestUserId);
        return YES;
    }];
    
    [analyticsTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
