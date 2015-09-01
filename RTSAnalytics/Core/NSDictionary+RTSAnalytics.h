//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (RTSAnalytics)

/**
 *  Set value and key iff both are non-nil
 */
- (void)safeSetValue:(id)value forKey:(NSString *)key;

@end
