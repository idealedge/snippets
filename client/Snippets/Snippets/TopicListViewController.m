//
//  ThemeTableViewController.m
//  Snippets
//
//  Created by James Heng on 10/12/13.
//  Copyright (c) 2013 Snippets. All rights reserved.
//

#import "TopicListViewController.h"
#import "TopicViewController.h"

#import "WNCDatabase+Snippets.h"
#import "UIColor+Snippets.h"

#import "Topic.h"

#import "TopicCell.h"

#define CELL_IDENTIFIER @"TopicCellID"

@interface TopicListViewController ()

@property (strong, nonatomic) NSArray *topics;
@property (nonatomic) NSIndexPath *selectedTopic;

@end

@implementation TopicListViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // temporary setter for demo "redis"
    Topic *rds = [[Topic alloc] init];
    rds.uid = @"rds";
    rds.name = @"Redis";
    rds.description = @"Redis is an open source, BSD licensed, advanced key-value store.";
    
    _topics = @[rds];
    
    // set an empty table view footer
    [self.tableView setTableFooterView:[UIView new]];

    // interactivePopGesture view controller
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>) self;

    // disable interactive pop gesture
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    // set tint color to navigationBar
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:@"#f16353" alpha:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions

- (IBAction)chooseTopic:(id)sender
{
    UIButton *button = (UIButton *) sender;
    
    TopicCell *cell = nil;
    
    // Getting tableViewCell from button
    for (id view = [button superview]; view != nil; view = [view superview]) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            cell = (TopicCell *) view;
            break;
        }
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    Topic *topic = _topics[indexPath.row];
    
    // set percent to 0 on choosen topic
    [cell setPercent:0];
    
    // cold start check
    if ([_database sn_countCommandsForTopicForTopic:topic.uid] > 0) {
        [self presentViewControllerForTopic:topic];
        
        // sync in background
        [self syncTopic:topic.uid resultBlock:nil progressBlock:nil];

        return;
    }
    
    void (^resultBlock)(NSError *) = ^(NSError *error) {
        [self.tableView setUserInteractionEnabled:YES];
        if (error) {
            // keep selected topic to use for retry action
            _selectedTopic = indexPath;
            // restore cell default title (= SYNC)
            [cell reset];
            // show alert view to handle retry action
            [self showAlertSyncError:error];
        }
        else {
            [self presentViewControllerForTopic:topic];
        }
    };
    
    void (^progressBlock)(NSInteger percentDone) = ^(NSInteger percentDone) {
        [cell setPercent:percentDone];
    };

    // sync on cold start with error view
    [self syncTopic:topic.uid resultBlock:resultBlock progressBlock:progressBlock];

    // disable user interaction on sync
    [self.tableView setUserInteractionEnabled:NO];
}

#pragma mark - Private

- (void)syncTopic:(NSString *)uid
      resultBlock:(void (^)(NSError *error))resultBlock
    progressBlock:(void (^)(NSInteger percentDone))progressBlock
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    void (^postSyncBlock)(NSArray *, NSError *) = ^(id _, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (resultBlock) {
            resultBlock(error);
        }
    };
    
    [_database sn_syncForTopic:uid
                   resultBlock:postSyncBlock
                 progressBlock:progressBlock
                         error:nil];
}

- (void)showAlertSyncError:(NSError *)error
{
    NSString *message;
    
    switch ([error code]) {
        case WNCErrorNoConn:
            message = @"The initial synchronization failed.\nPlease check your Internet connection.";
            break;
        case WNCErrorSlowConn:
        case WNCErrorTimeout:
            message = @"The initial synchronization failed.\nYour Internet connection is too slow.";
            break;
        default:
            message = @"The initial synchronization failed.\nPlease try again.";
            break;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:message
                               delegate:self
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@"Retry", nil] show];
}

- (void)presentViewControllerForTopic:(Topic *)topic
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TopicViewController  *topicVC = [storyboard instantiateViewControllerWithIdentifier:@"TopicViewController"];
    topicVC.topic = topic;
    topicVC.database = _database;
    
    [self.navigationController pushViewController:topicVC animated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopicCell *cell = (TopicCell *) [tableView cellForRowAtIndexPath:indexPath];
    if (!cell.isSynced) {
        return;
    }
    
    // call choose topic IBAction with the current selected cell
    [self chooseTopic:cell.chooseButton];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_topics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopicCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    Topic *topic = _topics[indexPath.row];
    
    cell.topic = topic;
    
    // if topic synced, show accessory button
    if ([_database sn_countCommandsForTopicForTopic:topic.uid] > 0) {
        cell.isSynced = YES;
    }
    
    return cell;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        return;
    }
    
    // Retry button
    TopicCell *cell = (TopicCell *) [self.tableView cellForRowAtIndexPath:_selectedTopic];
    
    // call choose topic IBAction with the current selected cell
    [self chooseTopic:cell.chooseButton];
}

@end
