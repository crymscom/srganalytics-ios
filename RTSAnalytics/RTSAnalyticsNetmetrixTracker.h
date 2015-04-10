//
//  Created by Frédéric Humbert-Droz on 10/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  <#Description#>
 */
@interface RTSAnalyticsNetmetrixTracker : NSObject

/**
 *  <#Description#>
 *
 *  @param appID  <#appID description#>
 *  @param domain <#domain description#>
 *
 *  @return <#return value description#>
 */
- (instancetype) initWithAppID:(NSString *)appID domain:(NSString *)domain;

/**
 *  <#Description#>
 */
- (void) trackView;

@end
