//
//  SRGViewCountProvider.m
//  SRFPlayer
//
//  Created by Frédéric VERGEZ on 26/06/14.
//  Copyright (c) 2014 SRG SSR. All rights reserved.
//

#import "SRGViewCountProvider.h"
#import "SRGMediaPlayerView.h"
#import "SRGMediaPlayerViewDelegate.h"
#import "SRGRequestsManager.h"

@interface SRGViewCountProvider () {
    BOOL isReadyToPlay;
}
@end

@implementation SRGViewCountProvider

+ (instancetype)sharedProvider
{
    static SRGViewCountProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        isReadyToPlay = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendViewCount:)
                                                     name:SRGMediaPlayerStatusDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Allows more easily to mock for unit tests.
- (SRGRequestsManager *)requestsManagerInstance
{
    return [SRGRequestsManager ILRequestManager];
}

- (void)sendViewCount:(NSNotification *)notification
{
    SRGMediaPlayerStatus status = [[[notification userInfo] objectForKey:SRGMediaPlayerStatusKey] unsignedIntegerValue];
    
    if (status == SRGMediaPlayerStatusReadyToPlay) {
        isReadyToPlay = YES;
    }
    
    if (isReadyToPlay && status == SRGMediaPlayerStatusPlay) {
        isReadyToPlay = NO;
        
        SRGMediaPlayerView *playerView = [notification object];
        NSAssert(playerView.dataSource, @"Missing player dataSource");
        
        NSString *identifier = [playerView.dataSource identifier];
        NSAssert(identifier, @"Missing player dataSource identifier");
        
        NSString *typeName = nil;
        switch (playerView.dataSource.mediaType) {
            case SRGMediaTypeAudio:
                typeName = @"audio";
                break;
            case SRGMediaTypeVideo:
                typeName = @"video";
                break;
            default:
                NSAssert(false, @"Invalid media type: %d %@ %@",
                        (int)playerView.dataSource.mediaType, playerView, playerView.dataSource);
        }

        if (identifier && typeName) { 
            SRGRequestsManager *manager = [self requestsManagerInstance];
            [manager sendViewCountUpdate:identifier forMediaTypeName:typeName];
        }
    }
}

@end
