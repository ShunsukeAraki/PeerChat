//
//  TouchDrawView.m
//  PeerChat
//
//  Created by Shunsuke Araki on 2013/09/14.
//  Copyright (c) 2013年 individual. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TouchDrawView.h"
#import "CanvasClient.h"

@interface TouchDrawView()
@property (nonatomic) UIBezierPath *bezierPath;
@property (nonatomic) UIImage *lastDrawImage;
@property (nonatomic) CALayer *imageLayer;
@end

@implementation TouchDrawView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.imageLayer = [CALayer layer];
		self.imageLayer.frame = self.bounds;
		[self.layer addSublayer:self.imageLayer];
	}
	return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
	[self.bezierPath stroke];
	[self.client.bezierPaths enumerateObjectsUsingBlock:^(UIBezierPath *path, NSUInteger idx, BOOL *stop) {
		[path stroke];
	}];
}

#pragma mark -
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint currentPoint = [[touches anyObject] locationInView:self];
	
	[self.client canvasTouchBegan:currentPoint];
	UIBezierPath *path = [UIBezierPath bezierPath];
	path.lineCapStyle = kCGLineCapRound;
	path.lineWidth = 3.0f;
	[path moveToPoint:currentPoint];
	self.bezierPath = path;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint currentPoint = [[touches anyObject] locationInView:self];
	if (!self.bezierPath) {
		return;
	}
	
	[self.client canvasTouchMove:currentPoint];
	[self.bezierPath addLineToPoint:currentPoint];
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint currentPoint = [[touches anyObject] locationInView:self];
	
	[self.client canvasTouchEnd:currentPoint];
	[self.bezierPath addLineToPoint:currentPoint];
	[self setNeedsDisplay];

	// save image
	UIGraphicsBeginImageContext(self.bounds.size);
	[self.lastDrawImage drawAtPoint:CGPointZero];
	[self.bezierPath stroke];
	self.lastDrawImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	self.imageLayer.contents = (__bridge id)(self.lastDrawImage.CGImage);
}
@end
