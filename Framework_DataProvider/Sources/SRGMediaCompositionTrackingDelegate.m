//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaCompositionTrackingDelegate.h"

@interface SRGMediaCompositionTrackingDelegate ()

@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGResource *resource;

@end

@implementation SRGMediaCompositionTrackingDelegate

#pragma mark Object lifecycle

- (instancetype)initWithMediaComposition:(SRGMediaComposition *)mediaComposition resource:(nonnull SRGResource *)resource
{
    if (self = [super init]) {
        self.mediaComposition = mediaComposition;
        self.resource = resource;
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark SRGAnalyticsMediaPlayerTrackingDelegate protocol

- (NSDictionary<NSString *,NSString *> *)labelsForContent
{
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    if (self.mediaComposition.analyticsLabels) {
        [labels addEntriesFromDictionary:self.mediaComposition.analyticsLabels];
    }
    if (self.mediaComposition.mainChapter.analyticsLabels) {
        [labels addEntriesFromDictionary:self.mediaComposition.mainChapter.analyticsLabels];
    }
    if (self.resource.analyticsLabels) {
        [labels addEntriesFromDictionary:self.resource.analyticsLabels];
    }
    return [labels copy];
}

- (NSDictionary<NSString *,NSString *> *)labelsForSegment:(SRGSegment *)segment
{
    return segment.analyticsLabels;
}

@end
