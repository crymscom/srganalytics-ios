//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@interface NSString (SRGAnalytics)

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
