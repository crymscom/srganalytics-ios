//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

NSString * const SRGAnalyticsMediaPlayerMediaCompositionKey = @"SRGAnalyticsMediaPlayerMediaCompositionKey";

typedef void (^SRGMediaPlayerDataProviderLoadCompletionBlock)(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *, NSString *> * _Nullable analyticsLabels, NSError * _Nullable error);

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
               withPreferredProtocol:(SRGProtocol)preferredProtocol
                    preferredQuality:(SRGQuality)preferredQuality
               preferredStartBitRate:(NSInteger)preferredStartBitRate
                              resume:(BOOL)resume
                     completionBlock:(SRGMediaPlayerDataProviderLoadCompletionBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    SRGChapter *chapter = mediaComposition.mainChapter;
    
    SRGProtocol protocol = (preferredProtocol != SRGProtocolNone) ? preferredProtocol : chapter.recommendedProtocol;
    NSArray<SRGResource *> *resources = [chapter resourcesForProtocol:protocol];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(preferredQuality)];
    SRGResource *resource = [resources filteredArrayUsingPredicate:predicate].firstObject ?: resources.firstObject;
    if (! resource) {
        return nil;
    }
    
    SRGRequest *request = [SRGDataProvider tokenizeURL:resource.URL withCompletionBlock:^(NSURL * _Nullable URL, NSError * _Nullable error) {
        // Bypass token server response, if an error occurred. We don't want to block the media player here
        if (error) {
            URL = resource.URL;
        }
        
        NSMutableDictionary<NSString *, NSString *> *analyticsLabels = [NSMutableDictionary dictionary];
        if (mediaComposition.analyticsLabels) {
            [analyticsLabels addEntriesFromDictionary:mediaComposition.analyticsLabels];
        }
        if (mediaComposition.mainChapter.analyticsLabels) {
            [analyticsLabels addEntriesFromDictionary:mediaComposition.mainChapter.analyticsLabels];
        }
        if (resource.analyticsLabels) {
            [analyticsLabels addEntriesFromDictionary:resource.analyticsLabels];
        }
        
        NSInteger index = [chapter.segments indexOfObject:mediaComposition.mainSegment];
        completionBlock(URL, index, chapter.segments, [analyticsLabels copy], nil);
    }];
    if (resume) {
        [request resume];
    }
    return request;
}

#pragma mark Playback methods

- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                        withPreferredProtocol:(SRGProtocol)preferredProtocol
                             preferredQuality:(SRGQuality)preferredQuality
                        preferredStartBitRate:(NSInteger)preferredStartBitRate
                                     userInfo:(NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredProtocol:preferredProtocol preferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate resume:resume completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *,NSString *> * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithMediaComposition:mediaComposition userInfo:userInfo];
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
               withPreferredProtocol:(SRGProtocol)preferredProtocol
                    preferredQuality:(SRGQuality)preferredQuality
               preferredStartBitRate:(NSInteger)preferredStartBitRate
                            userInfo:(NSDictionary *)userInfo
                              resume:(BOOL)resume
                   completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredProtocol:preferredProtocol preferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate resume:resume completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *,NSString *> * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithMediaComposition:mediaComposition userInfo:userInfo];
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:fullUserInfo completionHandler:^{
            [self play];
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

#pragma mark Getters and setters

- (SRGMediaComposition *)mediaComposition
{
    return self.userInfo[SRGAnalyticsMediaPlayerMediaCompositionKey];
}

@end
