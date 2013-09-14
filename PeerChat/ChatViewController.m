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
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
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

- (void)didMoveToParentViewController:(UIViewController *)parent {
	if (!parent) {
		self.client = nil;
	}
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

- (void)chatClient:(ChatClient *)client didReceiveImage:(UIImage *)image {
	[self showImage:image];
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

- (IBAction)sendPhotoAction:(id)sender {
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	[self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissViewControllerAnimated:YES completion:nil];
	UIImage *image = info[UIImagePickerControllerOriginalImage];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"send.png"];
	[UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
	[self showImage:info[UIImagePickerControllerOriginalImage]];
	[self.client sendResourceAtURL:[NSURL fileURLWithPath:path]];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
- (void)showImage:(UIImage *)image {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.frame = self.view.bounds;
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTap:)];
	[imageView addGestureRecognizer:tap];
	imageView.userInteractionEnabled = YES;
	[self.view addSubview:imageView];
}

- (void)imageTap:(UITapGestureRecognizer *)gesture {
	[gesture.view removeFromSuperview];
}

@end
