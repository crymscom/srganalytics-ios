//
//  Created by Frédéric Humbert-Droz on 10/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsNetmetrixTracker.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static NSString * const LoggerDomainAnalyticsNetmetrix = @"Netmetrix";

NSString * const RTSAnalyticsNetmetrixWillSendRequestNotification = @"RTSAnalyticsNetmetrixWillSendRequest";
NSString * const RTSAnalyticsNetmetrixRequestDidFinishNotification = @"RTSAnalyticsNetmetrixRequestDidFinish";
NSString * const RTSAnalyticsNetmetrixRequestSuccessUserInfoKey = @"RTSAnalyticsNetmetrixSuccess";
NSString * const RTSAnalyticsNetmetrixRequestResponseUserInfoKey = @"RTSAnalyticsNetmetrixResponse";

@interface RTSAnalyticsNetmetrixTracker ()

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *domain;

@end

@implementation RTSAnalyticsNetmetrixTracker

- (instancetype) initWithAppID:(NSString *)appID domain:(NSString *)domain
{
	if (!(self = [super init]))
		return nil;
	
	_appID = appID;
	_domain = domain;
	
	DDLogDebug(@"%@ initialization\nAppID: %@\nDomain: %@", LoggerDomainAnalyticsNetmetrix, appID, domain);

	return self;
}

#pragma mark - Track View

- (void) trackView
{
	if (!self.appID && !self.domain)
		return;
	
	NSString *netmetrixURLString = [NSString stringWithFormat:@"http://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", self.domain, self.appID, self.device];
	NSURL *netmetrixURL = [NSURL URLWithString:netmetrixURLString];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:netmetrixURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
	[request setHTTPMethod: @"GET"];
	[request setValue:@"image/gif" forHTTPHeaderField:@"Accept"];
	
	// Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
	NSString *systemVersion = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
	NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; CPU %@ %@ like Mac OS X)", self.device, self.operatingSystem, systemVersion];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

	DDLogVerbose(@"%@ : will send view event:\nurl        = %@\nuser-agent = %@", LoggerDomainAnalyticsNetmetrix, netmetrixURLString, userAgent);
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixWillSendRequestNotification object:request userInfo:nil];
	
	//Never sends page view is testing
	if ([self.appID isEqualToString:@"test"] || NSClassFromString(@"XCTestCase") != NULL) {
		DDLogWarn(@"%@ response will be fake due to testing flag or xctest bundle", LoggerDomainAnalyticsNetmetrix);
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixRequestDidFinishNotification object:request userInfo:nil];
		return;
	}
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		
		BOOL success = !connectionError;
		NSDictionary *userInfo = @{ RTSAnalyticsNetmetrixRequestSuccessUserInfoKey: @(success), RTSAnalyticsNetmetrixRequestResponseUserInfoKey: response };
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixRequestDidFinishNotification object:request userInfo:userInfo];
		
		if (success) {
			DDLogInfo(@"%@ view > %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod);
		}else{
			DDLogError(@"%@ ERROR sending %@ view : %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod, connectionError.localizedDescription);
		}
		
		DDLogDebug(@"%@ view event sent:\n%@", LoggerDomainAnalyticsNetmetrix,[(NSHTTPURLResponse*)response allHeaderFields]);
	}];
}

#pragma mark - Helpers


- (NSString *)device
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		return @"phone";
	}
	else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		return @"tablet";
	}
	else
	{
		return @"universal";
	}
}

- (NSString *)operatingSystem
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		return @"iPhone OS";
	}
	else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		return @"iPad OS";
	}
	else
	{
		return @"OS";
	}
}

@end
