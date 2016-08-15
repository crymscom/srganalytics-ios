//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

//! Project version number for SRGAnalytics.
FOUNDATION_EXPORT double SRGAnalyticsVersionNumber;

//! Project version string for SRGAnalytics.
FOUNDATION_EXPORT const unsigned char SRGAnalyticsVersionString[];

#import <SRGAnalytics/RTSAnalyticsTracker.h>
#import <SRGAnalytics/RTSAnalyticsComScoreTracker.h>
#import <SRGAnalytics/RTSAnalyticsNetmetrixTracker.h>
#import <SRGAnalytics/RTSAnalyticsPageViewDataSource.h>
#import <SRGAnalytics/UIViewController+RTSAnalytics.h>

#if __has_include("RTSAnalyticsMediaPlayer.h")
#import <SRGAnalytics/RTSAnalyticsMediaPlayer.h>
#endif