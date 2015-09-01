//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SegmentsMediaPlayerViewController : UIViewController

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

@end
