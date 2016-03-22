//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <comScore-iOS-SDK-RTS/CSStreamSense.h>
#import <JRSwizzle/JRSwizzle.h>

// Attempt to fix comScore internal crashes by having dictionary sometimes incorrectly accessed from several threads
// at the same time. The fix below assumes that the crash always occurred because of a concurrent access from the *main*
// thread and from another one. Having a look at the disassembled code, sending the corresponding work on the main thread
// should not lead to performance issues (the method namely contains only dictionary creation code).
@interface CSStreamSense (SRGFixes)

- (NSMutableDictionary *)swizzled_createMeasurementLabels:(CSStreamSenseEventType)eventType initialLabels:(NSDictionary *)initialLabels;

@end

@implementation CSStreamSense (SRGFixes)

+ (void)load
{
    [self jr_swizzleMethod:@selector(createMeasurementLabels:initialLabels:) withMethod:@selector(swizzled_createMeasurementLabels:initialLabels:) error:NULL];
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

@end
