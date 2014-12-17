//
//  CanvasClient.m
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/19.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CanvasClient.h"

typedef void(^invitationHandlerType)(BOOL accept, MCSession *session);

typedef struct Packet {
	CanvasTouchStatus status;
	CGPoint point;
} Packet;

@interface CanvasClient ()
<MCSessionDelegate,
MCNearbyServiceAdvertiserDelegate,
MCNearbyServiceBrowserDelegate,
NSStreamDelegate>
@property (nonatomic) NSMutableArray *receiceBeziePaths;
@property (nonatomic) MCSession *session;
@property (nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic) MCNearbyServiceBrowser *browser;
@property (copy, nonatomic) invitationHandlerType handler;
@property (nonatomic) NSString *roomName;
@property (nonatomic) NSMutableArray *outputStreams;
@property (nonatomic) NSMutableArray *outputStreamPeers;
@end

@implementation CanvasClient
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
		_receiceBeziePaths = @[].mutableCopy;
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
	self.outputStreams = @[].mutableCopy;
	self.outputStreamPeers = @[].mutableCopy;
}

- (void)joinRoom {
	self.handler(YES, self.session);
	self.outputStreams = @[].mutableCopy;
	self.outputStreamPeers = @[].mutableCopy;
	[self.session.connectedPeers enumerateObjectsUsingBlock:^(MCPeerID *peerID, NSUInteger idx, BOOL *stop) {
		NSError *error;
		NSOutputStream *stream = [self.session startStreamWithName:@"canvas" toPeer:peerID error:&error];
		if (error) {
			NSLog(@"%@", error);
		} else {
			[self.outputStreams addObject:stream];
			[self.outputStreamPeers addObject:peerID];
		}
	}];
}

- (void)canvasTouchBegan:(CGPoint)point {
	[self sendTouchPoint:point status:CanvasTouchStart];
}

- (void)canvasTouchMove:(CGPoint)point {
	[self sendTouchPoint:point status:CanvasTouching];
}

- (void)canvasTouchEnd:(CGPoint)point {
	[self sendTouchPoint:point status:CanvasTouchEnd];
}

#pragma mark - property
- (NSArray *)bezierPaths {
	return [NSArray arrayWithArray:self.receiceBeziePaths];
}

#pragma mark - private
- (void)sendTouchPoint:(CGPoint)point status:(CanvasTouchStatus)status {
	int size = sizeof(Packet);
	Packet packet;
	packet.status = status;
	packet.point = point;
	uint8_t buf[size];
	memcpy(buf, &packet, size);
	for (NSOutputStream *stream in self.outputStreams) {
		[stream write:buf maxLength:size];
	}
}

#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	if (state == MCSessionStateConnected) {
		if (![self.outputStreamPeers containsObject:peerID]) {
			NSError *error;
			NSOutputStream *stream = [self.session startStreamWithName:@"canvas" toPeer:peerID error:&error];
			if (error) {
				NSLog(@"%@", error);
			} else {
				[self.outputStreams addObject:stream];
				[self.outputStreamPeers addObject:peerID];
			}
		}
	} else if (state == MCSessionStateNotConnected) {
		if ([self.outputStreamPeers containsObject:peerID]) {
			NSUInteger index = [self.outputStreamPeers indexOfObject:peerID];
			[self.outputStreams[index] close];
			[self.outputStreams removeObjectAtIndex:index];
			[self.outputStreamPeers removeObjectAtIndex:index];
		}
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
	stream.delegate = self;
	[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(invitationHandlerType)invitationHandler {
	self.roomName = [[NSString alloc] initWithData:context encoding:NSUTF8StringEncoding];
	self.handler = invitationHandler;
	if ([self.delegate respondsToSelector:@selector(canvasClient:didFindRoom:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate canvasClient:self didFindRoom:self.roomName];
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

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	NSInputStream *input = (NSInputStream *)aStream;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		while ([input hasBytesAvailable]) {
			Packet packet;
			int size = sizeof(Packet);
			uint8_t buf[size];
			NSInteger count = [input read:buf maxLength:size];
			if (count == size) {
				memcpy(&packet, buf, size);
				UIBezierPath *path;
				switch (packet.status) {
					case CanvasTouchStart:
						path = [UIBezierPath bezierPath];
						path.lineCapStyle = kCGLineCapRound;
						path.lineWidth = 3.0f;
						[path moveToPoint:packet.point];
						[self.receiceBeziePaths addObject:path];
						break;
					case CanvasTouching:
						path = self.receiceBeziePaths.lastObject;
						[path addLineToPoint:packet.point];
						break;
					case CanvasTouchEnd:
						path = self.receiceBeziePaths.lastObject;
						[path addLineToPoint:packet.point];
						break;
						
					default:
						break;
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					if ([self.delegate respondsToSelector:@selector(canvasClientDidReceiveTouch:)]) {
						[self.delegate canvasClientDidReceiveTouch:self];
					}
				});
			}
		}
	});
}
@end
