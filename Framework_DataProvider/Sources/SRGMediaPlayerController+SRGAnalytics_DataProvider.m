//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGSubdivision+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaCompositionKey";

typedef void (^SRGMediaPlayerDataProviderLoadCompletionBlock)(NSURL * _Nullable URL, SRGStreamType streamType, NSInteger index, NSArray<id<SRGSegment>> *segments, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error);

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

#pragma mark Helpers

+ (NSDictionary *)fullInfoWithMediaComposition:(SRGMediaComposition *)mediaComposition userInfo:(NSDictionary *)userInfo
{
    NSParameterAssert(mediaComposition);
    
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    fullUserInfo[SRGAnalyticsMediaPlayerMediaCompositionKey] = mediaComposition;
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

- (SRGRequest *)loadMediaComposition:(SRGMediaComposition *)mediaComposition
        withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
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
    
    // Find the best resource subset matching the streaming method and quality. Prefer DVR streams to live streams.
    NSArray<SRGResource *> *resources = [chapter resourcesForStreamingMethod:streamingMethod];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(quality)];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, streamType) ascending:YES comparator:^(NSNumber * _Nonnull streamType1, NSNumber * _Nonnull streamType2) {
        // Don't simply compare enum values as integers, since their order might change.
        NSArray<NSNumber *> *orderedStreamTypes = @[ @(SRGStreamTypeDVR), @(SRGStreamTypeLive), @(SRGStreamTypeOnDemand) ];
        
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
    SRGResource *resource = [[resources filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]].firstObject ?: [resources sortedArrayUsingDescriptors:@[sortDescriptor]].firstObject;
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
        
        NSInteger index = [chapter.segments indexOfObject:mediaComposition.mainSegment];
        completionBlock(URL, resource.streamType, index, chapter.segments, labels, nil);
    }];
    if (resume) {
        [request resume];
    }
    return request;
}

#pragma mark Playback methods

- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                 withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                      quality:(SRGQuality)quality
                                 startBitRate:(NSInteger)startBitRate
                                     userInfo:(NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredStreamingMethod:streamingMethod quality:quality startBitRate:startBitRate resume:resume completionBlock:^(NSURL * _Nullable URL, SRGStreamType streamType, NSInteger index, NSArray<id<SRGSegment>> *segments, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithMediaComposition:mediaComposition userInfo:userInfo];
        
        if (streamType == SRGStreamTypeOnDemand) {
            [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
                completionHandler ? completionHandler(nil) : nil;
            }];
        }
        // Don't load segments in the media player controller preparation if it's a live stream or a DVR stream.
        else {
            CMTime time = kCMTimeZero;
            if (streamType == SRGStreamTypeDVR && index != NSNotFound) {
                time = segments[index].srg_timeRange.start;
            }
            [self prepareToPlayURL:URL atTime:time withSegments:nil analyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
                completionHandler ? completionHandler(nil) : nil;
            }];
        }
    }];
}

- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
        withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                             quality:(SRGQuality)quality
                        startBitRate:(NSInteger)startBitRate
                            userInfo:(NSDictionary *)userInfo
                              resume:(BOOL)resume
                   completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredStreamingMethod:streamingMethod quality:quality startBitRate:startBitRate resume:resume completionBlock:^(NSURL * _Nullable URL, SRGStreamType streamType, NSInteger index, NSArray<id<SRGSegment>> *segments, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithMediaComposition:mediaComposition userInfo:userInfo];
        
        if (streamType == SRGStreamTypeOnDemand) {
            [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
                [self play];
                completionHandler ? completionHandler(nil) : nil;
            }];
        }
        // Don't load segments in the media player controller preparation if it's a live stream or a DVR stream.
        else {
            CMTime time = kCMTimeZero;
            if (streamType == SRGStreamTypeDVR && index != NSNotFound) {
                time = segments[index].srg_timeRange.start;
            }
            [self prepareToPlayURL:URL atTime:time withSegments:nil analyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
                [self play];
                completionHandler ? completionHandler(nil) : nil;
            }];
        }
    }];
}

#pragma mark Getters and setters

- (SRGMediaComposition *)mediaComposition
{
    return self.userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey];
}

@end
