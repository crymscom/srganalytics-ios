//
//  Created by Frédéric Humbert-Droz on 10/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsNetmetrixTracker.h"

#import <AFNetworking/AFNetworking.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static NSString * const LoggerDomainAnalyticsNetmetrix = @"Netmetrix";

@interface RTSAnalyticsNetmetrixTracker ()

@property (nonatomic, strong) AFHTTPClient *netmetrixClient;

@end

@implementation RTSAnalyticsNetmetrixTracker

- (instancetype) initWithAppID:(NSString *)appID domain:(NSString *)domain
{
	if (!(self = [super init]))
		return nil;
	
	// Which User-Agent MUST be used is defined on http://www.net-metrix.ch/fr/produits/net-metrix-mobile/reglement/directives
	NSString *device;
	NSString *operatingSystem;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		device = @"phone";
		operatingSystem = @"iPhone OS";
	}
	else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		device = @"tablet";
		operatingSystem = @"iPad OS";
	}
	else
	{
		device = @"universal";
		operatingSystem = @"OS";
	}
	
	NSString *netmetrixURLString = [NSString stringWithFormat:@"http://%@.wemfbox.ch/cgi-bin/ivw/CP/apps/%@/ios/%@", domain, appID, device];
	
	_netmetrixClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:netmetrixURLString]];
	[_netmetrixClient registerHTTPOperationClass:[AFImageRequestOperation class]];
	[_netmetrixClient setDefaultHeader:@"Accept" value:@"image/gif"];
	
	NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iOS-%@; U; CPU %@ like Mac OS X)", device, operatingSystem];
	[_netmetrixClient setDefaultHeader:@"User-Agent" value:userAgent];
	
	DDLogDebug(@"%@ : URL: %@\nUserAgent: %@", LoggerDomainAnalyticsNetmetrix, netmetrixURLString, userAgent);

	return self;
}

- (void) trackView
{
	if (!self.netmetrixClient)
		return;
	
	DDLogVerbose(@"%@ : Sending netmetrix view", LoggerDomainAnalyticsNetmetrix);
	
	[self.netmetrixClient getPath:nil parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		DDLogDebug(@"%@ : Did send netmetrix GET view, %@", LoggerDomainAnalyticsNetmetrix, responseObject);
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		 DDLogError(@"%@ : Failed to send GET view, error: %@", LoggerDomainAnalyticsNetmetrix, error.localizedDescription);
	 }];
}


@end
