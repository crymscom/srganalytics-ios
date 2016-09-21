//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+SRGAnalytics.h"

@implementation NSString (SRGAnalytics)

- (NSString *)srg_comScoreTitleFormattedString
{
    NSCharacterSet *andSet = [NSCharacterSet characterSetWithCharactersInString:@"+&"];
    NSCharacterSet *strokeSet = [NSCharacterSet characterSetWithCharactersInString:@"=/\\<>()"];
    NSString *title = [[self componentsSeparatedByCharactersInSet:strokeSet] componentsJoinedByString:@"-"];
    return [[title componentsSeparatedByCharactersInSet:andSet] componentsJoinedByString:@"and"];
}

- (NSString *)srg_comScoreFormattedString
{
    NSLocale *posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"[^a-z0-9 -]" options:0 error:nil];
    
    NSString *normalizedString = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    normalizedString = [normalizedString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:posixLocale];
    normalizedString = [regexp stringByReplacingMatchesInString:normalizedString options:0 range:NSMakeRange(0, [normalizedString length]) withTemplate:@""];
    return [normalizedString stringByReplacingOccurrencesOfString:@" " withString:@"-"];
}

@end
