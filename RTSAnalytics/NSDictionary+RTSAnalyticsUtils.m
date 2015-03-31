//
//  NSDictionary+Utils.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 26/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "NSDictionary+RTSAnalyticsUtils.h"

@implementation NSDictionary (RTSAnalyticsUtils)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && key) {
        [self setValue:value forKey:key];
    }
}

@end