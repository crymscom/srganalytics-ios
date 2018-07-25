//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGContentProtection/SRGContentProtection.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGResource (SRGAnalytics_DataProvider)

/**
 *  The recommended content protection to apply when attempting to play the receiver URL.
 */
@property (nonatomic, readonly) SRGContentProtection srg_recommendedContentProtection;

@end

NS_ASSUME_NONNULL_END
