//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGAnalytics_DataProvider_Private)

/**
 *  Return the consolidated analytics stream labels associated for the specified resource of the receiver.
 */
- (SRGAnalyticsStreamLabels *)analyticsLabelsForResource:(SRGResource *)resource;

@end

NS_ASSUME_NONNULL_END
