//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CSRequest+SRGAnalytics.h"
#import <objc/runtime.h>

NSString * const SRGAnalyticsComScoreRequestDidFinishNotification = @"SRGAnalyticsComScoreRequestDidFinish";
NSString * const SRGAnalyticsComScoreRequestSuccessUserInfoKey = @"SRGAnalyticsSuccess";
NSString * const SRGAnalyticsComScoreRequestLabelsUserInfoKey = @"SRGAnalyticsLabels";

@implementation CSRequest (SRGNotification)

static BOOL (*sendIMP)(CSRequest *, SEL);

static BOOL NotificationSend(CSRequest *self, SEL _cmd);
static BOOL NotificationSend(CSRequest *self, SEL _cmd)
{
	BOOL success = sendIMP(self, _cmd);
	
    // Fragile, might break with future versions of the comScore library
    id measurement = [self valueForKey:@"measurement"];
    NSDictionary *labelsMap = object_getIvar(measurement, class_getInstanceVariable([measurement class], "_labelsMap"));
    
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    for (id label in labelsMap.allValues) {
        NSString *name = [label valueForKey:@"name"];
        NSString *value = [label valueForKey:@"value"];
        labels[name] = value;
    }
    
	NSDictionary *userInfo = @{ SRGAnalyticsComScoreRequestSuccessUserInfoKey: @(success), SRGAnalyticsComScoreRequestLabelsUserInfoKey: [labels copy] };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsComScoreRequestDidFinishNotification object:self userInfo:userInfo];
    });
	return success;
}

+ (void)load
{
	Method send = class_getInstanceMethod(self, @selector(send));
	sendIMP = (__typeof__(sendIMP))method_getImplementation(send);
	NSAssert(sendIMP, @"-[CSRequest send] implementation not found");
	method_setImplementation(send, (IMP)NotificationSend);
}

@end
