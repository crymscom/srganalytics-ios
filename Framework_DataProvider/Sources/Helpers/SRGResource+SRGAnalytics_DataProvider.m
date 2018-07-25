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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGDRM.new, type), @(SRGDRMTypeFairPlay)];
    if ([self.DRMs filteredArrayUsingPredicate:predicate].count != 0) {
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
