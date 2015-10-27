//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SegmentsMediaPlayerViewController.h"

@interface SegmentsMediaPlayerViewController ()

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, strong) IBOutlet RTSMediaSegmentsController *segmentsController;

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource> dataSource;

@end

@implementation SegmentsMediaPlayerViewController

#pragma mark - Object lifecycle

- (instancetype)initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>)dataSource
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.mediaPlayerController.dataSource = self.dataSource;
    self.segmentsController.dataSource = self.dataSource;
    
    [self.mediaPlayerController attachPlayerToView:self.view];
    [self.mediaPlayerController playIdentifier:self.identifier];
    
    self.mediaPlayerController.overlayViewsHidingDelay = 1000.;
    
    [self.segmentsController reloadSegmentsForIdentifier:self.identifier completionHandler:nil];
}

#pragma mark - Actions

- (IBAction) playFirstSegment:(id)sender
{
    id<RTSMediaSegment> segment = self.segmentsController.visibleSegments.firstObject;
    [self.segmentsController playSegment:segment];
}

- (IBAction) playSecondSegment:(id)sender
{
    NSAssert(self.segmentsController.visibleSegments.count > 1, @"Expect two visible segments at least");
    id<RTSMediaSegment> segment = [self.segmentsController.visibleSegments objectAtIndex:1];
    [self.segmentsController playSegment:segment];
}

- (IBAction) dismiss:(id)sender
{
    [self.mediaPlayerController reset];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
