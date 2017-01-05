//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "AppDelegate.h"
#import "SimpleViewController.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return @"Demo list";
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            SimpleViewController *simpleViewController = nil;
            
            switch (indexPath.row) {
                case 0: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking"
                                                                                levels:nil
                                                                          customLabels:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 1: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with levels"
                                                                                levels:@[@"level1", @"level2", @"level3"]
                                                                          customLabels:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 2: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with many levels"
                                                                                levels:@[@"level1", @"level2", @"level3", @"level4", @"level5", @"level6", @"level7", @"level8", @"level9", @"level10", @"level11", @"level12"]
                                                                          customLabels:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 3: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking with levels and custom labels"
                                                                                levels:@[@"level1", @"level2"]
                                                                          customLabels:@{ @"custom_label": @"custom_value" }
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                case 4: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@"Manual tracking"
                                                                                levels:nil
                                                                          customLabels:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:NO];
                    break;
                }
                    
                case 5: {
                    simpleViewController = [[SimpleViewController alloc] initWithTitle:@""
                                                                                levels:nil
                                                                          customLabels:nil
                                                            openedFromPushNotification:NO
                                                                  trackedAutomatically:YES];
                    break;
                }
                    
                default: {
                    return;
                    break;
                }
            }
            [self.navigationController pushViewController:simpleViewController animated:YES];
            break;
        }
            
        case 1: {
            NSURL *URL = nil;
            
            switch (indexPath.row) {
                case 0: {
                    URL = [NSURL URLWithString:@"http://fr-par-iphone-2.cdn.hexaglobe.net/streaming/euronews_ewns/9-live.m3u8"];
                    break;
                }
                    
                case 1: {
                    URL = [NSURL URLWithString:@"http://stream-i.rts.ch/i/tp/1993/tp_10071993-,450,k.mp4.csmil/master.m3u8"];
                    break;
                }
                    
                case 2: {
                    URL = [NSURL URLWithString:@"https://wowza.jwplayer.com/live/jelly.stream/playlist.m3u8?DVR"];
                    break;
                }

                    
                default: {
                    return;
                    break;
                }
            }
            
            SRGMediaPlayerViewController *playerViewController = [[SRGMediaPlayerViewController alloc] init];
            [playerViewController.controller playURL:URL
                                              atTime:kCMTimeZero
                                        withSegments:nil
                                     analyticsLabels:nil
                                            userInfo:nil];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 2: {
            UIViewController *simpleViewController = [[SimpleViewController alloc] initWithTitle:@"From push notification"
                                                                                          levels:nil
                                                                                    customLabels:nil
                                                                      openedFromPushNotification:YES
                                                                            trackedAutomatically:YES];
            [self.navigationController pushViewController:simpleViewController animated:YES];
            break;
        }
            
        default: {
            return;
            break;
        }
    }
}

@end
