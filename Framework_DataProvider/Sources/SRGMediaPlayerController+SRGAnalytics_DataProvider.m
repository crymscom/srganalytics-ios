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

static NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaCompositionKey";
static NSString * const SRGAnalyticsMediaPlayerStreamingMethodKey = @"SRGAnalyticsMediaPlayerStreamingMethodKey";
static NSString * const SRGAnalyticsMediaPlayerQualityKey = @"SRGAnalyticsMediaPlayerQualityKey";

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Playback methods

- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                 withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                   streamType:(SRGStreamType)streamType
                                      quality:(SRGQuality)quality
                                 startBitRate:(NSInteger)startBitRate
                                     userInfo:(NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    SRGRequest *request = [mediaComposition resourceWithPreferredStreamingMethod:streamingMethod streamType:streamType quality:quality startBitRate:startBitRate completionBlock:^(NSURL * _Nullable URL, SRGResource *resource, NSArray<id<SRGSegment>> *segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
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
        fullUserInfo[SRGAnalyticsMediaPlayerStreamingMethodKey] = @(resource.streamingMethod);
        fullUserInfo[SRGAnalyticsMediaPlayerQualityKey] = @(resource.quality);
        if (userInfo) {
            [fullUserInfo addEntriesFromDictionary:userInfo];
        }
        
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:[fullUserInfo copy] completionHandler:^{
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
    if (resume) {
        [request resume];
    }
    return request;
}

- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
        withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                          streamType:(SRGStreamType)streamType
                             quality:(SRGQuality)quality
                        startBitRate:(NSInteger)startBitRate
                            userInfo:(NSDictionary *)userInfo
                              resume:(BOOL)resume
                   completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    void (^playCompletionHandler)(NSError * _Nullable) = ^(NSError * _Nullable error) {
        if (! error) {
            [self play];
        }
        completionHandler ? completionHandler(error) : nil;
    };
    
    return [self prepareToPlayMediaComposition:mediaComposition
                  withPreferredStreamingMethod:streamingMethod
                                    streamType:streamType
                                       quality:quality
                                  startBitRate:startBitRate
                                      userInfo:userInfo
                                        resume:resume
                             completionHandler:playCompletionHandler];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(self.quality)];
    SRGResource *resource = [[mediaComposition.mainChapter resourcesForStreamingMethod:self.streamingMethod] filteredArrayUsingPredicate:predicate].firstObject;
    self.analyticsLabels = [mediaComposition analyticsLabelsForResource:resource];
    
    self.segments = mediaComposition.mainChapter.segments;
}

- (SRGMediaComposition *)mediaComposition
{
    return self.userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey];
}

- (SRGStreamingMethod)streamingMethod
{
    return [self.userInfo[SRGAnalyticsMediaPlayerStreamingMethodKey] integerValue];
}

- (SRGQuality)quality
{
    return [self.userInfo[SRGAnalyticsMediaPlayerQualityKey] integerValue];
}

@end
