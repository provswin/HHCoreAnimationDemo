//
//  HHCoreAnimationContentViewController.m
//  HHCoreAnimationDemo
//
//  Created by 深圳市秀软科技有限公司 on 07/02/2018.
//  Copyright © 2018 showsoft. All rights reserved.
//

#import "HHCoreAnimationContentViewController.h"
#import <GLKit/GLKit.h>
#import <CoreText/CoreText.h>
#import <AVFoundation/AVFoundation.h>

//导航栏高度
#define NAVIGATIONBARHEIGHT (STATUSBARHEIGHT + 44)
//状态栏高度
#define STATUSBARHEIGHT [UIApplication sharedApplication].statusBarFrame.size.height

#define LIGHT_DIRECTION 0, 1, -0.5
#define AMBIENT_LIGHT 0.5

@interface HHCoreAnimationContentViewController () <CALayerDelegate, CAAnimationDelegate>
/*
 该ViewController为本Demo所有演示页面所共用,因此以下属性可能在不同的页面有很多是不需要的。
 代码较为冗长,基本阅读思路为：
 viewDidLoad -> layoutSubLayer -> [找到name所对应code section] -> viewDidUnload -> dealloc
 */
@property (nonatomic, strong) UIView *matrixContainerView;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *cubeFaces;
@property (nonatomic, strong) UILabel *tips;

@property (nonatomic, strong) CALayer *gravityLayer;
@property (nonatomic, strong) CALayer *gravityContainerLayer;

@property (nonatomic, strong) CALayer *customDrawingLayer;

@property (nonatomic, strong) CALayer *hitTestBlueLayer;
@property (nonatomic, strong) CALayer *hitTestRedLayer;

@property (nonatomic, strong) CAScrollLayer *scrollLayer;
@property (nonatomic, strong) CATiledLayer *tiledLayer;

@property (nonatomic, strong) UIView *glView;
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) CAEAGLLayer *glLayer;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLint framebufferWidth;
@property (nonatomic, assign) GLint framebufferHeight;
@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, strong) CALayer *transactionLayer;
@property (nonatomic, strong) CALayer *globalLayer;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) IBOutlet UISlider *timeOffsetSlider;
@property (nonatomic, strong) IBOutlet UISlider *speedSlider;
@property (nonatomic, strong) IBOutlet UIView *relativeTimeControlContainerView;
@property (nonatomic, strong) IBOutlet UILabel *timeOffsetLabel;
@property (nonatomic, strong) IBOutlet UILabel *speedLabel;
@property (nonatomic, strong) CAShapeLayer *shipLayer;
@property (nonatomic, strong) UIBezierPath *bezierPath;
@property (nonatomic, strong) CALayer *doorLayer;
@property (nonatomic, strong) UILabel *timimgFunctionLabel;
@property (nonatomic, strong) CALayer *timingFunctionLayer;
@property (nonatomic, strong) CAKeyframeAnimation *timingFunctionKeyframeAnimation;
@property (nonatomic, strong) CABasicAnimation *timingFunctionBasicAnimation;
@property (nonatomic, strong) UILabel *animationOptionLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval timeOffset;
@property (nonatomic, strong) id fromValue;
@property (nonatomic, strong) id toValue;
@property (nonatomic, strong) UIImageView *ball;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastStep;
@end

@implementation HHCoreAnimationContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = _name;
    
    [self layoutSubLayer];
}

- (void)viewDidUnload {
    [self tearDownBuffers];
    [super viewDidUnload];
}

- (void)dealloc {
    _customDrawingLayer.delegate = nil;
    _tiledLayer.delegate = nil;
    
    [self tearDownBuffers];
    [EAGLContext setCurrentContext:nil];
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)layoutSubLayer {
    CGPoint center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    CGFloat layerWidth = [UIScreen mainScreen].bounds.size.width / 2;
    CGFloat layerHeight = [UIScreen mainScreen].bounds.size.width / 2;
    
    if ([_name isEqualToString:@"阴影"]) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.backgroundColor = [UIColor blueColor].CGColor;
        
        // 设置阴影颜色(默认值为黑色)
        layer.shadowColor = [UIColor redColor].CGColor;
        
        // 设置阴影透明度(默认值为0)
        layer.shadowOpacity = 1.0f;
        
        // 设阴影的方向和距离(默认值为(0, -3))
        // 1.设置为(0,0)时，layer的四周都会有一层很稀薄的阴影
        // 2.如果设置height为正数,layer的底部阴影会更多一些
        // 3.与Mac OS的方向相反
        layer.shadowOffset = CGSizeMake(0, 0);
        
        layer.position = center;
        
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"圆角"]) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.backgroundColor = [UIColor blueColor].CGColor;
        layer.cornerRadius = 5.f;
        layer.position = center;
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"边框"]) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.backgroundColor = [UIColor blueColor].CGColor;
        
        // 设置边框颜色(默认值为黑色)
        layer.borderColor = [UIColor redColor].CGColor;
        
        // 设置边框宽度(默认值为0)
        layer.borderWidth = 5.f;
        layer.position = center;
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"3D变换"]) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.backgroundColor = [UIColor blueColor].CGColor;
        layer.position = center;
        
        // 围绕Z旋转45°
        CATransform3D transform = CATransform3DMakeRotation(M_PI_4, 0, 0, 1);
        
        layer.transform = transform;
        
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"非矩形范围"] || [_name isEqualToString:@"CAShapeLayer"]) {
        UIBezierPath *bezier = [[UIBezierPath alloc] init];
        
        CGFloat centerX = [UIScreen mainScreen].bounds.size.width / 2;
        CGFloat centerY = [UIScreen mainScreen].bounds.size.height / 2;
        
        // 以下为绘制一个五角星的路径
        // moveToPoint：表达addLineToPoint所对应的参考点
        // addLineToPoint：以上一次结束绘制的点作为起点，以addLineToPoint所指向的点作为参考点绘制线条
        [bezier moveToPoint:CGPointMake(centerX, centerY)];
        
        [bezier addLineToPoint:CGPointMake(centerX - 50, centerY - 25)];
        
        [bezier addLineToPoint:CGPointMake(centerX + 50, centerY - 25)];
        
        [bezier addLineToPoint:CGPointMake(centerX - 50, centerY + 25)];
        
        [bezier addLineToPoint:CGPointMake(centerX, centerY - 50)];
        
        [bezier addLineToPoint:CGPointMake(centerX + 50, centerY + 25)];
        
        [bezier addLineToPoint:CGPointMake(centerX, centerY)];
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        
        // 线条宽度（默认是10.f）
        layer.lineWidth = 5.f;
        
        // 线条颜色（默认是nil）
        layer.strokeColor = [UIColor redColor].CGColor;
        
        // 路径之间的填充色（默认是黑色）
        layer.fillColor = [UIColor blueColor].CGColor;
        
        // 两个线条之间的连接形式：默认是Miter斜接(相接处为尖角);
        // 另外的选项含义：Bevel为斜面，Round为圆角
        layer.lineJoin = kCALineJoinRound;
        
        layer.path = bezier.CGPath;
        
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"透明遮罩"]) {
        CALayer *layerTop = [CALayer layer];
        layerTop.frame = CGRectMake(0, 0, 120, 120);
        layerTop.backgroundColor = [UIColor blueColor].CGColor;
        layerTop.position = CGPointMake(center.x, center.y - 160);
        
        CALayer *layerMiddle = [CALayer layer];
        layerMiddle.frame = layerTop.bounds;
        layerMiddle.contents = (__bridge id _Nullable)([UIImage imageNamed:@"bottle.png"].CGImage);
        layerMiddle.contentsGravity = kCAGravityResizeAspectFill;
        layerMiddle.position = center;
        
        CALayer *layerBottom = [CALayer layer];
        layerBottom.frame = CGRectMake(0, 0, 120, 120);
        layerBottom.backgroundColor = [UIColor blueColor].CGColor;
        layerBottom.position = CGPointMake(center.x, center.y + 160);
        
        CALayer *mask = [CALayer layer];
        mask.frame = layerBottom.bounds;
        mask.contents = (__bridge id _Nullable)([UIImage imageNamed:@"bottle.png"].CGImage);
        mask.contentsGravity = kCAGravityResizeAspectFill;
        layerBottom.mask = mask;
        
        [self.view.layer addSublayer:layerTop];
        [self.view.layer addSublayer:layerMiddle];
        [self.view.layer addSublayer:layerBottom];
    } else if ([_name isEqualToString:@"拉伸过滤"]) {
        CGFloat filterLayerWidth = ([UIScreen mainScreen].bounds.size.width- (10 * 4)) / 3 ;
        CGFloat filterLayerHeight= filterLayerWidth;
        
        // Nearest
        // Original1
        CALayer *original1 = [CALayer layer];
        original1.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        original1.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        original1.contentsScale = [UIScreen mainScreen].scale;
        original1.position = CGPointMake(10 + filterLayerWidth / 2, 104 + filterLayerHeight / 2);
        [self.view.layer addSublayer:original1];
        
        CALayer *nearest = [CALayer layer];
        nearest.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        nearest.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        nearest.position = CGPointMake((10 * 3)  + (filterLayerWidth * 2) + (filterLayerWidth / 2), 104 + filterLayerHeight / 2);
        nearest.magnificationFilter = kCAFilterNearest;
        nearest.contentsScale = [UIScreen mainScreen].scale;
        [self.view.layer addSublayer:nearest];
        
        UILabel *nearestLabel = [[UILabel alloc] init];
        nearestLabel.text = @"kCAFilterNearest";
        nearestLabel.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        nearestLabel.center = CGPointMake((10 * 2)  + (filterLayerWidth * 1) + (filterLayerWidth / 2), 104 + filterLayerHeight / 2);
        nearestLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        nearestLabel.font = [UIFont systemFontOfSize:13];
        nearestLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:nearestLabel];
        
        // Linear
        // Original2
        CALayer *original2 = [CALayer layer];
        original2.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        original2.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        original2.contentsScale = [UIScreen mainScreen].scale;
        original2.position = CGPointMake(10 + filterLayerWidth / 2, 104 + filterLayerHeight + 30 + filterLayerHeight / 2);
        [self.view.layer addSublayer:original2];
        
        CALayer *linear = [CALayer layer];
        linear.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        linear.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        linear.position = CGPointMake((10 * 3)  + (filterLayerWidth * 2) + (filterLayerWidth / 2), 104 + filterLayerHeight + 30 + filterLayerHeight / 2);
        linear.magnificationFilter = kCAFilterLinear;
        linear.contentsScale = [UIScreen mainScreen].scale;
        [self.view.layer addSublayer:linear];
        
        UILabel *linearLabel = [[UILabel alloc] init];
        linearLabel.text = @"kCAFilterLinear";
        linearLabel.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        linearLabel.center = CGPointMake((10 * 2)  + (filterLayerWidth * 1) + (filterLayerWidth / 2), 104 + filterLayerHeight + 30 + filterLayerHeight / 2);
        linearLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        linearLabel.font = [UIFont systemFontOfSize:13];
        linearLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:linearLabel];
        
        // Trilinear
        // Original3
        CALayer *Original3 = [CALayer layer];
        Original3.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        Original3.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        Original3.contentsScale = [UIScreen mainScreen].scale;
        Original3.position = CGPointMake(10 + filterLayerWidth / 2, 104 + filterLayerHeight * 2 + 30 * 2 + filterLayerHeight / 2);
        [self.view.layer addSublayer:Original3];
        
        CALayer *trilinear = [CALayer layer];
        trilinear.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        trilinear.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        trilinear.position = CGPointMake((10 * 3)  + (filterLayerWidth * 2) + (filterLayerWidth / 2), 104 + filterLayerHeight * 2 + 30 * 2 + filterLayerHeight / 2);
        trilinear.magnificationFilter = kCAFilterTrilinear;
        trilinear.contentsScale = [UIScreen mainScreen].scale;
        [self.view.layer addSublayer:trilinear];
        
        UILabel *trilinearLabel = [[UILabel alloc] init];
        trilinearLabel.text = @"kCAFilterTrilinear";
        trilinearLabel.frame = CGRectMake(0, 0, filterLayerWidth, filterLayerHeight);
        trilinearLabel.center = CGPointMake((10 * 2)  + (filterLayerWidth * 1) + (filterLayerWidth / 2), 104 + filterLayerHeight * 2 + 30 * 2 + filterLayerHeight / 2);
        trilinearLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        trilinearLabel.font = [UIFont systemFontOfSize:13];
        trilinearLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:trilinearLabel];
    } else if ([_name isEqualToString:@"组透明"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"UIViewGroupOpacity : \n YES:从iOS 7开始该值默认为YES；开启该值之后，组透明功能就会全局启用。 \n NO:iOS6之前，该值默认为NO，如果不想通过修改UIViewGroupOpacity的值实现组透明可以用下面的代码实现。";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
        button.backgroundColor = [UIColor blueColor];
        button.center = center;
        button.layer.cornerRadius = 10.f;
        [self.view addSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 130, 30)];
        label.text = @"你好，世界";
        label.backgroundColor = [UIColor blueColor];
        label.textAlignment = NSTextAlignmentCenter;
        [button addSubview:label];
        
        button.alpha = 0.5;
        // UIViewGroupOpacity为YES时，无须shouldRasterize=YES也可组透明
        button.layer.shouldRasterize = YES;
    } else if ([_name isEqualToString:@"contentGravity"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = [NSString stringWithFormat:@"contentGravity = %@", kCAGravityResize];
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        _gravityContainerLayer = [CALayer layer];
        _gravityContainerLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _gravityContainerLayer.position = center;
        _gravityContainerLayer.backgroundColor = [UIColor blueColor].CGColor;
        [self.view.layer addSublayer:_gravityContainerLayer];
        
        _gravityLayer = [CALayer layer];
        _gravityLayer.contents = (__bridge id)([UIImage imageNamed:@"seven.png"].CGImage);
        // 设置图层对齐方式（默认kCAGravityResize）
        _gravityLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _gravityLayer.contentsGravity = kCAGravityResize;
        [_gravityContainerLayer addSublayer:_gravityLayer];
        
        CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width / 4;
        CGFloat buttonHeight = 36.f;
        NSArray *buttonTextArray = @[@[@"Center", @"Top", @"Bottom", @"Left"], @[@"Right", @"TopLeft", @"TopRight", @"BottomLeft"], @[@"BottomRight", @"Resize", @"ResizeAspect", @"ResizeAspectFill"]];
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 4; j++) {
                UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth * j, [UIScreen mainScreen].bounds.size.height - buttonHeight * (i + 1), buttonWidth, buttonHeight)];
                button.layer.borderColor = [UIColor grayColor].CGColor;
                button.layer.borderWidth = 1.f;
                [button setTitle:[[buttonTextArray objectAtIndex:i] objectAtIndex:j] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                button.backgroundColor = [UIColor whiteColor];
                button.titleLabel.font = [UIFont systemFontOfSize:13.f];
                button.tag = i * 4 + j;
                [button addTarget:self action:@selector(adjustLayerGravity:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:button];
            }
        }
    } else if ([_name isEqualToString:@"contentsScale"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"contentsScale无论是在Retina还是非Retina屏下默认值均为1，所以在Retina屏下会导致1个point只显示1个像素。这样在Retina屏下就会略显粗糙";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        CGFloat layerWidth = ([UIScreen mainScreen].bounds.size.width - 3 * 20) / 2;
        CGFloat layerHeight = layerWidth;
        
        CALayer *leftLayer = [CALayer layer];
        leftLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        leftLayer.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        leftLayer.position = CGPointMake(20 + layerWidth / 2, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        leftLayer.contentsGravity = kCAGravityCenter;
        [self.view.layer addSublayer:leftLayer];
        
        UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, layerWidth, 36)];
        leftLabel.center = CGPointMake(20 + layerWidth / 2, leftLayer.position.y + 18 + 18);
        leftLabel.text = [NSString stringWithFormat:@"contentsScale = %f", leftLayer.contentsScale];
        leftLabel.textAlignment = NSTextAlignmentCenter;
        leftLabel.numberOfLines = 0;
        leftLabel.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:leftLabel];
        
        CALayer *rightLayer = [CALayer layer];
        rightLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        rightLayer.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        rightLayer.position = CGPointMake(20 * 2 + layerWidth / 2 + layerWidth, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        rightLayer.contentsGravity = kCAGravityCenter;
        rightLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.view.layer addSublayer:rightLayer];
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, layerWidth, 36)];
        rightLabel.center = CGPointMake(20 * 2 + layerWidth / 2 + layerWidth, rightLayer.position.y + 18 + 18);
        rightLabel.text = [NSString stringWithFormat:@"contentsScale = %f", rightLayer.contentsScale];
        rightLabel.textAlignment = NSTextAlignmentCenter;
        rightLabel.numberOfLines = 0;
        rightLabel.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:rightLabel];
    } else if ([_name isEqualToString:@"maskToBounds"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"左：masksToBounds为NO，右：masksToBounds为YES";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        CGFloat layerWidth = ([UIScreen mainScreen].bounds.size.width - 3 * 20) / 2;
        CGFloat layerHeight = layerWidth;
        
        CALayer *leftLayer = [CALayer layer];
        leftLayer.backgroundColor = [UIColor blueColor].CGColor;
        leftLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        leftLayer.position = CGPointMake(20 + layerWidth / 2, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        [self.view.layer addSublayer:leftLayer];
        
        CALayer *leftSubLayer = [CALayer layer];
        leftSubLayer.backgroundColor = [UIColor redColor].CGColor;
        leftSubLayer.frame = CGRectMake(0, 0, layerWidth / 2, layerHeight / 2);
        leftSubLayer.position = CGPointMake(layerWidth / 2, layerHeight);
        [leftLayer addSublayer:leftSubLayer];
        
        CALayer *rightLayer = [CALayer layer];
        rightLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        rightLayer.backgroundColor = [UIColor blueColor].CGColor;
        rightLayer.position = CGPointMake(20 * 2 + layerWidth / 2 + layerWidth, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        rightLayer.masksToBounds = YES;
        [self.view.layer addSublayer:rightLayer];
        
        CALayer *rightSubLayer = [CALayer layer];
        rightSubLayer.backgroundColor = [UIColor redColor].CGColor;
        rightSubLayer.frame = CGRectMake(0, 0, layerWidth / 2, layerHeight / 2);
        rightSubLayer.position = CGPointMake(layerWidth / 2, layerHeight);
        [rightLayer addSublayer:rightSubLayer];
    } else if ([_name isEqualToString:@"contentsRect"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"左：contentsRect为(0,0,1,1)，右：contentsRect为(0,0,0.5,0.5)";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        CGFloat layerWidth = ([UIScreen mainScreen].bounds.size.width - 3 * 20) / 2;
        CGFloat layerHeight = layerWidth;
        
        CALayer *leftLayer = [CALayer layer];
        leftLayer.backgroundColor = [UIColor blueColor].CGColor;
        leftLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        leftLayer.position = CGPointMake(20 + layerWidth / 2, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        [self.view.layer addSublayer:leftLayer];
        
        CALayer *leftSubLayer = [CALayer layer];
        leftSubLayer.contents = (__bridge id)([UIImage imageNamed:@"bottle.png"]).CGImage;
        leftSubLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        leftSubLayer.position = CGPointMake(layerWidth / 2, layerHeight / 2);
        [leftLayer addSublayer:leftSubLayer];
        
        CALayer *rightLayer = [CALayer layer];
        rightLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        rightLayer.backgroundColor = [UIColor blueColor].CGColor;
        rightLayer.position = CGPointMake(20 * 2 + layerWidth / 2 + layerWidth, NAVIGATIONBARHEIGHT + 96 + layerHeight / 2);
        [self.view.layer addSublayer:rightLayer];
        
        CALayer *rightSubLayer = [CALayer layer];
        rightSubLayer.contents = (__bridge id)([UIImage imageNamed:@"bottle.png"]).CGImage;
        rightSubLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        rightSubLayer.position = CGPointMake(layerWidth / 2, layerHeight / 2);
        rightSubLayer.contentsRect = CGRectMake(0, 0, 0.5, 0.5);
        [rightLayer addSublayer:rightSubLayer];
    } else if ([_name isEqualToString:@"contentsCenter"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"利用CALayer的contentsCenter能力，通过对UIButton设置不同大小的Frame实现指定区域的拉伸";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        /* 8 is gap */
        CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width / 2;
        UIButton *buttonUp = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - buttonWidth) / 2, NAVIGATIONBARHEIGHT + 96 + 8, buttonWidth, 100)];
        buttonUp.layer.contents = (__bridge id)([UIImage imageNamed:@"red_center.png"]).CGImage;
        buttonUp.layer.contentsCenter = CGRectMake(0.25, 0.25, 0.5, 0.5);
        
        UIButton *buttonDown = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - buttonWidth) / 2, NAVIGATIONBARHEIGHT + 96 + buttonUp.frame.size.height + 16, buttonWidth, 200)];
        buttonDown.layer.contents = (__bridge id)([UIImage imageNamed:@"red_center.png"]).CGImage;
        buttonDown.layer.contentsCenter = CGRectMake(0.25, 0.25, 0.5, 0.5);
        
        [self.view addSubview:buttonUp];
        [self.view addSubview:buttonDown];
    } else if ([_name isEqualToString:@"Custom Drawing"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"通过设置CALayer的delegate，并实现drawLayer: inContext:方法，使得CALayer实现自定义绘制";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        _customDrawingLayer = [CALayer layer];
        _customDrawingLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _customDrawingLayer.backgroundColor = [UIColor blueColor].CGColor;
        
        _customDrawingLayer.position = center;
        
        _customDrawingLayer.delegate = self;
        
        [self.view.layer addSublayer:_customDrawingLayer];
        
        [_customDrawingLayer display];
    } else if ([_name isEqualToString:@"frame、bounds、position"]) {
        layerWidth /= 2;
        layerHeight /= 2;
        CALayer *layerUp = [CALayer layer];
        layerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + 8, layerWidth, layerHeight);
        layerUp.backgroundColor = [UIColor blueColor].CGColor;
        
        [self.view.layer addSublayer:layerUp];
        
        CALayer *layerDown = [CALayer layer];
        layerDown.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + layerUp.bounds.size.height + 64, layerWidth, layerHeight);
        layerDown.backgroundColor = [UIColor blueColor].CGColor;
        
        // 围绕Z旋转45°
        CATransform3D transform = CATransform3DMakeRotation(M_PI_4, 0, 0, 1);
        
        layerDown.transform = transform;
        
        [self.view.layer addSublayer:layerDown];
        
        _tips = [[UILabel alloc] init];
        _tips.text = [NSString stringWithFormat:@"Up: frame = %@ bounds = %@, position = %@ \n\nDown: frame = %@ bounds = %@, position = %@",NSStringFromCGRect(layerUp.frame), NSStringFromCGRect(layerUp.bounds), NSStringFromCGPoint(layerUp.position),NSStringFromCGRect(layerDown.frame), NSStringFromCGRect(layerDown.bounds), NSStringFromCGPoint(layerDown.position)];
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 112);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"anchorPoint锚点"]) {
        CALayer *bgLayerUp = [CALayer layer];
        bgLayerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 96 + 8, layerWidth, layerHeight);
        bgLayerUp.backgroundColor = [UIColor blueColor].CGColor;
        [self.view.layer addSublayer: bgLayerUp];
        
        CALayer *bgLayerDown = [CALayer layer];
        bgLayerDown.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 96 + layerHeight + 16, layerWidth, layerHeight);
        bgLayerDown.backgroundColor = [UIColor blueColor].CGColor;
        [self.view.layer addSublayer: bgLayerDown];
        
        CALayer *subLayerUp = [CALayer layer];
        subLayerUp.frame = CGRectMake(0, 0, bgLayerUp.frame.size.width, bgLayerUp.frame.size.height);
        subLayerUp.backgroundColor = [UIColor redColor].CGColor;
        subLayerUp.anchorPoint = CGPointMake(0.5, 0.5);
        [bgLayerUp addSublayer: subLayerUp];
        
        CALayer *subLayerDown = [CALayer layer];
        subLayerDown.frame = CGRectMake(0, 0, bgLayerUp.frame.size.width, bgLayerUp.frame.size.height);
        subLayerDown.backgroundColor = [UIColor redColor].CGColor;
        subLayerDown.anchorPoint = CGPointMake(0, 0);
        [bgLayerDown addSublayer: subLayerDown];
        
        _tips = [[UILabel alloc] init];
        _tips.text = [NSString stringWithFormat:@"Up: frame = %@ position = %@ anchorPoint = %@ \n\nDown: frame = %@ position = %@ anchorPoint = %@",NSStringFromCGRect(subLayerUp.frame), NSStringFromCGPoint(subLayerUp.position), NSStringFromCGPoint(subLayerUp.anchorPoint), NSStringFromCGRect(subLayerDown.frame), NSStringFromCGPoint(subLayerDown.position), NSStringFromCGPoint(subLayerDown.anchorPoint)];
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"翻转的几何结构（geometryFlipped）"]) {
        CALayer *bgLayerUp = [CALayer layer];
        bgLayerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 96 + 8, layerWidth, layerHeight);
        bgLayerUp.backgroundColor = [UIColor blueColor].CGColor;
        [self.view.layer addSublayer: bgLayerUp];
        
        CALayer *bgLayerDown = [CALayer layer];
        bgLayerDown.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 96 + layerHeight + 16, layerWidth, layerHeight);
        bgLayerDown.backgroundColor = [UIColor blueColor].CGColor;
        bgLayerDown.geometryFlipped = YES;
        [self.view.layer addSublayer: bgLayerDown];
        
        CALayer *subLayerUp = [CALayer layer];
        subLayerUp.frame = CGRectMake(0, 0, 20, 20);
        subLayerUp.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        subLayerUp.magnificationFilter = kCAFilterNearest;
        subLayerUp.contentsScale = [UIScreen mainScreen].scale;
        
        CALayer *subLayerDown = [CALayer layer];
        subLayerDown.frame = CGRectMake(0, 0, 20, 20);
        subLayerDown.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        subLayerDown.magnificationFilter = kCAFilterNearest;
        subLayerDown.contentsScale = [UIScreen mainScreen].scale;
        
        [bgLayerUp addSublayer:subLayerUp];
        [bgLayerDown addSublayer: subLayerDown];
    } else if ([_name isEqualToString:@"Z坐标轴"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"red Layer zPosition = 20.f > green Layer zPosition , 因此red Layer位于Green Layer上方";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        layerWidth /= 2;
        layerHeight /= 2;
        CALayer *bgLayerUp = [CALayer layer];
        bgLayerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 96 + 8, layerWidth, layerHeight);
        bgLayerUp.backgroundColor = [UIColor blueColor].CGColor;
        [self.view.layer addSublayer: bgLayerUp];
        
        CALayer *subLayerUp = [CALayer layer];
        subLayerUp.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        subLayerUp.backgroundColor = [UIColor redColor].CGColor;
        subLayerUp.anchorPoint = CGPointMake(0, 0);
        
        CALayer *subLayerDown = [CALayer layer];
        subLayerDown.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        subLayerDown.backgroundColor = [UIColor greenColor].CGColor;
        subLayerDown.anchorPoint = CGPointMake(0.7, 0.7);
        
        [bgLayerUp addSublayer:subLayerUp];
        
        [bgLayerUp addSublayer:subLayerDown];
        
        subLayerUp.zPosition = 20.f;
    } else if ([_name isEqualToString:@"Hit Testing"]) {
        _hitTestBlueLayer = [CALayer layer];
        _hitTestBlueLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _hitTestBlueLayer.backgroundColor = [UIColor blueColor].CGColor;
        _hitTestBlueLayer.position = center;
        
        _hitTestRedLayer = [CALayer layer];
        _hitTestRedLayer.frame = CGRectMake(0, 0, layerWidth / 2, layerHeight / 2);
        _hitTestRedLayer.backgroundColor = [UIColor redColor].CGColor;
        _hitTestRedLayer.position = CGPointMake(layerWidth / 2, layerHeight / 2);
        [_hitTestBlueLayer addSublayer:_hitTestRedLayer];
        
        [self.view.layer addSublayer:_hitTestBlueLayer];
    } else if ([_name isEqualToString:@"仿射变换"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"仿射变换是一种二维坐标到二维坐标之间的线性变换，保持二维图形的“平直性”（即变换后直线还是直线不会打弯，圆弧还是圆弧）和“平行性”（指保二维图形间的相对位置关系不变，平行线还是平行线，相交直线的交角不变）";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 96);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = [UIColor redColor].CGColor;
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.position = center;
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 0.7, 1.2f);
        transform = CGAffineTransformRotate(transform, M_PI / 180.0 * 30.0);
        transform = CGAffineTransformTranslate(transform, 80.f, 15.f);
        
        layer.affineTransform = transform;
        
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"透视投影"]) {
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = [UIColor redColor].CGColor;
        layer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        layer.position = center;
        
        CATransform3D transform = CATransform3DIdentity;
        // 透视投影主要是控制m34的值，调整“相机”与视图之间的距离。
        transform.m34 = -1.0 / 500;
        
        transform = CATransform3DRotate(transform, M_PI_4, 0, 1, 0);
        
        layer.transform = transform;
        
        [self.view.layer addSublayer:layer];
    } else if ([_name isEqualToString:@"灭点"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"1、远离相机视角的物体将会变小变远，当远离到一个极限距离，它们可能就缩成了一个点，这个点叫做灭点 \n2、Core Animation定义了每个图层的灭点位于图层的anchorPoint \n3、当改变一个图层的position，你也改变了它的灭点 \n4、当视图通过调整m34来让它更加有3D效果时，应该首先把它放置于屏幕中央，然后通过平移来把它移动到指定位置（而不是直接改变它的position），这样所有的3D图层都共享一个灭点";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 160);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"sublayerTransform属性"]) {
        CALayer *containerLayer = [CALayer layer];
        containerLayer.backgroundColor = [UIColor blueColor].CGColor;
        containerLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        containerLayer.position = center;
        [self.view.layer addSublayer:containerLayer];
        
        CGFloat subLayerWidth = layerWidth / 2;
        CGFloat subLayerHeight = layerHeight / 2;
        
        CALayer *leftSubLayer = [CALayer layer];
        leftSubLayer.backgroundColor = [UIColor redColor].CGColor;
        leftSubLayer.frame = CGRectMake(0, (layerHeight - subLayerHeight) / 2, subLayerWidth, subLayerHeight);
        [containerLayer addSublayer:leftSubLayer];
        
        CALayer *rightSubLayer = [CALayer layer];
        rightSubLayer.backgroundColor = [UIColor redColor].CGColor;
        rightSubLayer.frame = CGRectMake(subLayerWidth, (layerHeight - subLayerHeight) / 2, subLayerWidth, subLayerHeight);
        [containerLayer addSublayer:rightSubLayer];
        
        //apply perspective transform to container
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = - 1.0 / 500.0;
        containerLayer.sublayerTransform = perspective;
        //rotate layerView1 by 45 degrees along the Y axis
        CATransform3D transform1 = CATransform3DMakeRotation(M_PI_4, 0, 1, 0);
        leftSubLayer.transform = transform1;
        //rotate layerView2 by 45 degrees along the Y axis
        CATransform3D transform2 = CATransform3DMakeRotation(-M_PI_4, 0, 1, 0);
        rightSubLayer.transform = transform2;
    } else if ([_name isEqualToString:@"背面"]) {
        layerWidth /= 2;
        layerHeight /= 2;
        CALayer *layerUp = [CALayer layer];
        layerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + 8, layerWidth, layerHeight);
        
        layerUp.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        
        CATransform3D transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
        layerUp.transform = transform;
        
        [self.view.layer addSublayer:layerUp];
        
        CALayer *layerDown = [CALayer layer];
        layerDown.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + layerUp.bounds.size.height + 64, layerWidth, layerHeight);
        layerDown.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
        layerDown.doubleSided = NO;
        layerDown.transform = transform;
        [self.view.layer addSublayer:layerDown];
        
        _tips = [[UILabel alloc] init];
        _tips.text = @"通过配置doubleSided的属性来控制图层的背面是否要被绘制 可见的Layer:doubleSided为YES，不可见的Layer:doubleSided为NO";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 112);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"扁平化图层"]) {
        _tips = [[UILabel alloc] init];
        _tips.text = @"待理解";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 112);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
        
        CALayer *outerLayer = [CALayer layer];
        outerLayer.backgroundColor = [UIColor blueColor].CGColor;
        outerLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        outerLayer.position = center;
        [self.view.layer addSublayer:outerLayer];
        
        CALayer *innerLayer = [CALayer layer];
        innerLayer.backgroundColor = [UIColor redColor].CGColor;
        innerLayer.frame = CGRectMake(layerWidth / 4, layerHeight / 4, layerWidth / 2, layerHeight / 2);
        [outerLayer addSublayer:innerLayer];
        
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = - 1.0 / 500;
        transform = CATransform3DRotate(transform, M_PI_4, 0, 1, 0);
        outerLayer.transform = transform;
        
        CATransform3D inner = CATransform3DIdentity;
        inner.m34 = - 1.0 / 500;
        inner = CATransform3DRotate(inner, -M_PI_4, 0, 1, 0);
        innerLayer.transform = inner;
    } else if ([_name isEqualToString:@"固体对象、光亮和阴影、点击事件"]) {
        //set up the container sublayer transform
        _matrixContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _matrixContainerView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_matrixContainerView];
        
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = -1.0 / 500.0;
        perspective = CATransform3DRotate(perspective, -M_PI_4, 1, 0, 0);
        perspective = CATransform3DRotate(perspective, -M_PI_4, 0, 1, 0);
        self.matrixContainerView.layer.sublayerTransform = perspective;
        //add cube face 1
        CATransform3D transform = CATransform3DMakeTranslation(0, 0, 100);
        [self addFace:0 withTransform:transform];
        //add cube face 2
        transform = CATransform3DMakeTranslation(100, 0, 0);
        transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
        [self addFace:1 withTransform:transform];
        //add cube face 3
        transform = CATransform3DMakeTranslation(0, -100, 0);
        transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
        [self addFace:2 withTransform:transform];
        //add cube face 4
        transform = CATransform3DMakeTranslation(0, 100, 0);
        transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
        [self addFace:3 withTransform:transform];
        //add cube face 5
        transform = CATransform3DMakeTranslation(-100, 0, 0);
        transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
        [self addFace:4 withTransform:transform];
        //add cube face 6
        transform = CATransform3DMakeTranslation(0, 0, -100);
        transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
        [self addFace:5 withTransform:transform];
    } else if ([_name isEqualToString:@"CATextLayer"]) {
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, self.view.bounds.size.width, self.view.bounds.size.height -  NAVIGATIONBARHEIGHT);
        textLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
        
        textLayer.contentsScale = [UIScreen mainScreen].scale;
        
        //set text attributes
        textLayer.alignmentMode = kCAAlignmentLeft;
        textLayer.wrapped = YES;
        
        //choose a font
        UIFont *font = [UIFont systemFontOfSize:15];
        
        //choose some text
        NSString *text = @"1、基于微信iOS 6.5.4版本\n2、依然需要借助越狱的设备实现（打包后可以在非越狱设备安装）\n3、本文大部分取自（一步一步实现iOS微信自动抢红包(非越狱)），在其文的基础上跑了一遍流程；也根据理解简化了其中的部分工作：）\n4、仅用于学习交流使用，也可前往我个人博客进行交流；\n5、本文不讲解如何找到抢红包的方法";
        
        NSMutableAttributedString *string = nil;
        //create attributed string
        string = [[NSMutableAttributedString alloc] initWithString:text];
        
        //convert UIFont to a CTFont
        CFStringRef fontName = (__bridge CFStringRef)font.fontName;
        CGFloat fontSize = font.pointSize;
        CTFontRef fontRef = CTFontCreateWithName(fontName, fontSize, NULL);
        
        //set text attributes
        NSDictionary *attribs = @{
                                  (__bridge id)kCTForegroundColorAttributeName:(__bridge id)[UIColor blackColor].CGColor,
                                  (__bridge id)kCTFontAttributeName: (__bridge id)fontRef
                                  };
        
        [string setAttributes:attribs range:NSMakeRange(0, [text length])];
        attribs = @{
                    (__bridge id)kCTForegroundColorAttributeName: (__bridge id)[UIColor redColor].CGColor,
                    (__bridge id)kCTUnderlineStyleAttributeName: @(kCTUnderlineStyleSingle),
                    (__bridge id)kCTFontAttributeName: (__bridge id)fontRef
                    };
        [string setAttributes:attribs range:NSMakeRange(4, 2)];
        
        //release the CTFont we created earlier
        CFRelease(fontRef);
        
        //set layer text
        textLayer.string = string;
        
        [self.view.layer addSublayer:textLayer];
    } else if ([_name isEqualToString:@"CATransformLayer"]) {
        //set up the container sublayer transform
        _matrixContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _matrixContainerView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_matrixContainerView];
        
        //set up the perspective transform
        CATransform3D pt = CATransform3DIdentity;
        pt.m34 = -1.0 / 500.0;
        _matrixContainerView.layer.sublayerTransform = pt;
        
        //set up the transform for cube 1 and add it
        CATransform3D c1t = CATransform3DIdentity;
        c1t = CATransform3DTranslate(c1t, -100, 0, 0);
        CALayer *cube1 = [self cubeWithTransform:c1t];
        [_matrixContainerView.layer addSublayer:cube1];
        
        //set up the transform for cube 2 and add it
        CATransform3D c2t = CATransform3DIdentity;
        c2t = CATransform3DTranslate(c2t, 100, 0, 0);
        c2t = CATransform3DRotate(c2t, -M_PI_4, 1, 0, 0);
        c2t = CATransform3DRotate(c2t, -M_PI_4, 0, 1, 0);
        CALayer *cube2 = [self cubeWithTransform:c2t];
        [_matrixContainerView.layer addSublayer:cube2];
    } else if ([_name isEqualToString:@"CAGradientLayer"]) {
        CAGradientLayer *layerUp = [CAGradientLayer layer];
        layerUp.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + 8, layerWidth, layerHeight);
        layerUp.colors = @[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor];
        layerUp.startPoint = CGPointMake(0, 0);
        layerUp.endPoint = CGPointMake(1, 1);
        [self.view.layer addSublayer:layerUp];
        
        CAGradientLayer *layerDown = [CAGradientLayer layer];
        layerDown.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - layerWidth) / 2, NAVIGATIONBARHEIGHT + 112 + layerUp.bounds.size.height + 64, layerWidth, layerHeight);
        layerDown.locations = @[@0, @0.25, @0.5];
        layerDown.colors = @[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor greenColor].CGColor, (__bridge id)[UIColor blueColor].CGColor];
        layerDown.startPoint = CGPointMake(0, 0);
        layerDown.endPoint = CGPointMake(1, 1);
        [self.view.layer addSublayer:layerDown];
        
        _tips = [[UILabel alloc] init];
        _tips.text = @"locations数组并不是强制要求的，但是如果你给它赋值了就一定要确保locations的数组大小和colors数组大小一定要相同，否则你将会得到一个空白的渐变";
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 112);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"CAReplicatorLayer、反射"]) {
        //create a replicator layer and add it to our view
        CAReplicatorLayer *replicator = [CAReplicatorLayer layer];
        replicator.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height / 2);
        replicator.backgroundColor = [UIColor lightGrayColor].CGColor;
        [self.view.layer addSublayer:replicator];
        
        //configure the replicator
        replicator.instanceCount = 6;   // 复制6个
        replicator.instanceDelay = 0.3;  // 复制间隔0.3秒
        replicator.instanceColor = [UIColor redColor].CGColor;
        replicator.instanceRedOffset = -0.1;
        replicator.instanceBlueOffset = -0.1;
        replicator.instanceGreenOffset = -0.1;
        
        //create a sublayer and place it inside the replicator
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0.f, 0.f, 10.f, 10.f);
        layer.backgroundColor = [UIColor redColor].CGColor;
        layer.cornerRadius = 5.f;
        layer.position = CGPointMake(replicator.frame.size.width / 2, NAVIGATIONBARHEIGHT + 48);
        
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.toValue = [NSNumber numberWithFloat:10.0f];
        scale.duration = 2.f;
        scale.removedOnCompletion = NO;
        
        CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.toValue = [NSNumber numberWithFloat:0.0f];
        opacity.duration = 2.f;
        opacity.removedOnCompletion = NO;
        
        CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
        group.animations = @[scale, opacity];
        group.repeatCount = HUGE;
        group.duration = 2.f;
        group.removedOnCompletion = NO;
        [layer addAnimation:group forKey:nil];
        
        [replicator addSublayer:layer];
        
        {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, self.view.bounds.size.height / 2)];
            view.backgroundColor = [UIColor darkGrayColor];
            [self.view addSubview:view];
            
            CAReplicatorLayer *reflectLayer = [CAReplicatorLayer layer];
            reflectLayer.instanceCount = 2;
            reflectLayer.frame = CGRectMake(view.bounds.size.width / 2 - 20, 0, 40, 40);
            
            
            //move reflection instance below original and flip vertically
            CATransform3D transform = CATransform3DIdentity;
            CGFloat verticalOffset = 40 + 2;
            transform = CATransform3DTranslate(transform, 0, verticalOffset, 0);
            transform = CATransform3DScale(transform, 1, -1, 0);
            reflectLayer.instanceTransform = transform;
            
            //reduce alpha of reflection layer
            reflectLayer.instanceAlphaOffset = -0.6;
            
            [view.layer addSublayer:reflectLayer];
            
            CALayer *layer = [CALayer layer];
            layer.contents = (__bridge id)([UIImage imageNamed:@"seven.png"]).CGImage;
            layer.contentsGravity = kCAGravityResize;
            layer.frame = CGRectMake(0, 0, 40, 40);
            [reflectLayer addSublayer:layer];
        }
    } else if ([_name isEqualToString:@"CAScrollLayer"]) {
        _scrollLayer = [CAScrollLayer layer];
        _scrollLayer.scrollMode = kCAScrollBoth;
        _scrollLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _scrollLayer.position = center;
        _scrollLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
        [self.view.layer addSublayer:_scrollLayer];
        
        CALayer *layer = [CALayer layer];
        layer.contents =(__bridge id)([UIImage imageNamed:@"bottle.png"]).CGImage;
        layer.frame = CGRectMake(0, 0, _scrollLayer.bounds.size.width * 2, _scrollLayer.bounds.size.height * 2);
        layer.position = CGPointMake(layerWidth / 2, layerHeight / 2);
        layer.contentsGravity = kCAGravityResize;
        [_scrollLayer addSublayer:layer];
        
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureChanged:)];
        [self.view addGestureRecognizer:recognizer];
    } else if ([_name isEqualToString:@"CATiledLayer"]) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        [self.view addSubview:scrollView];
        
        _tiledLayer = [CATiledLayer layer];
        _tiledLayer.frame = CGRectMake(0, 0, 1920 / [UIScreen mainScreen].scale, 5196 / [UIScreen mainScreen].scale);
        _tiledLayer.contentsScale = [UIScreen mainScreen].scale;
        _tiledLayer.delegate = self;
        [scrollView.layer addSublayer:_tiledLayer];
        
        scrollView.contentSize = _tiledLayer.frame.size;
        
        [_tiledLayer setNeedsDisplay];
    } else if ([_name isEqualToString:@"CAEmitterLayer"]) {
        CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
        emitterLayer.frame = self.view.bounds;
        emitterLayer.backgroundColor = [UIColor blackColor].CGColor;
        [self.view.layer addSublayer:emitterLayer];
        
        //configure emitter
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        emitterLayer.emitterPosition = CGPointMake(emitterLayer.frame.size.width / 2.0, emitterLayer.frame.size.height / 2.0);
        
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.contents = (__bridge id)[UIImage imageNamed:@"seven.png"].CGImage;
        // 出生率，即单位时间产生的粒子
        cell.birthRate = 150;
        // 生命周期，即每个粒子的生命时长
        cell.lifetime = 5.0;
        
        // 粒子的附着色
        cell.color = [UIColor colorWithRed:1 green:0.5 blue:0.1 alpha:1.0].CGColor;
        // 粒子透明度在生命周期内的改变速度；
        cell.alphaSpeed = -0.4;
        cell.velocity = 50;
        cell.velocityRange = 50;
        cell.emissionRange = M_PI * 2.0;
        
        //add particle template to emitter
        emitterLayer.emitterCells = @[cell];
    } else if ([_name isEqualToString:@"CAEAGLLayer"]) {
        _glView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, layerWidth, layerHeight)];
        _glView.center = center;
        _glView.backgroundColor = [UIColor blackColor];
        
        [self.view addSubview:_glView];
        
        //set up context
        self.glContext = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.glContext];
        
        //set up layer
        self.glLayer = [CAEAGLLayer layer];
        self.glLayer.frame = self.glView.bounds;
        [self.glView.layer addSublayer:self.glLayer];
        self.glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@NO, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
        
        //set up base effect
        self.effect = [[GLKBaseEffect alloc] init];
        
        //set up buffers
        [self setUpBuffers];
        
        //draw frame
        [self drawFrame];
    } else if ([_name isEqualToString:@"AVPlayerLayer"]) {
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = - 1.0 / 500;
        transform = CATransform3DRotate(transform, M_PI_4, 1.0, 1.0, 0);
        //get video URL
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"mate2" withExtension:@"mp4"];
        AVAsset *asset = [AVAsset assetWithURL:URL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        playerLayer.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - NAVIGATIONBARHEIGHT);
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerLayer.transform = transform;
        [self.view.layer addSublayer:playerLayer];
        [player play];
    } else if ([_name isEqualToString:@"事务、完成块"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = center;
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"Change" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(changeColor:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else if ([_name isEqualToString:@"图层行为"]) {
        //test layer action when outside of animation block
        id outSide = [self.view actionForLayer:self.view.layer forKey:@"backgroundColor"];
        NSLog(@"Outside: %@", outSide);
        
        //begin animation block
        [UIView beginAnimations:nil context:nil];
        //test layer action when inside of animation block
        id inside = [self.view actionForLayer:self.view.layer forKey:@"backgroundColor"];
        NSLog(@"Inside: %@", inside);
        //end animation block
        [UIView commitAnimations];
        
        _tips = [[UILabel alloc] init];
        _tips.text = [NSString stringWithFormat:@"1、UIView 默认对CALayer的隐式动画action返回nil，此例中为：[%@] \n2、如果用beginAnimations和commitAnimations包括后，则隐式动画则会生效了，此例中为：[%@]", outSide, inside];
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 112);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"呈现层与模型层"]) {
        _transactionLayer = [CALayer layer];
        _transactionLayer.backgroundColor = [UIColor redColor].CGColor;
        _transactionLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _transactionLayer.position = center;
        [self.view.layer addSublayer:_transactionLayer];
    } else if ([_name isEqualToString:@"属性动画"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = center;
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"Change" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(explicitChangeColor:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else if ([_name isEqualToString:@"关键帧动画"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = CGPointMake(center.x, center.y - 128);
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"Change" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(keyframeChangeColor:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        //create a path
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(button.center.x, button.center.y + 24 + 8 + 96) radius:48.f startAngle:0 endAngle:M_PI*2 clockwise:YES];
        
        //draw the path using a CAShapeLayer
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.path = bezierPath.CGPath;
        pathLayer.fillColor = [UIColor clearColor].CGColor;
        pathLayer.strokeColor = [UIColor redColor].CGColor;
        pathLayer.lineWidth = 3.0f;
        [self.view.layer addSublayer:pathLayer];
        
        CAShapeLayer *shipLayer = [CAShapeLayer layer];
        shipLayer.contents = (__bridge id)[UIImage imageNamed:@"airplane.png"].CGImage;
        shipLayer.frame = CGRectMake(0, 0, 50, 50);
        shipLayer.position = CGPointMake(button.center.x + 48.f, button.center.y + 24 + 8 + 96);
        [self.view.layer addSublayer:shipLayer];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.keyPath = @"position";
        animation.path = bezierPath.CGPath;
        animation.rotationMode = kCAAnimationRotateAuto;
        animation.duration = 4.f;
        animation.repeatCount = HUGE;
        [shipLayer addAnimation:animation forKey:nil];
    } else if ([_name isEqualToString:@"虚拟属性"]) {
        CAShapeLayer *shipLayer = [CAShapeLayer layer];
        shipLayer.contents = (__bridge id)[UIImage imageNamed:@"airplane.png"].CGImage;
        shipLayer.frame = CGRectMake(0, 0, 50, 50);
        shipLayer.position = center;
        [self.view.layer addSublayer:shipLayer];
        
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.keyPath = @"transform.rotation";
        animation.duration = 2.f;
        animation.repeatCount = HUGE;
        animation.byValue = @(2 * M_PI);
        [shipLayer addAnimation:animation forKey:nil];
    } else if ([_name isEqualToString:@"动画组"]) {
        CALayer *layerBottom = [CALayer layer];
        layerBottom.frame = CGRectMake(0, 0, 50, 50);
        layerBottom.backgroundColor = [UIColor blueColor].CGColor;
        layerBottom.position = CGPointMake(center.x + 48, center.y);
        [self.view.layer addSublayer:layerBottom];
        
        CALayer *mask = [CALayer layer];
        mask.frame = layerBottom.bounds;
        mask.contents = (__bridge id _Nullable)([UIImage imageNamed:@"airplane.png"].CGImage);
        mask.contentsGravity = kCAGravityResizeAspectFill;
        layerBottom.mask = mask;
        
        //create a path
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:center radius:48.f startAngle:0 endAngle:M_PI*2 clockwise:YES];
        
        //draw the path using a CAShapeLayer
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.path = bezierPath.CGPath;
        pathLayer.fillColor = [UIColor clearColor].CGColor;
        pathLayer.strokeColor = [UIColor redColor].CGColor;
        pathLayer.lineWidth = 3.0f;
        [self.view.layer addSublayer:pathLayer];
        
        CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animation];
        keyframeAnimation.keyPath = @"position";
        keyframeAnimation.path = bezierPath.CGPath;
        keyframeAnimation.rotationMode = kCAAnimationRotateAuto;
        
        CABasicAnimation *basicAnimation = [CABasicAnimation animation];
        basicAnimation.keyPath = @"backgroundColor";
        basicAnimation.toValue = (__bridge id)[UIColor redColor].CGColor;
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[keyframeAnimation, basicAnimation];
        group.duration = 4.f;
        group.repeatCount = HUGE;
        [layerBottom addAnimation:group forKey:nil];
    } else if ([_name isEqualToString:@"过渡"]) {
        self.colors = @[(__bridge id)[UIColor redColor].CGColor,
                        (__bridge id)[UIColor blueColor].CGColor,
                        (__bridge id)[UIColor greenColor].CGColor];
        
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = (__bridge CGColorRef _Nullable)([self.colors objectAtIndex:0]);
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = center;
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"transition" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(transitionAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else if ([_name isEqualToString:@"自定义动画"]) {
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = center;
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"transition" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(customTransition:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else if ([_name isEqualToString:@"在动画过程中取消动画"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = center;
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *start = [[UIButton alloc] init];
        start.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        start.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        start.backgroundColor = [UIColor blueColor];
        start.layer.cornerRadius = 5.f;
        [start setTitle:@"start" forState:UIControlStateNormal];
        [start addTarget:self action:@selector(startAnimation:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:start];
        
        UIButton *stop = [[UIButton alloc] init];
        stop.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        stop.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24 + 48 + 8);
        stop.backgroundColor = [UIColor blueColor];
        stop.layer.cornerRadius = 5.f;
        [stop setTitle:@"stop" forState:UIControlStateNormal];
        [stop addTarget:self action:@selector(stopAnimation:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:stop];
    } else if ([_name isEqualToString:@"持续和重复"]) {
        //add the door
        CALayer *doorLayer = [CALayer layer];
        doorLayer.frame = CGRectMake(0, 0, 53.5, 100);
        doorLayer.position = CGPointMake(center.x - 53.5 / 2, center.y);
        doorLayer.anchorPoint = CGPointMake(0, 0.5);
        doorLayer.contents = (__bridge id)[UIImage imageNamed: @"door.png"].CGImage;
        [self.view.layer addSublayer:doorLayer];
        //apply perspective transform
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = -1.0 / 500.0;
        self.view.layer.sublayerTransform = perspective;
        //apply swinging animation
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.keyPath = @"transform.rotation.y";
        animation.toValue = @(-M_PI_2);
        animation.duration = 2.0;
        animation.repeatDuration = INFINITY;
        animation.autoreverses = YES;
        [doorLayer addAnimation:animation forKey:nil];
    } else if ([_name isEqualToString:@"相对时间"]) {
        //create a path
        _bezierPath = [UIBezierPath bezierPathWithArcCenter:center radius:48.f startAngle:0 endAngle:M_PI*2 clockwise:YES];
        
        //draw the path using a CAShapeLayer
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.path = _bezierPath.CGPath;
        pathLayer.fillColor = [UIColor clearColor].CGColor;
        pathLayer.strokeColor = [UIColor redColor].CGColor;
        pathLayer.lineWidth = 3.0f;
        [self.view.layer addSublayer:pathLayer];
        
        _shipLayer = [CAShapeLayer layer];
        _shipLayer.contents = (__bridge id)[UIImage imageNamed:@"airplane.png"].CGImage;
        _shipLayer.frame = CGRectMake(0, 0, 50, 50);
        _shipLayer.position = CGPointMake(center.x + 48.f, center.y);
        [self.view.layer addSublayer:_shipLayer];
        
        _relativeTimeControlContainerView.frame = CGRectMake(0, 0, self.view.bounds.size.width - 48, 80);
        _relativeTimeControlContainerView.center = CGPointMake(center.x, center.y + 48.f + 96.f);
        [self.view addSubview:_relativeTimeControlContainerView];
        
        [self updateSliders:nil];
    } else if ([_name isEqualToString:@"fillMode"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = center;
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"Change" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(fillModeChange:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        _tips = [[UILabel alloc] init];
        _tips.text = [NSString stringWithFormat:@"kCAFillModeRemoved 这个是默认值，也就是说当动画开始前和动画结束后，动画对layer都没有影响，动画结束后，layer会恢复到之前的状态\nkCAFillModeForwards 当动画结束后，layer会一直保持着动画最后的状态\nkCAFillModeBackwards 在动画开始前，只需要将动画加入了一个layer，layer便立即进入动画的初始状态并等待动画开始。\nkCAFillModeBoth 这个其实就是上面两个的合成.动画加入后开始之前，layer便处于动画初始状态，动画结束后layer保持动画最后的状态"];
        _tips.frame = CGRectMake(0, NAVIGATIONBARHEIGHT, [UIScreen mainScreen].bounds.size.width, 160);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"手动动画"]) {
        //add the door
        _doorLayer = [CALayer layer];
        _doorLayer.frame = CGRectMake(0, 0, 53.5, 100);
        _doorLayer.position = CGPointMake(center.x - 53.5 / 2, center.y);
        _doorLayer.anchorPoint = CGPointMake(0, 0.5);
        _doorLayer.contents = (__bridge id)[UIImage imageNamed: @"door.png"].CGImage;
        [self.view.layer addSublayer:_doorLayer];
        _doorLayer.speed = 0.f;
        
        //apply perspective transform
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = -1.0 / 500.0;
        self.view.layer.sublayerTransform = perspective;
        
        //apply swinging animation
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.keyPath = @"transform.rotation.y";
        animation.toValue = @(-M_PI_2);
        animation.duration = 2.0;
        animation.repeatDuration = INFINITY;
        animation.autoreverses = YES;
        [_doorLayer addAnimation:animation forKey:nil];
        
        //add pan gesture recognizer to handle swipes
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
        [pan addTarget:self action:@selector(pan:)];
        [self.view addGestureRecognizer:pan];
    } else if ([_name isEqualToString:@"动画速度"]) {
        _timingFunctionLayer = [CALayer layer];
        _timingFunctionLayer.frame = CGRectMake(0, 0, 50, 50);
        _timingFunctionLayer.backgroundColor = [UIColor blueColor].CGColor;
        _timingFunctionLayer.position = CGPointMake(center.x + 48, center.y);
        [self.view.layer addSublayer:_timingFunctionLayer];
        
        CALayer *mask = [CALayer layer];
        mask.frame = _timingFunctionLayer.bounds;
        mask.contents = (__bridge id _Nullable)([UIImage imageNamed:@"airplane.png"].CGImage);
        mask.contentsGravity = kCAGravityResizeAspectFill;
        _timingFunctionLayer.mask = mask;
        
        //create a path
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(center.x, center.y) radius:48.f startAngle:0 endAngle:M_PI*2 clockwise:YES];
        
        //draw the path using a CAShapeLayer
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.path = bezierPath.CGPath;
        pathLayer.fillColor = [UIColor clearColor].CGColor;
        pathLayer.strokeColor = [UIColor redColor].CGColor;
        pathLayer.lineWidth = 3.0f;
        [self.view.layer addSublayer:pathLayer];
        
        _timingFunctionKeyframeAnimation = [CAKeyframeAnimation animation];
        _timingFunctionKeyframeAnimation.keyPath = @"position";
        _timingFunctionKeyframeAnimation.path = bezierPath.CGPath;
        _timingFunctionKeyframeAnimation.rotationMode = kCAAnimationRotateAuto;
        
        _timingFunctionBasicAnimation = [CABasicAnimation animation];
        _timingFunctionBasicAnimation.keyPath = @"backgroundColor";
        _timingFunctionBasicAnimation.toValue = (__bridge id)[UIColor redColor].CGColor;
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[_timingFunctionKeyframeAnimation, _timingFunctionBasicAnimation];
        group.duration = 4.f;
        group.repeatCount = HUGE;
        group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        group.removedOnCompletion = NO;
        [_timingFunctionLayer addAnimation:group forKey:@"timingFunction"];
        
        _timimgFunctionLabel = [[UILabel alloc] init];
        _timimgFunctionLabel.frame = CGRectMake(0, 0, self.view.bounds.size.width / 2, 30);
        _timimgFunctionLabel.center = CGPointMake(center.x, center.y + 48 + 15 + 16);
        _timimgFunctionLabel.text = kCAMediaTimingFunctionEaseInEaseOut;
        _timimgFunctionLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_timimgFunctionLabel];
        
        CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width / 2;
        CGFloat buttonHeight = 36.f;
        NSArray *buttonTextArray = @[@[kCAMediaTimingFunctionEaseIn, kCAMediaTimingFunctionEaseOut], @[kCAMediaTimingFunctionEaseInEaseOut, kCAMediaTimingFunctionLinear]];
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 2; j++) {
                UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth * j, [UIScreen mainScreen].bounds.size.height - buttonHeight * (i + 1), buttonWidth, buttonHeight)];
                button.layer.borderColor = [UIColor grayColor].CGColor;
                button.layer.borderWidth = 1.f;
                [button setTitle:[[buttonTextArray objectAtIndex:i] objectAtIndex:j] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                button.backgroundColor = [UIColor whiteColor];
                button.titleLabel.font = [UIFont systemFontOfSize:13.f];
                button.tag = i * 2 + j;
                [button addTarget:self action:@selector(adjustTimingFunction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:button];
            }
        }
    } else if ([_name isEqualToString:@"UIView的动画缓冲"]) {
        _animationOptionLabel = [[UILabel alloc] init];
        _animationOptionLabel.frame = CGRectMake(0, 0, self.view.bounds.size.width, 30);
        _animationOptionLabel.center = center;
        _animationOptionLabel.textAlignment = NSTextAlignmentCenter;
        _animationOptionLabel.text = @"UIView的动画缓冲";
        [self.view addSubview:_animationOptionLabel];
    } else if ([_name isEqualToString:@"缓冲和关键帧动画"]) {
        _globalLayer = [CALayer layer];
        _globalLayer.backgroundColor = [UIColor redColor].CGColor;
        _globalLayer.frame = CGRectMake(0, 0, layerWidth, layerHeight);
        _globalLayer.position = CGPointMake(center.x, center.y);
        [self.view.layer addSublayer:_globalLayer];
        
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(0, 0, layerWidth / 2, 48);
        button.center = CGPointMake(center.x, _globalLayer.position.y + (layerHeight / 2) + 8 + 24);
        button.backgroundColor = [UIColor blueColor];
        button.layer.cornerRadius = 5.f;
        [button setTitle:@"Change" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(timingFunctionKeyframeChangeColor:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else if ([_name isEqualToString:@"EaseIn"]) {
        CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        float controlPoint1[2], controlPoint2[2];
        [function getControlPointAtIndex:1 values:controlPoint1];
        [function getControlPointAtIndex:2 values:controlPoint2];
        
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        [bezierPath moveToPoint:CGPointZero];
        [bezierPath addCurveToPoint:CGPointMake(1, 1) controlPoint1:CGPointMake(controlPoint1[0], controlPoint1[1]) controlPoint2:CGPointMake(controlPoint2[0], controlPoint2[1])];
        //scale the path up to a reasonable size for display
        [bezierPath applyTransform:CGAffineTransformMakeScale(200, 200)];
        
        //create shape layer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 4.0f;
        shapeLayer.path = bezierPath.CGPath;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.center = center;
        view.backgroundColor = [UIColor lightGrayColor];
        view.layer.geometryFlipped = YES;
        [self.view addSubview:view];
        [view.layer addSublayer:shapeLayer];
    } else if ([_name isEqualToString:@"Linear"]) {
        CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        float controlPoint1[2], controlPoint2[2];
        [function getControlPointAtIndex:1 values:controlPoint1];
        [function getControlPointAtIndex:2 values:controlPoint2];
        
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        [bezierPath moveToPoint:CGPointZero];
        [bezierPath addCurveToPoint:CGPointMake(1, 1) controlPoint1:CGPointMake(controlPoint1[0], controlPoint1[1]) controlPoint2:CGPointMake(controlPoint2[0], controlPoint2[1])];
        //scale the path up to a reasonable size for display
        [bezierPath applyTransform:CGAffineTransformMakeScale(200, 200)];
        
        //create shape layer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 4.0f;
        shapeLayer.path = bezierPath.CGPath;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.center = center;
        view.backgroundColor = [UIColor lightGrayColor];
        view.layer.geometryFlipped = YES;
        [self.view addSubview:view];
        [view.layer addSublayer:shapeLayer];
    } else if ([_name isEqualToString:@"EaseOut"]) {
        CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        float controlPoint1[2], controlPoint2[2];
        [function getControlPointAtIndex:1 values:controlPoint1];
        [function getControlPointAtIndex:2 values:controlPoint2];
        
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        [bezierPath moveToPoint:CGPointZero];
        [bezierPath addCurveToPoint:CGPointMake(1, 1) controlPoint1:CGPointMake(controlPoint1[0], controlPoint1[1]) controlPoint2:CGPointMake(controlPoint2[0], controlPoint2[1])];
        //scale the path up to a reasonable size for display
        [bezierPath applyTransform:CGAffineTransformMakeScale(200, 200)];
        
        //create shape layer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 4.0f;
        shapeLayer.path = bezierPath.CGPath;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.center = center;
        view.backgroundColor = [UIColor lightGrayColor];
        view.layer.geometryFlipped = YES;
        [self.view addSubview:view];
        [view.layer addSublayer:shapeLayer];
    } else if ([_name isEqualToString:@"EaseInEaseOut"]) {
        CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        float controlPoint1[2], controlPoint2[2];
        [function getControlPointAtIndex:1 values:controlPoint1];
        [function getControlPointAtIndex:2 values:controlPoint2];
        
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        [bezierPath moveToPoint:CGPointZero];
        [bezierPath addCurveToPoint:CGPointMake(1, 1) controlPoint1:CGPointMake(controlPoint1[0], controlPoint1[1]) controlPoint2:CGPointMake(controlPoint2[0], controlPoint2[1])];
        //scale the path up to a reasonable size for display
        [bezierPath applyTransform:CGAffineTransformMakeScale(200, 200)];
        
        //create shape layer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 4.0f;
        shapeLayer.path = bezierPath.CGPath;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.center = center;
        view.backgroundColor = [UIColor lightGrayColor];
        view.layer.geometryFlipped = YES;
        [self.view addSubview:view];
        [view.layer addSublayer:shapeLayer];
    } else if ([_name isEqualToString:@"更加复杂的动画曲线"]) {
        UIImageView *ball = [[UIImageView alloc] init];
        ball.image = [UIImage imageNamed:@"baseball.png"];
        ball.frame = CGRectMake(0, 0, 85, 88.5);
        ball.center = CGPointMake(center.x, 32);
        [self.view addSubview:ball];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.keyPath = @"position";
        animation.duration = 2.0;
        animation.values = @[
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 236)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 128)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 48)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 10)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 2)],
                             [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)]
                             ];
        animation.timingFunctions = @[
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut],
                                      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]
                                      ];
        
        animation.keyTimes = @[@(0), @(0.3), @(0.5), @(0.7), @(0.8), @(0.9), @(0.95), @(0.975), @(0.99), @(1.0)];
        
        //apply animation
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [ball.layer addAnimation:animation forKey:nil];
    } else if ([_name isEqualToString:@"流程自动化"]) {
        UIImageView *ball = [[UIImageView alloc] init];
        ball.image = [UIImage imageNamed:@"baseball.png"];
        ball.frame = CGRectMake(0, 0, 85, 88.5);
        ball.center = CGPointMake(center.x, center.y - 236);
        [self.view addSubview:ball];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.keyPath = @"position";
        
        CFTimeInterval duration = 1.0;
        //generate keyframes
        NSInteger numFrames = duration * 60;
        NSMutableArray *frames = [NSMutableArray array];
        NSValue *fromValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 236)];
        NSValue *toValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)];
        for (int i = 0; i < numFrames; i++) {
            // 总时长是1秒钟
            // 1秒钟之内有60帧
            // 平均每帧需要时间
            float time = 1/(float)numFrames * i;
            time = bounceEaseOut(time);
            [frames addObject:[self interpolateFromValue:fromValue toValue:toValue time:time]];
        }
        animation.values = frames;
        animation.duration = 1.0;
        //apply animation
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [ball.layer addAnimation:animation forKey:nil];
    } else if ([_name isEqualToString:@"NSTimer"]) {
        _ball = [[UIImageView alloc] init];
        _ball.image = [UIImage imageNamed:@"baseball.png"];
        _ball.frame = CGRectMake(0, 0, 85, 88.5);
        _ball.center = CGPointMake(center.x, center.y - 236);
        _ball.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_ball];
        
        //configure the animation
        self.duration = 1.0;
        self.timeOffset = 0.0;
        self.fromValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 236)];
        self.toValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)];
        //stop the timer if it's already running
        [self.timer invalidate];
        //start the timer
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1/60.0
                                                      target:self
                                                    selector:@selector(step:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        _tips = [[UILabel alloc] init];
        _tips.text = @"使用NSTimer做动画有如下缺点：\n1、NSTimer需要等待NSRunLoop中的上一个任务完成后才会被执行，因此有可能被延迟启动\n2、屏幕重绘的频率是一秒钟六十次,但是如果屏幕重绘的上一个任务执行的时间很长，屏幕重绘也会被延迟。3、基于此，本代码中的NSTimer就不能准确的1秒钟执行60次（其他NSTimer也一样）\n3、如果本应“同步”的在NSTimer，它的执行发生屏幕更新之后，动画就卡住了\n4、如果NSTimer，在屏幕更新的时候执行了两次，那么动画也会有跳跃的感觉";
        _tips.frame = CGRectMake(0, center.y + 48, [UIScreen mainScreen].bounds.size.width, 196);
        _tips.textAlignment = NSTextAlignmentCenter;
        _tips.numberOfLines = 0;
        _tips.font = [UIFont systemFontOfSize:13];
        _tips.backgroundColor = [UIColor whiteColor];
        _tips.layer.masksToBounds = YES;
        [self.view addSubview:_tips];
    } else if ([_name isEqualToString:@"CADisplayLink"]) {
        _ball = [[UIImageView alloc] init];
        _ball.image = [UIImage imageNamed:@"baseball.png"];
        _ball.frame = CGRectMake(0, 0, 85, 88.5);
        _ball.center = CGPointMake(center.x, center.y - 236);
        [self.view addSubview:_ball];
        
        //configure the animation
        self.duration = 1.0;
        self.timeOffset = 0.0;
        self.fromValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 236)];
        self.toValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)];
        //stop the timer if it's already running
        [self.displayLink invalidate];
        
        self.lastStep = CACurrentMediaTime();
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkStep:)];
        
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)adjustLayerGravity:(id)sender {
    UIButton *button = sender;
    switch (button.tag) {
        case 0:
            _gravityLayer.contentsGravity = kCAGravityCenter;
            break;
        case 1:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityTop : kCAGravityBottom;
            break;
        case 2:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityBottom : kCAGravityTop;
            break;
        case 3:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityLeft : kCAGravityRight;
            break;
        case 4:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityRight : kCAGravityLeft;
            break;
        case 5:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityTopLeft : kCAGravityTopRight;
            break;
        case 6:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityTopRight : kCAGravityTopLeft;
            break;
        case 7:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityBottomLeft : kCAGravityBottomRight;
            break;
        case 8:
            _gravityLayer.contentsGravity = _gravityLayer.contentsAreFlipped ? kCAGravityBottomRight : kCAGravityBottomLeft;
            break;
        case 9:
            _gravityLayer.contentsGravity = kCAGravityResize;
            break;
        case 10:
            _gravityLayer.contentsGravity = kCAGravityResizeAspect;
            break;
        case 11:
            _gravityLayer.contentsGravity = kCAGravityResizeAspectFill;
            break;
    }
    
    _tips.text = [NSString stringWithFormat:@"contentGravity = %@", _gravityLayer.contentsGravity];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    //draw a thick red circle
    if (_customDrawingLayer) {
        CGContextSetLineWidth(ctx, 10.0f);
        CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
        CGContextStrokeEllipseInRect(ctx, layer.bounds);
    } else {
        //determine tile coordinate
        CATiledLayer *tiledLayer = (CATiledLayer *)layer;
        //determine tile coordinate
        CGRect bounds = CGContextGetClipBoundingBox(ctx);
        CGFloat scale = [UIScreen mainScreen].scale;
        NSInteger x = floor(bounds.origin.x / tiledLayer.tileSize.width * scale);
        NSInteger y = floor(bounds.origin.y / tiledLayer.tileSize.height * scale);
        
        //load tile image
        NSString *imageName = [NSString stringWithFormat: @"style_%02li_%02li", (long)x, (long)y];
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"];
        UIImage *tileImage = [UIImage imageWithContentsOfFile:imagePath];
        
        //draw tile
        UIGraphicsPushContext(ctx);
        [tileImage drawInRect:bounds];
        UIGraphicsPopContext();
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    point = [_hitTestBlueLayer convertPoint:point fromLayer:self.view.layer];
    if ([_hitTestBlueLayer containsPoint:point]) {
        point = [_hitTestRedLayer convertPoint:point fromLayer:_hitTestBlueLayer];
        if ([_hitTestRedLayer containsPoint:point]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Inside Red Layer"
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Inside Blue Layer"
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (_transactionLayer) {
        point = [[touches anyObject] locationInView:self.view];
        if ([_transactionLayer.presentationLayer hitTest:point]) {
            //randomize the layer background color
            CGFloat red = arc4random() / (CGFloat)INT_MAX;
            CGFloat green = arc4random() / (CGFloat)INT_MAX;
            CGFloat blue = arc4random() / (CGFloat)INT_MAX;
            _transactionLayer.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0].CGColor;
        } else {
            //otherwise (slowly) move the layer to new position
            [CATransaction begin];
            [CATransaction setAnimationDuration:4.0];
            _transactionLayer.position = point;
            [CATransaction commit];
        }
    } else if (_animationOptionLabel) {
        //perform the animation
        [UIView animateWithDuration:1.0 delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             //set the position
                             _animationOptionLabel.center = [[touches anyObject] locationInView:self.view];
                         }
                         completion:NULL];
    }
}

- (void)addFace:(NSInteger)index withTransform:(CATransform3D)transform {
    //get the face view and add it to the container
    UIView *face = self.cubeFaces[index];
    [self.matrixContainerView addSubview:face];
    //center the face view within the container
    CGSize containerSize = self.matrixContainerView.bounds.size;
    face.center = CGPointMake(containerSize.width / 2.0, containerSize.height / 2.0);
    // apply the transform
    face.layer.transform = transform;
    //apply lighting
    [self applyLightingToFace:face.layer];
}

- (void)applyLightingToFace:(CALayer *)face {
    //add lighting layer
    CALayer *layer = [CALayer layer];
    layer.frame = face.bounds;
    [face addSublayer:layer];
    //convert the face transform to matrix
    //(GLKMatrix4 has the same structure as CATransform3D)
    CATransform3D transform = face.transform;
    GLKMatrix4 matrix4 = [self matrixFrom3DTransformation:transform];
    GLKMatrix3 matrix3 = GLKMatrix4GetMatrix3(matrix4);
    //get face normal
    GLKVector3 normal = GLKVector3Make(0, 0, 1);
    normal = GLKMatrix3MultiplyVector3(matrix3, normal);
    normal = GLKVector3Normalize(normal);
    //get dot product with light direction
    GLKVector3 light = GLKVector3Normalize(GLKVector3Make(LIGHT_DIRECTION));
    float dotProduct = GLKVector3DotProduct(light, normal);
    //set lighting layer opacity
    CGFloat shadow = 1 + dotProduct - AMBIENT_LIGHT;
    UIColor *color = [UIColor colorWithWhite:0 alpha:shadow];
    layer.backgroundColor = color.CGColor;
}

- (GLKMatrix4)matrixFrom3DTransformation:(CATransform3D)transform {
    GLKMatrix4 matrix = GLKMatrix4Make(transform.m11, transform.m12, transform.m13, transform.m14,
                                       transform.m21, transform.m22, transform.m23, transform.m24,
                                       transform.m31, transform.m32, transform.m33, transform.m34,
                                       transform.m41, transform.m42, transform.m43, transform.m44);
    return matrix;
}

- (IBAction)clickFace3:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Click face 3"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (CALayer *)faceWithTransform:(CATransform3D)transform {
    //create cube face layer
    CALayer *face = [CALayer layer];
    face.frame = CGRectMake(-50, -50, 100, 100);
    
    //apply a random color
    CGFloat red = (rand() / (double)INT_MAX);
    CGFloat green = (rand() / (double)INT_MAX);
    CGFloat blue = (rand() / (double)INT_MAX);
    face.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0].CGColor;
    
    //apply the transform and return
    face.transform = transform;
    return face;
}

- (CALayer *)cubeWithTransform:(CATransform3D)transform {
    //create cube layer
    CATransformLayer *cube = [CATransformLayer layer];
    
    //add cube face 1
    CATransform3D ct = CATransform3DMakeTranslation(0, 0, 50);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //add cube face 2
    ct = CATransform3DMakeTranslation(50, 0, 0);
    ct = CATransform3DRotate(ct, M_PI_2, 0, 1, 0);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //add cube face 3
    ct = CATransform3DMakeTranslation(0, -50, 0);
    ct = CATransform3DRotate(ct, M_PI_2, 1, 0, 0);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //add cube face 4
    ct = CATransform3DMakeTranslation(0, 50, 0);
    ct = CATransform3DRotate(ct, -M_PI_2, 1, 0, 0);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //add cube face 5
    ct = CATransform3DMakeTranslation(-50, 0, 0);
    ct = CATransform3DRotate(ct, -M_PI_2, 0, 1, 0);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //add cube face 6
    ct = CATransform3DMakeTranslation(0, 0, -50);
    ct = CATransform3DRotate(ct, M_PI, 0, 1, 0);
    [cube addSublayer:[self faceWithTransform:ct]];
    
    //center the cube layer within the container
    CGSize containerSize = _matrixContainerView.bounds.size;
    cube.position = CGPointMake(containerSize.width / 2.0, containerSize.height / 2.0);
    
    //apply the transform and return
    cube.transform = transform;
    return cube;
}

- (void)gestureChanged:(UIPanGestureRecognizer *)recognizer {
    //get the offset by subtracting the pan gesture
    //translation from the current bounds origin
    CGPoint offset = _scrollLayer.bounds.origin;
    offset.x -= [recognizer translationInView:self.view].x;
    offset.y -= [recognizer translationInView:self.view].y;
    
    //scroll the layer
    [(CAScrollLayer *)_scrollLayer scrollToPoint:offset];
    
    //reset the pan gesture translation
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)setUpBuffers {
    //set up frame buffer
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    //set up color render buffer
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);
    
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)tearDownBuffers {
    if (_framebuffer) {
        //delete framebuffer
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_colorRenderbuffer) {
        //delete color render buffer
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }
}

- (void)drawFrame {
    //bind framebuffer & set viewport
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _framebufferWidth, _framebufferHeight);
    
    //bind shader program
    [self.effect prepareToDraw];
    
    //clear the screen
    glClear(GL_COLOR_BUFFER_BIT); glClearColor(0.0, 0.0, 0.0, 1.0);
    
    //set up vertices
    GLfloat vertices[] = {
        -0.5f, -0.5f, -1.0f, 0.0f, 0.5f, -1.0f, 0.5f, -0.5f, -1.0f,
    };
    
    //set up colors
    GLfloat colors[] = {
        1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
    };
    
    //draw triangle
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(GLKVertexAttribColor,4, GL_FLOAT, GL_FALSE, 0, colors);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    //present render buffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)changeColor:(id)sender {
    //randomize the layer background color
    CGFloat red = arc4random() / (CGFloat)INT_MAX;
    CGFloat green = arc4random() / (CGFloat)INT_MAX;
    CGFloat blue = arc4random() / (CGFloat)INT_MAX;
    
    [CATransaction begin];
    // 设置完成块动作
    [CATransaction setCompletionBlock:^{
        _globalLayer.transform = CATransform3DRotate(_globalLayer.transform, M_PI_2, 0, 0, 1);
    }];
    // 设置隐式动画的时长
    [CATransaction setAnimationDuration:1.0f];
    _globalLayer.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0].CGColor;
    [CATransaction commit];
}

- (void)explicitChangeColor:(id)sender {
    //randomize the layer background color
    CGFloat red = arc4random() / (CGFloat)INT_MAX;
    CGFloat green = arc4random() / (CGFloat)INT_MAX;
    CGFloat blue = arc4random() / (CGFloat)INT_MAX;
    
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"backgroundColor";
    animation.toValue = (__bridge id)color.CGColor;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [_globalLayer addAnimation:animation forKey:nil];
}

- (void)fillModeChange:(UIButton *)button {
    [_globalLayer removeAnimationForKey:@"fillModeChange"];
    
    //randomize the layer background color
    CGFloat red = arc4random() / (CGFloat)INT_MAX;
    CGFloat green = arc4random() / (CGFloat)INT_MAX;
    CGFloat blue = arc4random() / (CGFloat)INT_MAX;
    NSArray *array = @[kCAFillModeForwards, kCAFillModeBackwards, kCAFillModeBoth, kCAFillModeRemoved];
    int random = arc4random_uniform(4);
    
    [button setTitle:[array objectAtIndex:random] forState:UIControlStateNormal];
    
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"backgroundColor";
    animation.toValue = (__bridge id)color.CGColor;
    animation.fillMode = [array objectAtIndex:random];
    [_globalLayer addAnimation:animation forKey:@"fillModeChange"];
}

- (void)keyframeChangeColor:(id)sender {
    //randomize the layer background color
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"backgroundColor";
    animation.values = @[(__bridge id)[UIColor redColor].CGColor,
                         (__bridge id)[UIColor blueColor].CGColor,
                         (__bridge id)[UIColor greenColor].CGColor,
                         (__bridge id)[UIColor redColor].CGColor
                         ];
    animation.duration = 4.f;
    [_globalLayer addAnimation:animation forKey:nil];
}

- (void)timingFunctionKeyframeChangeColor:(id)sender {
    //randomize the layer background color
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"backgroundColor";
    animation.values = @[(__bridge id)[UIColor redColor].CGColor,
                         (__bridge id)[UIColor blueColor].CGColor,
                         (__bridge id)[UIColor greenColor].CGColor,
                         (__bridge id)[UIColor redColor].CGColor
                         ];
    CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.timingFunctions = @[function, function, function];
    animation.duration = 4.f;
    [_globalLayer addAnimation:animation forKey:nil];
}

- (void)transitionAction:(id)sender {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [_globalLayer addAnimation:transition forKey:nil];
    NSUInteger index = [_colors indexOfObject:(__bridge id)_globalLayer.backgroundColor];
    index = ((index + 1) % [_colors count]);
    _globalLayer.backgroundColor = (__bridge CGColorRef _Nullable)([_colors objectAtIndex:index]);
}

- (void)customTransition:(id)sender {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.f);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIImageView *cover = [[UIImageView alloc] initWithFrame:self.view.bounds];
    cover.image = image;
    [self.view addSubview:cover];
    
    //randomize the layer background color
    CGFloat red = arc4random() / (CGFloat)INT_MAX;
    CGFloat green = arc4random() / (CGFloat)INT_MAX;
    CGFloat blue = arc4random() / (CGFloat)INT_MAX;
    
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    self.view.backgroundColor = color;
    
    //perform animation (anything you like)
    [UIView animateWithDuration:1.0 animations:^{
        //scale, rotate and fade the view
        CGAffineTransform transform = CGAffineTransformMakeScale(0.01, 0.01);
        transform = CGAffineTransformRotate(transform, M_PI_2);
        cover.transform = transform;
        cover.alpha = 0.0;
    } completion:^(BOOL finished) {
        //remove the cover view now we're finished with it
        [cover removeFromSuperview];
    }];
}

- (void)startAnimation:(id)sender {
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"transform.rotation";
    animation.byValue = @(M_PI * 2);
    animation.duration = 2.f;
    animation.delegate = self;
    [_globalLayer addAnimation:animation forKey:@"globalLayerAnimation"];
}

- (void)stopAnimation:(id)sender {
    [_globalLayer removeAnimationForKey:@"globalLayerAnimation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    //log that the animation stopped
    NSLog(@"The animation stopped (finished: %@)", flag? @"YES": @"NO");
}
- (IBAction)relativeTimeControlPlayAnimation:(id)sender {
    [_shipLayer removeAnimationForKey:@"relativeTimeAnimation"];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"position";
    animation.path = _bezierPath.CGPath;
    animation.timeOffset = self.timeOffsetSlider.value;
    animation.speed = self.speedSlider.value;
    animation.rotationMode = kCAAnimationRotateAuto;
    animation.duration = 4.f;
    animation.repeatCount = HUGE;
    animation.removedOnCompletion = YES;
    [_shipLayer addAnimation:animation forKey:@"relativeTimeAnimation"];
}

- (IBAction)updateSliders:(UISlider *)sender {
    self.timeOffsetLabel.text = [NSString stringWithFormat:@"timeOffset(%0.1f):", self.timeOffsetSlider.value / 10.f];
    self.speedLabel.text = [NSString stringWithFormat:@"speed(%0.1f):", self.speedSlider.value / 10.f];
}

- (void)pan:(UIPanGestureRecognizer *)pan {
    //get horizontal component of pan gesture
    CGFloat x = [pan translationInView:self.view].x;
    //convert from points to animation duration //using a reasonable scale factor
    x /= 200.0f;
    //update timeOffset and clamp result
    CFTimeInterval timeOffset = self.doorLayer.timeOffset;
    timeOffset = MIN(1.999, MAX(0.0, timeOffset - x));
    self.doorLayer.timeOffset = timeOffset;
    //reset pan gesture
    [pan setTranslation:CGPointZero inView:self.view];
}

- (void)adjustTimingFunction:(UIButton *)button {
    [_timingFunctionLayer removeAnimationForKey:@"timingFunction"];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[_timingFunctionKeyframeAnimation, _timingFunctionBasicAnimation];
    group.duration = 4.f;
    group.repeatCount = HUGE;
    switch (button.tag) {
        case 0:
            group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            _timimgFunctionLabel.text = kCAMediaTimingFunctionEaseIn;
            break;
        case 1:
            group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            _timimgFunctionLabel.text = kCAMediaTimingFunctionEaseOut;
            break;
        case 2:
            group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            _timimgFunctionLabel.text = kCAMediaTimingFunctionEaseInEaseOut;
            break;
        case 3:
            group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            _timimgFunctionLabel.text = kCAMediaTimingFunctionLinear;
            break;
    }
    group.removedOnCompletion = NO;
    [_timingFunctionLayer addAnimation:group forKey:@"timingFunction"];
    
}

float bounceEaseOut(float t) {
    if (t < 4/11.0) {
        return (121 * t * t)/16.0;
    } else if (t < 8/11.0) {
        return (363/40.0 * t * t) - (99/10.0 * t) + 17/5.0;
    } else if (t < 9/10.0) {
        return (4356/361.0 * t * t) - (35442/1805.0 * t) + 16061/1805.0;
    }
    return (54/5.0 * t * t) - (513/25.0 * t) + 268/25.0;
}

- (id)interpolateFromValue:(id)fromValue toValue:(id)toValue time:(float)time {
    if ([fromValue isKindOfClass:[NSValue class]]) {
        //get type
        const char *type = [fromValue objCType];
        if (strcmp(type, @encode(CGPoint)) == 0) {
            CGPoint from = [fromValue CGPointValue];
            CGPoint to = [toValue CGPointValue];
            CGPoint result = CGPointMake(interpolate(from.x, to.x, time), interpolate(from.y, to.y, time));
            return [NSValue valueWithCGPoint:result];
        }
    }
    //provide safe default implementation
    return (time < 0.5)? fromValue: toValue;
}

float interpolate(float from, float to, float time) {
    return (to - from) * time + from;
}
- (void)step:(NSTimer *)step {
    //update time offset
    self.timeOffset = MIN(self.timeOffset + 1/60.0, self.duration);
    //get normalized time offset (in range 0 - 1)
    float time = self.timeOffset / self.duration;
    //apply easing
    time = bounceEaseOut(time);
    //interpolate position
    id position = [self interpolateFromValue:self.fromValue
                                     toValue:self.toValue
                                        time:time];
    //move ball view to new position
    _ball.center = [position CGPointValue];
    //stop the timer if we've reached the end of the animation
    if (self.timeOffset >= self.duration) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)displayLinkStep:(CADisplayLink *)sender {
    //update time offset
    CFTimeInterval thisStep = CACurrentMediaTime();
    CFTimeInterval stepDuration = thisStep - self.lastStep;
    self.lastStep = thisStep;
    self.timeOffset = MIN(self.timeOffset + stepDuration, self.duration);
    float time = self.timeOffset / self.duration;
    //apply easing
    time = bounceEaseOut(time);
    //interpolate position
    id position = [self interpolateFromValue:self.fromValue
                                     toValue:self.toValue
                                        time:time];
    //move ball view to new position
    _ball.center = [position CGPointValue];
    //stop the timer if we've reached the end of the animation
    if (self.timeOffset >= self.duration) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

