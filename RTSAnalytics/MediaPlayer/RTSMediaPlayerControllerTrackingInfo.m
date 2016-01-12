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
    // ns_st_pn: segment index, starting at 1 (send 1 for the full)
    // ns_st_tp: number of total parts (i.e., 1 if no segments)
    // Do not set ns_st_cl and ns_st_sl as it was the case in the past! It is the responsability of the IL Data Provider, as in Android.
    
    // Extract information from the segments controller when available
    id<RTSMediaSegment> segment = self.segment;
    if (segment) {
        RTSMediaSegmentsController *segmentsController = self.mediaPlayerController.segmentsController;
        
        if ([RTSMediaSegmentsController isFullLengthSegment:segment]) {
            NSArray *childSegments = [segmentsController childSegmentsForSegment:segment];
            return @{ @"ns_st_pn" : @"1", // starts at 1 because 'segment' is fullLength
                      @"ns_st_tp" : @(childSegments.count + 1).stringValue }; // starts at 1 because 'segment' is fullLength
        }
        else {
            NSUInteger fullLengthIncrement = ([segmentsController parentSegmentForSegment:segment] != nil) ? 1 : 0;
            NSArray *siblingSegments = [segmentsController siblingSegmentsForSegment:segment];
            return @{ @"ns_st_pn" : @([siblingSegments indexOfObject:segment] + 1 + fullLengthIncrement).stringValue, // starts at 1 anyway
                      @"ns_st_tp" : @(siblingSegments.count + fullLengthIncrement).stringValue }; // starts at 1 anyway
        }
    }
    // Otherwise extract information from the player controller
    else {
        NSMutableDictionary *labels = [NSMutableDictionary dictionary];
        labels[@"ns_st_pn"] = @"1";
        labels[@"ns_st_tp"] = @"1";
        return [labels copy];
    }
}

- (id<RTSMediaSegment>)segment
{
    if (_segment) {
        return _segment;
    }
    else {
        // If no segment has been provided, find the full-length currently being played (if a segment controller is available)
        RTSMediaSegmentsController *segmentsController = self.mediaPlayerController.segmentsController;
        if (segmentsController) {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<RTSMediaSegment>  _Nonnull segment, NSDictionary<NSString *,id> * _Nullable bindings) {
                return [self.mediaPlayerController.identifier isEqualToString:segment.segmentIdentifier]
                && [RTSMediaSegmentsController isFullLengthSegment:segment]
                && CMTimeRangeContainsTime(segment.timeRange, self.mediaPlayerController.player.currentTime);
            }];
            return [segmentsController.segments filteredArrayUsingPredicate:predicate].firstObject;
        }
        else {
            return nil;
        }
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
