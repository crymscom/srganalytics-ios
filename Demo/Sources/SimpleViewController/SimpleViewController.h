//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

@interface SimpleViewController : UIViewController

@property (nonatomic, strong) NSArray *levels;
@property (nonatomic, strong) NSDictionary *customLabels;
@property (nonatomic, assign) BOOL srg_isOpenedFromPushNotification;
@property (nonatomic, assign, getter=srg_isTrackedAutomatically) BOOL srg_trackedAutomatically;

@end

