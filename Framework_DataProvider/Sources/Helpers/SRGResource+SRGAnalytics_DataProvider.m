//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGResource+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

@implementation SRGResource (SRGAnalytics_DataProvider)

- (SRGContentProtection)srg_recommendedContentProtection
{
    SRGDRM *fairPlayDRM = [self DRMWithType:SRGDRMTypeFairPlay];
    if (fairPlayDRM) {
        return SRGContentProtectionFairPlay;
    }
    else if (self.streamingMethod == SRGStreamingMethodHLS && [self.URL.absoluteString containsString:@"akamai"]) {
        return SRGContentProtectionAkamaiToken;
    }
    else {
        return SRGContentProtectionFree;
    }
}

@end
