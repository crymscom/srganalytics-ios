//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker+Logging_private.h"

#import <ComScore-iOS/CSCore.h>
#import <ComScore-iOS/CSComScore.h>
#import <ComScore-iOS/CSTaskExecutor.h>

#import "CSRequest+RTSAnalytics_private.h"
#import "RTSAnalyticsLogger.h"
#import "RTSAnalyticsComScoreTracker.h"

@implementation RTSAnalyticsTracker (Logging)

- (void)startLoggingInternalComScoreTasks
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comScoreRequestDidFinish:)
                                                 name:RTSAnalyticsComScoreRequestDidFinishNotification
                                               object:nil];
	
    // +[CSComScore setPixelURL:] is dispatched on an internal comScore queue, so calling +[CSComScore pixelURL]
    // right after doesn’t work, we must also dispatch it on the same queue!
	[[[CSComScore core] taskExecutor] execute:^
	 {
		 const SEL selectors[] = {
			 @selector(appName),
			 @selector(pixelURL),
			 @selector(publisherSecret),
			 @selector(customerC2),
			 @selector(version),
			 @selector(labels)
		 };
		 
		 NSMutableString *message = [NSMutableString new];
		 for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
			 SEL selector = selectors[i];
			 [message appendFormat:@"%@: %@\n", NSStringFromSelector(selector), [CSComScore performSelector:selector]];
		 }
		 [message deleteCharactersInRange:NSMakeRange(message.length - 1, 1)];
		 RTSAnalyticsLogDebug(@"%@", message);
		 
	 } background:YES];
}

#pragma mark - Notifications

- (void)comScoreRequestDidFinish:(NSNotification *)notification
{
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
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
	
	NSString *event = ns_st_ev ?  [typeSymbol stringByAppendingFormat:@" %@", ns_st_ev] : ns_ap_ev;
	NSString *name = ns_st_ev ? [NSString stringWithFormat:@"%@ / %@", labels[@"ns_st_pl"], labels[@"ns_st_ep"]] : labels[@"name"];
	
	BOOL success = [notification.userInfo[RTSAnalyticsComScoreRequestSuccessUserInfoKey] boolValue];
	if (success) {
		RTSAnalyticsLogInfo(@"%@ > %@", event, name);
	}
	else {
		RTSAnalyticsLogError(@"ERROR sending %@ > %@", event, name);
	}
	
	RTSAnalyticsLogDebug(@"Comscore %@ event sent:\n%@", labels[@"ns_type"], dictionaryRepresentation);
}

@end
