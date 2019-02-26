//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGMediaComposition+SRGAnalytics_DataProvider.h"
#import "SRGMediaComposition+SRGAnalytics_DataProvider_Private.h"
#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>
#import <SRGContentProtection/SRGContentProtection.h>

static NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaComposition";
static NSString * const SRGAnalyticsMediaPlayerResourceKey = @"SRGAnalyticsMediaPlayerResource";
static NSString * const SRGAnalyticsMediaPlayerSourceUidKey = @"SRGAnalyticsMediaPlayerSourceUid";

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Playback methods

- (BOOL)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                           atPosition:(SRGPosition *)position
                withPreferredSettings:(SRGPlaybackSettings *)preferredSettings
                             userInfo:(NSDictionary *)userInfo
                    completionHandler:(void (^)(void))completionHandler
{
    return [mediaComposition playbackContextWithPreferredSettings:preferredSettings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
        if (resource.presentation == SRGPresentation360) {
            if (self.view.viewMode != SRGMediaPlayerViewModeMonoscopic && self.view.viewMode != SRGMediaPlayerViewModeStereoscopic) {
                self.view.viewMode = SRGMediaPlayerViewModeMonoscopic;
            }
        }
        else {
            self.view.viewMode = SRGMediaPlayerViewModeFlat;
        }
        
        NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
        fullUserInfo[SRGAnalyticsMediaPlayerMediaCompositionKey] = mediaComposition;
        fullUserInfo[SRGAnalyticsMediaPlayerResourceKey] = resource;
        fullUserInfo[SRGAnalyticsMediaPlayerSourceUidKey] = preferredSettings.sourceUid;
        if (userInfo) {
            [fullUserInfo addEntriesFromDictionary:userInfo];
        }
        
        SRGDRM *fairPlayDRM = [resource DRMWithType:SRGDRMTypeFairPlay];
        NSString *URN = mediaComposition.segmentURN ?: mediaComposition.chapterURN;
        AVURLAsset *asset = [AVURLAsset srg_assetWithURL:streamURL certificateURL:fairPlayDRM.certificateURL options:@{ SRGAssetOptionDiagnosticServiceNameKey : @"SRGPlaybackMetrics",
                                                                                                                        SRGAssetOptionDiagnosticReportNameKey : URN }];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [self prepareToPlayItem:playerItem atIndex:index position:position inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:[fullUserInfo copy] completionHandler:^{
            completionHandler ? completionHandler() : nil;
        }];
    }];
}

- (BOOL)playMediaComposition:(SRGMediaComposition *)mediaComposition
                  atPosition:(SRGPosition *)position
       withPreferredSettings:(SRGPlaybackSettings *)preferredSettings
                    userInfo:(NSDictionary *)userInfo
{
    return [self prepareToPlayMediaComposition:mediaComposition atPosition:position withPreferredSettings:preferredSettings userInfo:userInfo completionHandler:^{
        [self play];
    }];
}

#pragma mark Getters and setters

- (void)setMediaComposition:(SRGMediaComposition *)mediaComposition
{
    SRGMediaComposition *currentMediaComposition = self.userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey];
    if (! currentMediaComposition || ! mediaComposition) {
        return;
    }
    
    if (! [currentMediaComposition.mainChapter isEqual:mediaComposition.mainChapter]) {
        return;
    }
    
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy];
    userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey] = mediaComposition;
    self.userInfo = [userInfo copy];
    
    // Synchronize analytics labels
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(self.resource.quality)];
    SRGResource *resource = [[mediaComposition.mainChapter resourcesForStreamingMethod:self.resource.streamingMethod] filteredArrayUsingPredicate:predicate].firstObject;
    self.analyticsLabels = [mediaComposition analyticsLabelsForResource:resource sourceUid:self.userInfo[SRGAnalyticsMediaPlayerSourceUidKey]];
    
    self.segments = mediaComposition.mainChapter.segments;
}

- (SRGMediaComposition *)mediaComposition
{
    return self.userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey];
}

- (SRGResource *)resource
{
    return self.userInfo[SRGAnalyticsMediaPlayerResourceKey];
}

@end
