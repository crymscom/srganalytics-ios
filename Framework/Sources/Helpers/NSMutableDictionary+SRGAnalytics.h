//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (SRGAnalytics)

/**
 *  Set value and key iff both are non-`nil`.
 */
- (void)srg_safelySetObject:(nullable id)object forKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
