//
//  ChatViewController.h
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/11.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatClient;
@interface ChatViewController : UITableViewController
@property (nonatomic) ChatClient *client;
@end
