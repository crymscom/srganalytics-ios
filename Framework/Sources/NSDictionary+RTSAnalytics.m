//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSDictionary+RTSAnalytics.h"

@implementation NSDictionary (RTSAnalytics)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && key) {
        [self setValue:value forKey:key];
    }
}

@end
