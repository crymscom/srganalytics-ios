//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition+SRGAnalytics_DataProvider.h"

#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

@implementation SRGMediaComposition (SRGAnalytics_DataProvider)

- (SRGAnalyticsStreamLabels *)analyticsLabelsForResource:(SRGResource *)resource
{
    NSAssert([self.mainChapter.resources containsObject:resource], @"The specified resource must be associated with the current context");
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    
    NSMutableDictionary<NSString *, NSString *> *customInfo = [NSMutableDictionary dictionary];
    if (self.analyticsLabels) {
        [customInfo addEntriesFromDictionary:self.analyticsLabels];
    }
    if (self.mainChapter.analyticsLabels) {
        [customInfo addEntriesFromDictionary:self.mainChapter.analyticsLabels];
    }
    if (resource.analyticsLabels) {
        [customInfo addEntriesFromDictionary:resource.analyticsLabels];
    }
    labels.customInfo = [customInfo copy];
    
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomInfo = [NSMutableDictionary dictionary];
    if (self.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:self.comScoreAnalyticsLabels];
    }
    if (self.mainChapter.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:self.mainChapter.comScoreAnalyticsLabels];
    }
    if (resource.comScoreAnalyticsLabels) {
        [comScoreCustomInfo addEntriesFromDictionary:resource.comScoreAnalyticsLabels];
    }
    labels.comScoreCustomInfo = [comScoreCustomInfo copy];
    
    return labels;
}

- (SRGRequest *)resourceURLWithPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                             streamType:(SRGStreamType)streamType
                                                quality:(SRGQuality)quality
                                           startBitRate:(NSInteger)startBitRate
                                        completionBlock:(SRGResourceURLCompletionBlock)completionBlock
{
    if (startBitRate < 0) {
        startBitRate = 0;
    }
    
    SRGChapter *chapter = self.mainChapter;
    
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
    
    NSSortDescriptor *streamTypeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, streamType) ascending:NO comparator:^(NSNumber * _Nonnull streamType1, NSNumber * _Nonnull streamType2) {
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
    
    NSSortDescriptor *URLSchemeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGResource.new, URL) ascending:NO comparator:^NSComparisonResult(NSURL * _Nonnull URL1, NSURL * _Nonnull URL2) {
        // Only declare ordering for important URL schemes. For other schemes the initial order will be preserved
        NSArray<NSString *> *orderedURLSchemes = @[@"http", @"https"];
        
        NSUInteger index1 = [orderedURLSchemes indexOfObject:URL1.scheme];
        NSUInteger index2 = [orderedURLSchemes indexOfObject:URL2.scheme];
        if (index1 == index2) {
            return NSOrderedSame;
        }
        // Unknown scheme < known scheme
        else if (index1 == NSNotFound) {
            return NSOrderedAscending;
        }
        // Known scheme > unknown scheme
        else if (index2 == NSNotFound) {
            return NSOrderedDescending;
        }
        else if (index1 < index2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    resources = [resources sortedArrayUsingDescriptors:@[streamTypeSortDescriptor, URLSchemeSortDescriptor]];
    
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
        
        SRGAnalyticsStreamLabels *labels = [self analyticsLabelsForResource:resource];
        NSInteger index = [chapter.segments indexOfObject:self.mainSegment];
        completionBlock(URL, resource, chapter.segments, index, labels, nil);
    }];
    return request;
}

@end
