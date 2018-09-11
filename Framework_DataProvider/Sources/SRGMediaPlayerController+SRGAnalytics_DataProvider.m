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

#if __has_include(<SRGContentProtection/SRGContentProtection.h>)
#import <SRGContentProtection/SRGContentProtection.h>
#endif

static NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaCompositionKey";
static NSString * const SRGAnalyticsMediaPlayerResourceKey = @"SRGAnalyticsMediaPlayerResource";

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Playback methods

- (BOOL)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                           atPosition:(SRGPosition *)position
         withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                           streamType:(SRGStreamType)streamType
                              quality:(SRGQuality)quality
                                  DRM:(BOOL)DRM
                         startBitRate:(NSInteger)startBitRate
                             userInfo:(NSDictionary *)userInfo
                    completionHandler:(void (^)(void))completionHandler
{
    return [mediaComposition playbackContextWithPreferredStreamingMethod:streamingMethod streamType:streamType quality:quality DRM:DRM startBitRate:startBitRate contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
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
        if (userInfo) {
            [fullUserInfo addEntriesFromDictionary:userInfo];
        }
        
#if __has_include(<SRGContentProtection/SRGContentProtection.h>)
        AVURLAsset *asset = nil;
        if ([[AVURLAsset class] respondsToSelector:@selector(srg_assetWithURL:licenseURL:)]) {
            SRGDRM *fairPlayDRM = [resource DRMWithType:SRGDRMTypeFairPlay];
            NSString *URN = mediaComposition.segmentURN ?: mediaComposition.chapterURN;
            asset = [AVURLAsset srg_assetWithURL:streamURL licenseURL:fairPlayDRM.licenseURL userInfo:@{ SRGContentProtectionURNKey : URN }];
        }
        else {
            asset = [AVURLAsset assetWithURL:streamURL];
        }
#else
        AVURLAsset *asset = [AVURLAsset assetWithURL:streamURL];
#endif
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [self prepareToPlayItem:playerItem atIndex:index position:position inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:[fullUserInfo copy] completionHandler:^{
            completionHandler ? completionHandler() : nil;
        }];
    }];
}

- (BOOL)playMediaComposition:(SRGMediaComposition *)mediaComposition
                  atPosition:(SRGPosition *)position
withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                  streamType:(SRGStreamType)streamType
                     quality:(SRGQuality)quality
                         DRM:(BOOL)DRM
                startBitRate:(NSInteger)startBitRate
                    userInfo:(NSDictionary *)userInfo
{
    return [self prepareToPlayMediaComposition:mediaComposition atPosition:position withPreferredStreamingMethod:streamingMethod streamType:streamType quality:quality DRM:DRM startBitRate:startBitRate userInfo:userInfo completionHandler:^{
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
    self.analyticsLabels = [mediaComposition analyticsLabelsForResource:resource];
    
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
