//
//  Created by Frédéric Humbert-Droz on 19/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/RTSMediaPlayerController.h>

/**
 *  The `RTSAnalyticsMediaPlayerDelegate` groups methods that are used to customize stream measurement behaviour when using `RTSMediaPlayerController`.
 */
@protocol RTSAnalyticsMediaPlayerDelegate <NSObject>
@optional

/**
 *  Method called before a CSStreamSense instance is automatically created. If not implemented, the default answer is considered
 *  to be 'YES', that is, a new stream tracker will be created.
 *
 *  @param identifier the identifier of the currently playing media.
 *
 *  @return YES, for allowing to track the media, NO otherwise.
 *
 *  @discussion A media tracker is created each time a new media player starts, however for some reasons (by ex: multilive) some streams should not be tracked.
 *  To force the creation of a new stream tracker instance call `-startTrackingMediaPlayerController:`, @see `UIViewController+RTSAnalyticsMediaPlayer.h`
 */
- (BOOL) shouldTrackMediaWithIdentifier:(NSString *)identifier;

@end
