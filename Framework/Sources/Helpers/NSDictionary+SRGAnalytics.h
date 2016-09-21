//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (SRGAnalytics)

/**
 *  Set value and key iff both are non-nil
 */
- (void)safeSetValue:(nullable id)value forKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
