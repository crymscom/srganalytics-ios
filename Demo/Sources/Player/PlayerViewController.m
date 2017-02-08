//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayerViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface PlayerViewController ()

@property (nonatomic) NSURL *URL;

@property (nonatomic, weak) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@end

@implementation PlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURL:(NSURL *)URL
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    PlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.URL = URL;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(close:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        [self.mediaPlayerController playURL:self.URL];
    }
}

#pragma mark Actions

- (void)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
