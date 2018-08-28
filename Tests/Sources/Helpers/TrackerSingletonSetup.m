//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <dlfcn.h>
#import <SRGAnalytics/SRGAnalytics.h>

// The singleton can be only setup once. Do not perform in a test case setup
__attribute__((constructor)) static void SetupTestSingletonTracker(void)
{
    // We cannot link the framework with the usual OTHER_LDFLAGS setting, the build would fail when building the open
    // source version which has no access to the framework.
    dlopen("SRGContentProtection.framework/SRGContentProtection", RTLD_LAZY);
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             comScoreVirtualSite:@"rts-app-test-v"
                                                                                             netMetrixIdentifier:@"test"];
    configuration.unitTesting = YES;
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
}
