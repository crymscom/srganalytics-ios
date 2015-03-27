//
//  NSString+RTSAnlyticsUtils.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 26/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "NSString+RTSAnalyticsUtils.h"

@implementation NSString (RTSAnalyticsUtils)

- (NSString *)comScoreFormattedString
{
    NSCharacterSet *andSet = [NSCharacterSet characterSetWithCharactersInString:@"+&"];
    NSCharacterSet *strokeSet = [NSCharacterSet characterSetWithCharactersInString:@"=/\\<>()"];
    NSString *tmp = [[self componentsSeparatedByCharactersInSet:strokeSet] componentsJoinedByString:@"-"];
    return [[tmp componentsSeparatedByCharactersInSet:andSet] componentsJoinedByString:@"and"];
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
