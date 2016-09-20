//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"
#import "SRGAnalyticsNetmetrixTracker.h"
#import "SRGAnalyticsLogger.h"

#import <UIKit/UIKit.h>

static NSString * const LoggerDomainAnalyticsNetmetrix = @"Netmetrix";

@interface SRGAnalyticsNetmetrixTracker ()

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;

@end

@implementation SRGAnalyticsNetmetrixTracker

- (instancetype) initWithAppID:(NSString *)appID businessUnit:(SSRBusinessUnit)businessUnit
{
	if (!(self = [super init]))
		return nil;
	
	_appID = appID;
	_businessUnit = businessUnit;
	
	SRGAnalyticsLogDebug(@"%@ initialization\nAppID: %@\nDomain: %@", LoggerDomainAnalyticsNetmetrix, appID, self.netmetrixDomain);

	return self;
}

- (NSString *) netmetrixDomain
{
	NSArray *netmetrixDomains = @[ @"srf", @"SRG", @"SRGi", @"rtr", @"swissinf" ];
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
		SRGAnalyticsLogWarning(@"%@ response will be fake due to testing flag or xctest bundle presence", LoggerDomainAnalyticsNetmetrix);
	}
	else
	{
		SRGAnalyticsLogVerbose(@"%@ : will send view event:\nurl        = %@\nuser-agent = %@", LoggerDomainAnalyticsNetmetrix, netmetrixURLString, userAgent);
		[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			
			BOOL succes = !connectionError;
			if (succes) {
				SRGAnalyticsLogInfo(@"%@ view > %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod);
			}else{
				SRGAnalyticsLogError(@"%@ ERROR sending %@ view : %@", LoggerDomainAnalyticsNetmetrix, request.HTTPMethod, connectionError.localizedDescription);
			}
			
			SRGAnalyticsLogDebug(@"%@ view event sent:\n%@", LoggerDomainAnalyticsNetmetrix, [(NSHTTPURLResponse *)response allHeaderFields]);
			
			NSMutableDictionary *userInfo = [@{ SRGAnalyticsNetmetrixRequestSuccessUserInfoKey: @(succes) } mutableCopy];
			if (response)
				userInfo[SRGAnalyticsNetmetrixRequestResponseUserInfoKey] = response;
			if (connectionError)
				userInfo[SRGAnalyticsNetmetrixRequestErrorUserInfoKey] = connectionError;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsNetmetrixRequestDidFinishNotification object:request userInfo:[userInfo copy]];
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
