//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+RTSAnalytics.h"

@implementation NSString (RTSAnalytics)

- (NSString *)comScoreTitleFormattedString
{
    NSCharacterSet *andSet = [NSCharacterSet characterSetWithCharactersInString:@"+&"];
    NSCharacterSet *strokeSet = [NSCharacterSet characterSetWithCharactersInString:@"=/\\<>()"];
    NSString *tmp = [[self componentsSeparatedByCharactersInSet:strokeSet] componentsJoinedByString:@"-"];
    return [[tmp componentsSeparatedByCharactersInSet:andSet] componentsJoinedByString:@"and"];
}

- (NSString *)comScoreFormattedString
{
	NSLocale *posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"[^a-z0-9 -]" options:0 error:nil];
	
	NSString *normalizedString = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
	normalizedString = [normalizedString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:posixLocale];
	normalizedString = [regexp stringByReplacingMatchesInString:normalizedString options:0 range:NSMakeRange(0, [normalizedString length]) withTemplate:@""];
	return [normalizedString stringByReplacingOccurrencesOfString:@" " withString:@"-"];
}

- (NSString *)truncateAndAddEllipsisForStatistics
{
    return [self truncateAndAddEllipsis:50];
}

- (NSString *)truncateAndAddEllipsis:(int)maxLength
{
    if ([self length] > maxLength) {
        return [NSString stringWithFormat:@"%@...",[self substringToIndex:maxLength-3]];
    }
    return self;
}

@end
