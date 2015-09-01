//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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
