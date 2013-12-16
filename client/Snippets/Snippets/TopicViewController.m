//
//  RedisViewController.m
//  Snippets
//
//  Created by Cédric Deltheil on 17/11/13.
//  Copyright (c) 2013 Snippets. All rights reserved.
//

#import "TopicViewController.h"
#import "CommandViewController.h"
#import "ConsoleViewController.h"

#import <Winch/Winch.h>

#import "WNCDatabase+Snippets.h"
#import "UITableView+Snippets.h"

#import "Topic.h"
#import "Group.h"
#import "GroupCell.h"
#import "Command.h"
#import "CommandCell.h"

#define GROUP_CELL_WIDTH 90

@interface TopicViewController ()

// UI properties
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *groupPickerView;
@property (nonatomic, weak) IBOutlet UITableView *commandsTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;

// Private properties
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) Group *currentGroup;

@property (nonatomic) double lastScrollPosX;

@end

@implementation TopicViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // enable interactive pop gesture
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    // transform pickerView to be horizontal
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-3.14 / 2);
    rotate = CGAffineTransformScale(rotate, 0.25, 2.0);
    [self.groupPickerView setTransform:rotate];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"commandViewSegue"]) {
        UITableViewCell *cell = (UITableViewCell *) sender;
        
        NSIndexPath *indexPath = [self.commandsTableView indexPathForCell:cell];
        
        Command *cmd = self.commands[indexPath.row];

        NSString *htmlDoc = [_database sn_getHTMLForCommand:cmd forTopic:_topic.uid];

        CommandViewController *cmdVC = segue.destinationViewController;
        cmdVC.command = cmd;
        cmdVC.htmlDoc = htmlDoc;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component;
{
    return [self.groups count];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 44;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentGroup = [self.groups objectAtIndex:row];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    Group *group = [self.groups objectAtIndex:row];
    
    // reusing view
    UILabel *label = (UILabel *) view;
   
    if (!label) {
        label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 180, 80)];
        
        // customize title label
        [label setFont:[UIFont fontWithName:@"VAGRoundedStd-Light" size:26]];
        [label setTextAlignment:NSTextAlignmentCenter];
        
        // transform label to be horizontal
        CGAffineTransform rotate = CGAffineTransformMakeRotation(3.14 / 2);
        rotate = CGAffineTransformScale(rotate, 0.25, 2.0);
        [label setTransform:rotate];
    }

    [label setText:group.name];
    
    return label;
}

#pragma mark - Private

- (void)setTopic:(Topic *)topic
{
    _topic = topic;
    
    [self.titleLabel setText:_topic.name];
    [self.backButton setTitle:_topic.name];
}

- (NSArray *)groups
{
    if (_groups) {
        return _groups;
    }
    
    _groups = [_database sn_fetchGroupsForTopic:_topic.uid error:nil];
    
    return _groups;
}

- (NSArray *)commands
{
    if (_commands) {
        return _commands;
    }
    
    NSMutableArray *cmds = [NSMutableArray arrayWithArray:[_database sn_fetchCommandsForTopic:_topic.uid error:nil]];
    
    if (_currentGroup) {
        [cmds filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *_) {
            Command *cmd = (Command *) obj;
            return [_currentGroup.cmds containsObject:cmd.uid];
        }]];
    }
    
    _commands = [NSArray arrayWithArray:cmds];
    
    return _commands;
}

- (void)setCurrentGroup:(Group *)currentGroup
{
    NSString *prev = _currentGroup ? _currentGroup.name : @"<void>";
    NSString *next = currentGroup ? currentGroup.name : @"<void>";
    
    if ([prev isEqualToString:next]) {
        return;
    }
    
    _currentGroup = currentGroup;
    
    self.commands = nil;
    
    [self.commandsTableView reloadData];
    
    // table view popup animation
    [self.commandsTableView popUpVisibleCells];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.commands count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"topicCommandCellID";
    
    CommandCell *cell = (CommandCell *) [_commandsTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[CommandCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:cellIdentifier];
    }
    
    Command *cmd = self.commands[indexPath.row];
    cell.command = cmd;
    
    return cell;
}

@end
