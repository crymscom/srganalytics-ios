//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerControllerTrackingInfo.h"

@interface RTSMediaPlayerControllerTrackingInfo ()

@property (nonatomic, weak) RTSMediaPlayerController *mediaPlayerController;

@end

@implementation RTSMediaPlayerControllerTrackingInfo

- (instancetype)initWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    NSParameterAssert(mediaPlayerController);
    
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
    }
    return self;
}

@end
