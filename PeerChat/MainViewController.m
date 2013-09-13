//
//  MainViewController.m
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/11.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import "MainViewController.h"
#import "ChatViewController.h"
#import "ChatClient.h"

@interface MainViewController ()
<UITextFieldDelegate,
UIAlertViewDelegate,
ChatClientDelegate>
@property (weak, nonatomic) IBOutlet UITextField *oNickNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *oRoomNameTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oFindActivity;
@property (nonatomic) UIBarButtonItem *doneButton;

@property (nonatomic) ChatClient *client;
@property (nonatomic) NSString *chatRoomName;
@end

@implementation MainViewController

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
	self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																	target:self
																	action:@selector(doneAction)];
	NSString *defaultName = [UIDevice currentDevice].name;
	self.oNickNameTextField.text = defaultName;
	self.oRoomNameTextField.text = [defaultName stringByAppendingString:@"'s Room"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([@"toChat" compare:segue.identifier] == NSOrderedSame) {
		ChatViewController *vc = segue.destinationViewController;
		vc.client = self.client;
		self.client = nil;
		vc.title = self.chatRoomName;
	}
}

#pragma mark - Actions
- (IBAction)findNearRoomAction:(id)sender {
	self.client = [[ChatClient alloc] initWithDisplayName:self.oNickNameTextField.text];
	self.client.delegate = self;
	if (!self.client) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"NickName too long or empty."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[self.oNickNameTextField becomeFirstResponder];
		return;
	}
	[self.client startRoomSearch];
	self.oFindActivity.hidden = NO;
}

- (IBAction)createRoomAction:(id)sender {
	self.client = [[ChatClient alloc] initWithDisplayName:self.oNickNameTextField.text];
	self.client.delegate = self;
	if (!self.client) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"NickName too long or empty."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[self.oNickNameTextField becomeFirstResponder];
		return;
	}
	self.chatRoomName = self.oRoomNameTextField.text;
	[self.client createRoom:self.chatRoomName];
	[self performSegueWithIdentifier:@"toChat" sender:self];
}

- (void)doneAction {
	[self.oNickNameTextField resignFirstResponder];
	[self.oRoomNameTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.navigationItem.rightBarButtonItem = self.doneButton;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - ChatClientDelegate
- (void)chatClient:(ChatClient *)client didFindRoom:(NSString *)roomName {
	self.chatRoomName = roomName;
	NSString *message = [NSString stringWithFormat:@"Join to \"%@\"?", roomName];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Found Room"
													message:message
												   delegate:self
										  cancelButtonTitle:@"NO"
										  otherButtonTitles:@"YES", nil];
	[alert show];
	self.oFindActivity.hidden = YES;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self.client joinRoom];
		[self performSegueWithIdentifier:@"toChat" sender:self];
	}
}
@end
