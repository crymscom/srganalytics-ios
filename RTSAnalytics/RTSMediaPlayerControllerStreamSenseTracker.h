//
//  Created by Frédéric Humbert-Droz on 08/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTSAnalyticsMediaPlayerDataSource.h"

#import <RTSMediaPlayer/RTSMediaPlayerController.h>

#import <comScore-iOS-SDK/CSStreamSensePlugin.h>
#import <comScore-iOS-SDK/CSStreamSensePluginProtocol.h>

/**
 <#Description#>
 */
@interface RTSMediaPlayerControllerStreamSenseTracker : CSStreamSense

/**
 *  <#Description#>
 *
 *  @param mediaPlayerController <#mediaPlayerController description#>
 *  @param dataSource            <#dataSource description#>
 *
 *  @return <#return value description#>
 */
- (id) initWithPlayer:(RTSMediaPlayerController *)mediaPlayerController dataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;

/**
 *  <#Description#>
 *
 *  @param playerEvent <#playerEvent description#>
 */
- (void) notify:(CSStreamSenseEventType)playerEvent;

@end
