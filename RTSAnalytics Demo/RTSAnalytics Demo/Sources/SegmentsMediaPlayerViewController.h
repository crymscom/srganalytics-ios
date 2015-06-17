//
//  Created by Samuel Défago on 12/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface SegmentsMediaPlayerViewController : UIViewController

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

@end
