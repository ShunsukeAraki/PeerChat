//
//  ChatClient.h
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/11.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatClient;
@protocol ChatClientDelegate <NSObject>
@optional
- (void)chatClientDidReceiveMessage:(ChatClient *)client;
- (void)chatClient:(ChatClient *)client didFindRoom:(NSString *)roomName;
@end

@interface Message : NSObject
@property (nonatomic) NSString *sender;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *message;
@end

@interface ChatClient : NSObject
@property (weak, nonatomic) id<ChatClientDelegate> delegate;
@property (nonatomic, readonly) NSArray *messages;
- (instancetype)initWithDisplayName:(NSString *)name;
- (void)startRoomSearch;
- (void)stopRoomSearch;
- (void)createRoom:(NSString *)name;
- (void)joinRoom;
- (void)sendMessage:(NSString *)message;
@end
