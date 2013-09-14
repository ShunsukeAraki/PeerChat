//
//  ChatViewController.m
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/11.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatClient.h"

@interface ChatCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *oNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *oDateLabel;
@property (weak, nonatomic) IBOutlet UITextView *oMessageTextView;
@end

@implementation ChatCell
@end

@interface ChatViewController ()
<UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
ChatClientDelegate>
@property (weak, nonatomic) IBOutlet UITextField *oSendMessageTextField;

@end

@implementation ChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.client.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.client = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ChatClientDelegate
- (void)chatClientDidReceiveMessage:(ChatClient *)client {
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.client.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ChatCell";
	
	ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	Message *mes = self.client.messages[indexPath.row];
	cell.oNameLabel.text = mes.sender;
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateFormat = @"HH:mm:ss";
	df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"US"];
	NSString *dateStr = [df stringFromDate:mes.date];
	cell.oDateLabel.text = dateStr;
	cell.oMessageTextView.text = mes.message;
	return cell;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self sendAction:nil];
	return YES;
}

#pragma mark - Actions
- (IBAction)sendAction:(id)sender {
	if (self.oSendMessageTextField.text.length) {
		[self.client sendMessage:self.oSendMessageTextField.text];
	}
	self.oSendMessageTextField.text = @"";
	[self.oSendMessageTextField resignFirstResponder];
}

@end
