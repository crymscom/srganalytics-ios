//
//  Created by Samuel Défago on 12/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
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

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>)dataSource
{
    if (self = [super init])
    {
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
    
    [self.segmentsController reloadSegmentsForIdentifier:self.identifier completionHandler:nil];
}

#pragma mark - Actions

- (IBAction) dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
