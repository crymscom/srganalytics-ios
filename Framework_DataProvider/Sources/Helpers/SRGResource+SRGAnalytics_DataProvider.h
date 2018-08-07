//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Content protection types.
 */
typedef NS_ENUM(NSInteger, SRGContentProtection) {
    /**
     *  Not specified.
     */
    SRGContentProtectionNone = 0,
    /**
     *  Free from any content protection mechanism.
     */
    SRGContentProtectionFree,
    /**
     *  Akamai token-based protection.
     */
    SRGContentProtectionAkamaiToken,
    /**
     *  FairPlay encryption.
     */
    SRGContentProtectionFairPlay,
    /**
     *  Widevine encryption. Not supported natively on iOS, but useful for Google Cast receivers.
     */
    SRGContentProtectionWidevine,
    /**
     *  PlayReady encryption. Not supported natively on iOS, but useful for Google Cast receivers.
     */
    SRGContentProtectionPlayReady
};

@interface SRGResource (SRGAnalytics_DataProvider)

/**
 *  The recommended content protection to apply when attempting to play the receiver URL. Attempting to play the
 *  resource with another content protection type might work but is not guaranteed.
 */
@property (nonatomic, readonly) SRGContentProtection srg_recommendedContentProtection;

@end

NS_ASSUME_NONNULL_END
