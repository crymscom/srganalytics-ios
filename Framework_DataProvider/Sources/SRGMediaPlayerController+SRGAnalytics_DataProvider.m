//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGSubdivision+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

static NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaCompositionKey";
static NSString * const SRGAnalyticsMediaPlayerStreamingMethodKey = @"SRGAnalyticsMediaPlayerStreamingMethodKey";
static NSString * const SRGAnalyticsMediaPlayerQualityKey = @"SRGAnalyticsMediaPlayerQualityKey";

typedef void (^SRGMediaPlayerDataProviderLoadCompletionBlock)(NSURL * _Nullable URL, SRGResource *resource, NSInteger index, NSArray<id<SRGSegment>> *segments, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error);

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Helpers

+ (SRGAnalyticsStreamLabels *)analyticsLabelsForMediaComposition:(SRGMediaComposition *)mediaComposition resource:(SRGResource *)resource
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    
    NSMutableDictionary<NSString *, NSString *> *customInfo = [NSMutableDictionary dictionary];
    if (mediaComposition.analyticsLabels) {
        [customInfo addEntriesFromDictionary:mediaComposition.analyticsLabels];
    }
    if (mediaComposition.mainChapter.analyticsLabels) {
        [customInfo addEntriesFromDictionary:mediaComposition.mainChapter.analyticsLabels];
    }
    if (resource.analyticsLabels) {
        [customInfo addEntriesFromDictionary:resource.analyticsLabels];
    }
    labels.customInfo = [customInfo copy];
    
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomInfo = [NSMutableDictionary dictionary];
    if (mediaComposition.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:mediaComposition.comScoreAnalyticsLabels];
    }
    if (mediaComposition.mainChapter.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:mediaComposition.mainChapter.comScoreAnalyticsLabels];
    }
    if (resource.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:resource.comScoreAnalyticsLabels];
    }
    labels.comScoreCustomInfo = [comScoreCustomInfo copy];
    
    return labels;
}

- (SRGRequest *)loadMediaComposition:(SRGMediaComposition *)mediaComposition
        withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                          streamType:(SRGStreamType)streamType
                             quality:(SRGQuality)quality
                        startBitRate:(NSInteger)startBitRate
                              resume:(BOOL)resume
                     completionBlock:(SRGMediaPlayerDataProviderLoadCompletionBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    if (startBitRate < 0) {
        startBitRate = 0;
    }
    
    SRGChapter *chapter = mediaComposition.mainChapter;
    
    if (streamingMethod == SRGStreamingMethodNone) {
        streamingMethod = chapter.recommendedStreamingMethod;
    }
    
    NSArray<SRGResource *> *resources = [chapter resourcesForStreamingMethod:streamingMethod];
    if (resources.count == 0) {
        resources = [chapter resourcesForStreamingMethod:chapter.recommendedStreamingMethod];
    }
    
    // Determine the stream type order to use (start with a default setup, overridden if a preferred type has been set),
    // from the lowest to the highest priority.
    NSArray<NSNumber *> *orderedStreamTypes = @[@(SRGStreamTypeOnDemand), @(SRGStreamTypeLive), @(SRGStreamTypeDVR)];
    if (streamType != SRGStreamTypeNone) {
        orderedStreamTypes = [[orderedStreamTypes mtl_arrayByRemovingObject:@(streamType)] arrayByAddingObject:@(streamType)];
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, streamType) ascending:NO comparator:^(NSNumber * _Nonnull streamType1, NSNumber * _Nonnull streamType2) {
        // Don't simply compare enum values as integers since their order might change.
        NSUInteger index1 = [orderedStreamTypes indexOfObject:streamType1];
        NSUInteger index2 = [orderedStreamTypes indexOfObject:streamType2];
        if (index1 == index2) {
            return NSOrderedSame;
        }
        else if (index1 < index2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    resources = [resources sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    // Resources are initially ordered by quality (see `-resourcesForStreamingMethod:` documentation), and this order
    // is kept stable by the stream type sort descriptor above. We therefore attempt to find a proper match for the specified
    // quality, otherwise we just use the first resource available.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(quality)];
    SRGResource *resource = [resources filteredArrayUsingPredicate:predicate].firstObject ?: resources.firstObject;
    if (! resource) {
        SRGAnalyticsMediaPlayerLogError(@"mediaplayer", @"No valid resource could be retrieved");
        return nil;
    }
    
    // Use the preferrred start bit rate is set. Currrently only supported by Akamai via a __b__ parameter (the actual
    // bitrate will be rounded to the nearest available quality)
    NSURL *URL = resource.URL;
    if (startBitRate != 0 && [URL.host containsString:@"akamai"]) {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        
        NSMutableArray<NSURLQueryItem *> *queryItems = [URLComponents.queryItems mutableCopy] ?: [NSMutableArray array];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"__b__" value:@(startBitRate).stringValue]];
        URLComponents.queryItems = [queryItems copy];
        
        URL = URLComponents.URL;
    }
    
    SRGRequest *request = [SRGDataProvider tokenizeURL:URL withCompletionBlock:^(NSURL * _Nullable URL, NSError * _Nullable error) {
        // Bypass token server response, if an error occurred. We don't want to block the media player here
        if (error) {
            URL = resource.URL;
        }
        
        SRGAnalyticsStreamLabels *labels = [SRGMediaPlayerController analyticsLabelsForMediaComposition:mediaComposition resource:resource];
        NSInteger index = [chapter.segments indexOfObject:mediaComposition.mainSegment];
        completionBlock(URL, resource, index, chapter.segments, labels, nil);
    }];
    if (resume) {
        [request resume];
    }
    return request;
}

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
    return [self loadMediaComposition:mediaComposition withPreferredStreamingMethod:streamingMethod streamType:streamType quality:quality startBitRate:startBitRate resume:resume completionBlock:^(NSURL * _Nullable URL, SRGResource *resource, NSInteger index, NSArray<id<SRGSegment>> *segments, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
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
    self.analyticsLabels = [SRGMediaPlayerController analyticsLabelsForMediaComposition:mediaComposition resource:resource];
    
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
