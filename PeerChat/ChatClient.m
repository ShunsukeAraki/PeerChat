//
//  ChatClient.m
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/11.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "ChatClient.h"

typedef void(^invitationHandlerType)(BOOL accept, MCSession *session);

@implementation Message
@end

@interface ChatClient()
<MCSessionDelegate,
MCNearbyServiceAdvertiserDelegate,
MCNearbyServiceBrowserDelegate>
@property (nonatomic) NSMutableArray *chatMessages;
@property (nonatomic) MCSession *session;
@property (nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic) MCNearbyServiceBrowser *browser;
@property (copy, nonatomic) invitationHandlerType handler;
@property (nonatomic) NSString *roomName;
@end

@implementation ChatClient
#pragma mark - public
- (instancetype)initWithDisplayName:(NSString *)name {
	self = [super init];
	if (self) {
		if (!name.length || [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 63) {
			return nil;
		}
		MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:name];
		_session = [[MCSession alloc] initWithPeer:peerID];
		_session.delegate = self;
		_advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID
														discoveryInfo:nil
														  serviceType:@"test-chat"];
		_advertiser.delegate = self;
		_browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID
													serviceType:@"test-chat"];
		_browser.delegate = self;
		_chatMessages = @[].mutableCopy;
	}
	return self;
}

- (void)dealloc {
	[self.advertiser stopAdvertisingPeer];
	[self.browser stopBrowsingForPeers];
	[self.session disconnect];
}

- (void)startRoomSearch {
	[self.advertiser startAdvertisingPeer];
}

- (void)stopRoomSearch {
	[self.advertiser stopAdvertisingPeer];
}

- (void)createRoom:(NSString *)name {
	self.roomName = name;
	[self.browser startBrowsingForPeers];
}

- (void)joinRoom {
	self.handler(YES, self.session);
}

- (void)sendMessage:(NSString *)message {
	NSError *error;
	BOOL result = [self.session sendData:[message dataUsingEncoding:NSUTF8StringEncoding]
								 toPeers:self.session.connectedPeers
								withMode:MCSessionSendDataUnreliable
								   error:&error];
	if (!result || error) {
		NSLog(@"%@", error);
	} else {
		[self addMessage:message fromPeerID:self.session.myPeerID];
	}
}

#pragma mark - property
- (NSArray *)messages {
	return [NSArray arrayWithArray:self.chatMessages];
}

#pragma mark - private
- (void)addMessage:(NSString *)message fromPeerID:(MCPeerID *)peerID {
	Message *messageObj = [[Message alloc] init];
	messageObj.sender = peerID.displayName;
	messageObj.date = [NSDate date];
	messageObj.message = message;
	[self.chatMessages insertObject:messageObj atIndex:0];
	if ([self.delegate respondsToSelector:@selector(chatClientDidReceiveMessage:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate chatClientDidReceiveMessage:self];
		});
	}
}

#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	if (state == MCSessionStateConnected) {
		[self addMessage:@"connected." fromPeerID:peerID];
	} else if (state == MCSessionStateNotConnected) {
		[self addMessage:@"disconnected." fromPeerID:peerID];
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
	NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[self addMessage:message fromPeerID:peerID];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(invitationHandlerType)invitationHandler {
	self.roomName = [[NSString alloc] initWithData:context encoding:NSUTF8StringEncoding];
	self.handler = invitationHandler;
	if ([self.delegate respondsToSelector:@selector(chatClient:didFindRoom:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate chatClient:self didFindRoom:self.roomName];
		});
	}
	[self stopRoomSearch];
}

#pragma mark - MCNearbyServiceBrowserDelegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
	NSData *context = [self.roomName dataUsingEncoding:NSUTF8StringEncoding];
	[browser invitePeer:peerID toSession:self.session withContext:context timeout:0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
}
@end
