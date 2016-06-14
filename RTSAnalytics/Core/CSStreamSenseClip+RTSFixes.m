//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <ComScore/CSStreamSenseClip.h>
#import <JRSwizzle/JRSwizzle.h>

#import "NSString+RTSAnalytics.h"

// See CSStreamSense+SRGFixes.m
@interface CSStreamSenseClip (SRGFixes)

- (NSMutableDictionary *)swizzled_createLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;
- (void)swizzled_setLabel:(NSString *)name value:(NSString *)value;

@end

@implementation CSStreamSenseClip (SRGFixes)

+ (void)load
{
    [self jr_swizzleMethod:@selector(createLabels:initialLabels:) withMethod:@selector(swizzled_createLabels:initialLabels:) error:NULL];
    [self jr_swizzleMethod:@selector(setLabel:value:) withMethod:@selector(swizzled_setLabel:value:) error:NULL];
}

- (NSMutableDictionary *)swizzled_createLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels
{
    if ([[NSThread currentThread] isMainThread]) {
        return [self swizzled_createLabels:eventType initialLabels:initialLabels];
    }
    else {
        __block NSMutableDictionary *labels = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            labels = [self swizzled_createLabels:eventType initialLabels:initialLabels];
        });
        return labels;
    }
}

- (void)swizzled_setLabel:(NSString *)name value:(NSString *)value
{
    // FIXME: Workaround for a comScore issue with values containing quotes ("). Events containing such values are probably
    //        not correctly percent encoded, and such events are inhibited. Percent encode everything before sending to
    //        the comScore library until a fix has been made
    [self swizzled_setLabel:name value:[value percentEncodedStringWithEncoding:NSUTF8StringEncoding]];
}

@end
