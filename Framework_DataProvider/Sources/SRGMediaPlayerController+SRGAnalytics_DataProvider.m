//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_DataProvider.h"

#import "SRGMediaCompositionTrackingDelegate.h"
#import "SRGSegment+SRGAnalytics_DataProvider.h"

typedef void (^SRGMediaPlayerDataProviderLoadCompletionBlock)(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, id<SRGAnalyticsMediaPlayerTrackingDelegate>  _Nullable trackingDelegate, NSError * _Nullable error);

@implementation SRGMediaPlayerController (SRGAnalytics_DataProvider)

- (SRGRequest *)loadMediaComposition:(SRGMediaComposition *)mediaComposition
                withPreferredQuality:(SRGQuality)preferredQuality
                     completionBlock:(SRGMediaPlayerDataProviderLoadCompletionBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    SRGChapter *chapter = mediaComposition.mainChapter;
    NSArray<SRGResource *> *resources = [chapter resourcesForProtocol:SRGProtocolHLS];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quality == %@", @(preferredQuality)];
    SRGResource *resource = [resources filteredArrayUsingPredicate:predicate].firstObject ?: resources.firstObject;
    
    return [SRGDataProvider tokenizeURL:resource.URL withCompletionBlock:^(NSURL * _Nullable URL, NSError * _Nullable error) {
        if (error) {
            completionBlock(nil, NSNotFound, nil, nil, error);
            return;
        }
        
        SRGMediaCompositionTrackingDelegate *trackingDelegate = [[SRGMediaCompositionTrackingDelegate alloc] initWithMediaComposition:mediaComposition resource:resource];
        NSInteger index = [chapter.segments indexOfObject:mediaComposition.mainSegment];
        completionBlock(resource.URL, index, chapter.segments, trackingDelegate, nil);
    }];
}

- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                         withPreferredQuality:(SRGQuality)preferredQuality
                                     userInfo:(NSDictionary *)userInfo
                            completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredQuality:preferredQuality completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, id<SRGAnalyticsMediaPlayerTrackingDelegate>  _Nullable trackingDelegate, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withTrackingDelegate:trackingDelegate userInfo:userInfo completionHandler:^{
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
                withPreferredQuality:(SRGQuality)preferredQuality
                            userInfo:(NSDictionary *)userInfo
                   completionHandler:(void (^)(NSError *error))completionHandler
{
    return [self loadMediaComposition:mediaComposition withPreferredQuality:preferredQuality completionBlock:^(NSURL * _Nullable URL, NSInteger index, NSArray<id<SRGSegment>> *segments, id<SRGAnalyticsMediaPlayerTrackingDelegate>  _Nullable trackingDelegate, NSError * _Nullable error) {
        if (error) {
            completionHandler ? completionHandler(error) : nil;
            return;
        }
        
        [self prepareToPlayURL:URL atIndex:index inSegments:segments withTrackingDelegate:trackingDelegate userInfo:userInfo completionHandler:^{
            [self play];
            completionHandler ? completionHandler(nil) : nil;
        }];
    }];
}

@end
