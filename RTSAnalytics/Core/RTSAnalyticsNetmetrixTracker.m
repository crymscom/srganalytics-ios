//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsNetmetrixTracker_private.h"
#import "RTSAnalyticsLogger.h"

static NSString * const LoggerDomainAnalyticsNetmetrix = @"Netmetrix";

NSString * const RTSAnalyticsNetmetrixRequestDidFinishNotification = @"RTSAnalyticsNetmetrixRequestDidFinish";
NSString * const RTSAnalyticsNetmetrixRequestSuccessUserInfoKey = @"RTSAnalyticsNetmetrixSuccess";
NSString * const RTSAnalyticsNetmetrixRequestErrorUserInfoKey = @"RTSAnalyticsNetmetrixError";
NSString * const RTSAnalyticsNetmetrixRequestResponseUserInfoKey = @"RTSAnalyticsNetmetrixResponse";

@interface RTSAnalyticsNetmetrixTracker ()

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
@property (nonatomic, assign) BOOL production;

@end

@implementation RTSAnalyticsNetmetrixTracker

- (instancetype) initWithAppID:(NSString *)appID businessUnit:(SSRBusinessUnit)businessUnit production:(BOOL)production
{
	if (!(self = [super init]))
		return nil;
	
	_appID = appID;
	_businessUnit = businessUnit;
	_production = production;
	
	RTSAnalyticsLogDebug(@"%@ initialization\nAppID: %@\nDomain: %@", LoggerDomainAnalyticsNetmetrix, appID, self.netmetrixDomain);

	return self;
}

- (NSString *) netmetrixDomain
{
	NSArray *netmetrixDomains = @[ @"srf", @"rts", @"rtsi", @"rtr", @"swissinf" ];
	return netmetrixDomains[self.businessUnit];
}

#pragma mark - Track View

- (void) trackView
{
	NSString *netmetrixURLString = [NSString stringWithFormat:@"http://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", self.netmetrixDomain, self.appID, self.device];
	NSURL *netmetrixURL = [NSURL URLWithString:netmetrixURLString];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:netmetrixURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
	[request setHTTPMethod: @"GET"];
	[request setValue:@"image/gif" forHTTPHeaderField:@"Accept"];
	
	// Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
	NSString *systemVersion = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
	NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; CPU %@ %@ like Mac OS X)", self.device, self.operatingSystem, systemVersion];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	
	BOOL testMode = [self.appID isEqualToString:@"test"] || NSClassFromString(@"XCTestCase") != NULL;
	
	if (testMode)
	{
		RTSAnalyticsLogWarning(@"%@ response will be fake due to testing flag or xctest bundle presence", LoggerDomainAnalyticsNetmetrix);
	}
	else if (self.production)
	{
		RTSAnalyticsLogVerbose(@"%@ : will send view event:\nurl        = %@\nuser-agent = %@", LoggerDomainAnalyticsNetmetrix, netmetrixURLString, userAgent);
		[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			
			BOOL succes = !connectionError;
			if (succes) {
				RTSAnalyticsLogInfo(@"%@ view > %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod);
			}else{
				RTSAnalyticsLogError(@"%@ ERROR sending %@ view : %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod, connectionError.localizedDescription);
			}
			
			RTSAnalyticsLogDebug(@"%@ view event sent:\n%@", LoggerDomainAnalyticsNetmetrix, [(NSHTTPURLResponse *)response allHeaderFields]);
			
			NSMutableDictionary *userInfo = [@{ RTSAnalyticsNetmetrixRequestSuccessUserInfoKey: @(succes) } mutableCopy];
			if (response)
				userInfo[RTSAnalyticsNetmetrixRequestResponseUserInfoKey] = response;
			if (connectionError)
				userInfo[RTSAnalyticsNetmetrixRequestErrorUserInfoKey] = connectionError;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:RTSAnalyticsNetmetrixRequestDidFinishNotification object:request userInfo:[userInfo copy]];
		}];
	}
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
