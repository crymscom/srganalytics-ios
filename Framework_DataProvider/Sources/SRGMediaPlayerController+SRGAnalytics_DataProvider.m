//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

typedef void (^SRGMediaPlayerDataProviderLoadCompletionBlock)(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *, NSString *> * _Nullable analyticsLabels, NSError * _Nullable error);

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

- (SRGRequest *)loadMediaComposition:(SRGMediaComposition *)mediaComposition
                withPreferredQuality:(SRGQuality)preferredQuality
                              resume:(BOOL)resume
                     completionBlock:(SRGMediaPlayerDataProviderLoadCompletionBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    SRGChapter *chapter = mediaComposition.mainChapter;
    NSArray<SRGResource *> *resources = [chapter resourcesForProtocol:SRGProtocolHLS];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGResource.new, quality), @(preferredQuality)];
    SRGResource *resource = [resources filteredArrayUsingPredicate:predicate].firstObject ?: resources.firstObject;
    
    SRGRequest *request = [SRGDataProvider tokenizeURL:resource.URL withCompletionBlock:^(NSURL * _Nullable URL, NSError * _Nullable error) {
        if (error) {
            completionBlock(nil, NSNotFound, nil, nil, error);
            return;
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

- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                         withPreferredQuality:(SRGQuality)preferredQuality
                                     userInfo:(NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredQuality:preferredQuality resume:resume completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *,NSString *> * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:userInfo completionHandler:^{
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
                withPreferredQuality:(SRGQuality)preferredQuality
                            userInfo:(NSDictionary *)userInfo
                              resume:(BOOL)resume
                   completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredQuality:preferredQuality resume:resume completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, NSDictionary<NSString *,NSString *> * _Nullable analyticsLabels, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withAnalyticsLabels:analyticsLabels userInfo:userInfo completionHandler:^{
            [self play];
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

@end
