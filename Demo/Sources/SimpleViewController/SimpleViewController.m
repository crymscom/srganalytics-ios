//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimpleViewController.h"

@interface SimpleViewController ()

@property (nonatomic) NSArray<NSString *> *levels;
@property (nonatomic) NSDictionary<NSString *, NSString *> *customLabels;
@property (nonatomic, getter=isOpenedFromPushNotification) BOOL openedFromPushNotification;
@property (nonatomic, getter=isTrackedAutomatically) BOOL trackedAutomatically;

@end

@implementation SimpleViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title levels:(NSArray<NSString *> *)levels customLabels:(NSDictionary<NSString *,NSString *> *)customLabels openedFromPushNotification:(BOOL)openedFromPushNotification trackedAutomatically:(BOOL)trackedAutomatically
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    SimpleViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.title = title;
    viewController.levels = levels;
    viewController.customLabels = customLabels;
    viewController.openedFromPushNotification = openedFromPushNotification;
    viewController.trackedAutomatically = trackedAutomatically;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(dismiss:)];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (BOOL)srg_isTrackedAutomatically
{
    return self.trackedAutomatically;
}

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

- (NSArray *)srg_pageViewLevels
{
    return self.levels;
}

- (NSDictionary *)srg_pageViewCustomLabels
{
    return self.customLabels;
}

#pragma mark Actions

- (IBAction)trackPageView:(id)sender
{
    [self srg_trackPageView];
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
