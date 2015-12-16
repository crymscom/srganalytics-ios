//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerControllerTrackingInfo.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface RTSMediaPlayerControllerTrackingInfo ()

@property (nonatomic, weak) RTSMediaPlayerController *mediaPlayerController;

@end

@implementation RTSMediaPlayerControllerTrackingInfo

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    NSParameterAssert(mediaPlayerController);
    
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
    }
    return self;
}

#pragma mark Labels

- (NSDictionary *)labels
{
    RTSMediaSegmentsController *segmentsController = self.mediaPlayerController.segmentsController;
    
    // If no segment has been provided, find the full-length currently being played (if a segment controller is available)
    id<RTSMediaSegment> segment = self.segment;
    if (!segment && segmentsController) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<RTSMediaSegment>  _Nonnull segment, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [self.mediaPlayerController.identifier isEqualToString:segment.segmentIdentifier]
                && [RTSMediaSegmentsController isFullLengthSegment:segment]
                && CMTimeRangeContainsTime(segment.timeRange, self.mediaPlayerController.player.currentTime);
        }];
        segment = [segmentsController.segments filteredArrayUsingPredicate:predicate].firstObject;
    }
    
    // ns_st_cl: current length
    // ns_st_sl: segment length (same as ns_st_cl for a full-length)
    // ns_st_pn: segment index, starting at 1 and +1 for accounting the fullLength. (send 1 for the full)
    // ns_st_tp: number of segments +1 for accounting the fullLength. (1 if no segments)
    
    // Extract information from the segments controller when available
    if (segment) {
        if ([RTSMediaSegmentsController isFullLengthSegment:segment]) {
            NSInteger duration = CMTimeGetSeconds(segment.timeRange.duration) * 1000;
            NSArray *childSegments = [segmentsController childSegmentsForSegment:segment];
            
            return @{ @"ns_st_cl" : @(duration).stringValue,
                      @"ns_st_sl" : @(duration).stringValue,
                      @"ns_st_pn" : @"1",
                      @"ns_st_tp" : @(childSegments.count + 1).stringValue };
        }
        else {
            id<RTSMediaSegment> fullLengthSegment = [segmentsController parentSegmentForSegment:segment];
            NSArray *siblingSegments = [segmentsController siblingSegmentsForSegment:segment];
            
            NSInteger segmentDuration = (NSInteger)(CMTimeGetSeconds(segment.timeRange.duration) * 1000);
            NSInteger fullLengthDuration = (NSInteger)(CMTimeGetSeconds(fullLengthSegment.timeRange.duration) * 1000);
            return @{ @"ns_st_cl" : @(segmentDuration).stringValue, // This is insanely identical to the next line... See SPA-2162 (2015-12-15).
                      @"ns_st_sl" : @(segmentDuration).stringValue,
                      @"ns_st_pn" : @([siblingSegments indexOfObject:segment] + 1 + 1).stringValue,
                      @"ns_st_tp" : @(siblingSegments.count + 1).stringValue };
        }
    }
    // Otherwise extract information from the player controller
    else {
        NSMutableDictionary *labels = [NSMutableDictionary dictionary];
        
        // The player time might be invalid. Check first
        CMTime durationTime = self.mediaPlayerController.player.currentItem.asset.duration;
        if (CMTIME_IS_VALID(durationTime)) {
            NSInteger duration = CMTimeGetSeconds(durationTime) * 1000;
            labels[@"ns_st_cl"] = @(duration).stringValue;
            labels[@"ns_st_sl"] = @(duration).stringValue;
        }
        
        labels[@"ns_st_pn"] = @"1";
        labels[@"ns_st_tp"] = @"1";
        
        return [labels copy];
    }
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    RTSMediaPlayerControllerTrackingInfo *copy = [[RTSMediaPlayerControllerTrackingInfo alloc] init];
    copy.mediaPlayerController = self.mediaPlayerController;
    copy.segment = self.segment;
    copy.skippingNextEvents = self.skippingNextEvents;
    return copy;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; mediaPlayerController: %@; segment: %@; labels: %@; skippingNextEvents: %@>",
            [self class],
            self,
            self.mediaPlayerController,
            self.segment,
            self.labels,
            self.skippingNextEvents ? @"YES" : @"NO"];
}

@end
