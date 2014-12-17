//
//  CanvasClient.h
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/19.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CanvasClient;
@protocol CanvasClientDelegate <NSObject>
@optional
- (void)canvasClientDidReceiveTouch:(CanvasClient *)client;
- (void)canvasClient:(CanvasClient *)client didFindRoom:(NSString *)roomName;
@end

typedef NS_ENUM(NSInteger, CanvasTouchStatus) {
	CanvasTouchStart = 0,
	CanvasTouching,
	CanvasTouchEnd
};

@interface CanvasTouch : NSObject
@property (nonatomic) NSString *sender;
@property (nonatomic) CanvasTouchStatus status;
@property (nonatomic) CGPoint point;
@end

@interface CanvasClient : NSObject
@property (weak, nonatomic) id<CanvasClientDelegate> delegate;
@property (nonatomic, readonly) NSArray *bezierPaths;
- (instancetype)initWithDisplayName:(NSString *)name;
- (void)startRoomSearch;
- (void)stopRoomSearch;
- (void)createRoom:(NSString *)name;
- (void)joinRoom;
- (void)canvasTouchBegan:(CGPoint)point;
- (void)canvasTouchMove:(CGPoint)point;
- (void)canvasTouchEnd:(CGPoint)point;
@end
