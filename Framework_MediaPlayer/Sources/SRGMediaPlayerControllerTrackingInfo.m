//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerControllerTrackingInfo.h"

@interface SRGMediaPlayerControllerTrackingInfo ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SRGMediaPlayerControllerTrackingInfo

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    NSParameterAssert(mediaPlayerController);
    
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
    }
    return self;
}

@end
