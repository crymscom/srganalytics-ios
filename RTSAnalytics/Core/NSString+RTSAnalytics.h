//
//  NSString+RTSAnlyticsUtils.h
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 26/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RTSAnalytics)

/**
 *  Format the receiver in a standard way
 */
- (NSString *)comScoreTitleFormattedString;
- (NSString *)comScoreFormattedString;

/**
 *  Truncate strings longer than 50 (replacing last characters with ...)
 */
- (NSString *)truncateAndAddEllipsisForStatistics;

/**
 *  Truncate long strings longer than maxLength (replacing last characters with ...)
 */
- (NSString *)truncateAndAddEllipsis:(int)maxLength;

@end
