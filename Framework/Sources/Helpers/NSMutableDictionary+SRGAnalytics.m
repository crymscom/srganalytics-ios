//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSMutableDictionary+SRGAnalytics.h"

@implementation NSMutableDictionary (SRGAnalytics)

- (void)srg_safelySetObject:(id)object forKey:(NSString *)key
{
    if (object && key) {
        [self setObject:object forKey:key];
    }
    else {
        [self removeObjectForKey:key];
    }
}

@end
