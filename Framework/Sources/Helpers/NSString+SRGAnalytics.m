//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+SRGAnalytics.h"

@implementation NSString (SRGAnalytics)

- (NSString *)srg_comScoreFormattedString
{
    NSString *normalizedString = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    
    // Remove accentuated characters
    NSLocale *posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    normalizedString = [normalizedString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:posixLocale];
    
    // See rules at https://srfmmz.atlassian.net/wiki/display/SRGPLAY/Measurement+of+SRG+Player+Apps
    NSCharacterSet *andSet = [NSCharacterSet characterSetWithCharactersInString:@"+&"];
    normalizedString = [[normalizedString componentsSeparatedByCharactersInSet:andSet] componentsJoinedByString:@"and"];
    
    // Replace all non-alphanumeric characters with hyphens
    NSCharacterSet *nonAlphanumericCharacters = [NSCharacterSet alphanumericCharacterSet].invertedSet;
    return [[normalizedString componentsSeparatedByCharactersInSet:nonAlphanumericCharacters] componentsJoinedByString:@"-"];
}

@end
