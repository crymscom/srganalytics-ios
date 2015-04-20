//
//  Created by Frédéric Humbert-Droz on 19/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;

/**
 *  The implementation swizzles `viewDidLoad` to keep a UIViewController reference for media analytics
 */
@interface UIViewController (RTSAnalyticsMediaPlayer)

/**
 *  Force tracking a media. Create a new `RTSMediaPlayerControllerStreamSenseTracker` instance and sends a "start" event type.
 *
 *  @param mediaPlayerController the media player controller instance to track
 */
- (void) startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController;

/**
 *  Force to stop tracking a media. Automatically sends an "end" event type and remove the `RTSMediaPlayerControllerStreamSenseTracker` instance.
 *
 *  @param mediaPlayerController the media player controller instance to be removed from tracking
 */
- (void) stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController;

@end
