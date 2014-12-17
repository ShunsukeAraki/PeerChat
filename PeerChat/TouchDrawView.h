//
//  TouchDrawView.h
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/14.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CanvasClient;
@interface TouchDrawView : UIView
@property (nonatomic) CanvasClient *client;
@end
