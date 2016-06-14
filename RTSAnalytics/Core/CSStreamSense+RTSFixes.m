//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <ComScore/CSStreamSense.h>
#import <JRSwizzle/JRSwizzle.h>

#import "NSString+RTSAnalytics.h"

// Attempt to fix comScore internal crashes by having dictionary sometimes incorrectly accessed from several threads
// at the same time. The fix below assumes that the crash always occurred because of a concurrent access from the *main*
// thread and from another one. Having a look at the disassembled code, sending the corresponding work on the main thread
// should not lead to performance issues (the method namely contains only dictionary creation code).
@interface CSStreamSense (SRGFixes)

- (NSMutableDictionary *)swizzled_createMeasurementLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;
- (void)swizzled_setLabel:(NSString *)name value:(NSString *)value;

@end

@implementation CSStreamSense (SRGFixes)

+ (void)load
{
    [self jr_swizzleMethod:@selector(createMeasurementLabels:initialLabels:) withMethod:@selector(swizzled_createMeasurementLabels:initialLabels:) error:NULL];
    [self jr_swizzleMethod:@selector(setLabel:value:) withMethod:@selector(swizzled_setLabel:value:) error:NULL];
}

- (NSMutableDictionary *)swizzled_createMeasurementLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels
{
    if ([[NSThread currentThread] isMainThread]) {
        return [self swizzled_createMeasurementLabels:eventType initialLabels:initialLabels];
    }
    else {
        __block NSMutableDictionary *labels = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            labels = [self swizzled_createMeasurementLabels:eventType initialLabels:initialLabels];
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
