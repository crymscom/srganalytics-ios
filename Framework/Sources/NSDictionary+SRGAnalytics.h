//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SRGAnalytics)

/**
 *  Set value and key iff both are non-nil
 */
- (void)safeSetValue:(id)value forKey:(NSString *)key;

@end
