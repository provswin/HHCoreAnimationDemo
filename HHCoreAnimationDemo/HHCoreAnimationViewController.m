//
//  HHCoreAnimationViewController.m
//  HHCoreAnimationDemo
//
//  Created by 深圳市秀软科技有限公司 on 06/02/2018.
//  Copyright © 2018 showsoft. All rights reserved.
//

#import "HHCoreAnimationViewController.h"
#import "HHCoreAnimationContentViewController.h"
#import "HHCoreAnimationHierarchyModel.h"

@interface HHCoreAnimationViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSArray *data;

@end

@implementation HHCoreAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _data = @[
              // 0
              @[HierarchyModelMake(@"CALayer的能力", YES, @1), HierarchyModelMake(@"寄宿图", YES, @2), HierarchyModelMake(@"图形几何学", YES, @4), HierarchyModelMake(@"变换", YES, @6), HierarchyModelMake(@"专用图层", YES, @7), HierarchyModelMake(@"隐式动画", YES, @8), HierarchyModelMake(@"显示动画", YES, @9), HierarchyModelMake(@"图层时间", YES, @10), HierarchyModelMake(@"缓冲", YES, @12), HierarchyModelMake(@"基于定时器的动画", YES, @15)],
              // 1
              @[HierarchyModelNoChildModelMake(@"阴影"), HierarchyModelNoChildModelMake(@"圆角"), HierarchyModelNoChildModelMake(@"边框"), HierarchyModelNoChildModelMake(@"3D变换"), HierarchyModelNoChildModelMake(@"非矩形范围"), HierarchyModelNoChildModelMake(@"透明遮罩"), HierarchyModelNoChildModelMake(@"多级非线性动画"), HierarchyModelNoChildModelMake(@"拉伸过滤"), HierarchyModelNoChildModelMake(@"组透明")],
              // 2
              @[HierarchyModelMake(@"contents属性", YES, @3), HierarchyModelNoChildModelMake(@"Custom Drawing")],
              // 3
              @[HierarchyModelNoChildModelMake(@"contentGravity"), HierarchyModelNoChildModelMake(@"contentsScale"), HierarchyModelNoChildModelMake(@"maskToBounds"), HierarchyModelNoChildModelMake(@"contentsRect"), HierarchyModelNoChildModelMake(@"contentsCenter")],
              // 4
              @[HierarchyModelMake(@"布局", YES, @5), HierarchyModelNoChildModelMake(@"anchorPoint锚点"), HierarchyModelNoChildModelMake(@"翻转的几何结构（geometryFlipped）"), HierarchyModelNoChildModelMake(@"Z坐标轴"), HierarchyModelNoChildModelMake(@"Hit Testing")],
              // 5
              @[HierarchyModelNoChildModelMake(@"frame、bounds、position")],
              // 6
              @[HierarchyModelNoChildModelMake(@"仿射变换"), HierarchyModelNoChildModelMake(@"3D变换"), HierarchyModelNoChildModelMake(@"透视投影"), HierarchyModelNoChildModelMake(@"灭点"), HierarchyModelNoChildModelMake(@"sublayerTransform属性"), HierarchyModelNoChildModelMake(@"背面"), HierarchyModelNoChildModelMake(@"扁平化图层"), HierarchyModelNoChildModelMake(@"固体对象、光亮和阴影、点击事件")],
              // 7
              @[HierarchyModelNoChildModelMake(@"CAShapeLayer"), HierarchyModelNoChildModelMake(@"CATextLayer"), HierarchyModelNoChildModelMake(@"CATransformLayer"), HierarchyModelNoChildModelMake(@"CAGradientLayer"), HierarchyModelNoChildModelMake(@"CAReplicatorLayer、反射"), HierarchyModelNoChildModelMake(@"CAScrollLayer"), HierarchyModelNoChildModelMake(@"CATiledLayer"), HierarchyModelNoChildModelMake(@"CAEmitterLayer"), HierarchyModelNoChildModelMake(@"CAEAGLLayer"), HierarchyModelNoChildModelMake(@"AVPlayerLayer")],
              // 8
              @[HierarchyModelNoChildModelMake(@"事务、完成块"), HierarchyModelNoChildModelMake(@"图层行为"), HierarchyModelNoChildModelMake(@"呈现层与模型层")],
              // 9
              @[HierarchyModelNoChildModelMake(@"属性动画"), HierarchyModelNoChildModelMake(@"关键帧动画"), HierarchyModelNoChildModelMake(@"虚拟属性"), HierarchyModelNoChildModelMake(@"动画组"), HierarchyModelNoChildModelMake(@"过渡"), HierarchyModelNoChildModelMake(@"自定义动画"), HierarchyModelNoChildModelMake(@"在动画过程中取消动画")],
              // 10
              @[HierarchyModelNoChildModelMake(@"持续和重复"), HierarchyModelNoChildModelMake(@"相对时间"), HierarchyModelNoChildModelMake(@"fillMode"), HierarchyModelMake(@"层级关系时间", YES, @11)],
              // 11
              @[HierarchyModelNoChildModelMake(@"手动动画")],
              // 12
              @[HierarchyModelNoChildModelMake(@"动画速度"), HierarchyModelNoChildModelMake(@"UIView的动画缓冲"), HierarchyModelNoChildModelMake(@"缓冲和关键帧动画"), HierarchyModelMake(@"自定义缓冲函数", YES, @13)],
              // 13
              @[HierarchyModelMake(@"三次贝塞尔曲线", YES, @14), HierarchyModelNoChildModelMake(@"更加复杂的动画曲线"), HierarchyModelNoChildModelMake(@"流程自动化")],
              // 14
              @[HierarchyModelNoChildModelMake(@"EaseIn"), HierarchyModelNoChildModelMake(@"Linear"), HierarchyModelNoChildModelMake(@"EaseOut"), HierarchyModelNoChildModelMake(@"EaseInEaseOut")],
              // 15
              @[HierarchyModelMake(@"定时帧", YES, @16)],
              // 16
              @[HierarchyModelNoChildModelMake(@"NSTimer"), HierarchyModelNoChildModelMake(@"CADisplayLink")]
              ];
    
    if (_hierarchy == 0) {
        self.title = @"CoreAnimation";
    } else {
        self.title = _titleString;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) style:UITableViewStylePlain];
    
    _tableView.delegate = self;
    
    _tableView.dataSource = self;
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"cell%lu", (unsigned long)_hierarchy]];
    
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"cell%lu", (unsigned long)_hierarchy]];
    HHCoreAnimationHierarchyModel *model = [[_data objectAtIndex:_hierarchy] objectAtIndex:indexPath.row];
    cell.textLabel.text = model.name;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_data objectAtIndex:_hierarchy] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HHCoreAnimationHierarchyModel *model = [[_data objectAtIndex:_hierarchy] objectAtIndex:indexPath.row];
    if (model.hasChild) {
        HHCoreAnimationViewController *vc = [[HHCoreAnimationViewController alloc] init];
        vc.titleString = model.name;
        vc.hierarchy = [model.childIndex integerValue];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        HHCoreAnimationContentViewController *content = [[HHCoreAnimationContentViewController alloc] init];
        content.name = model.name;
        [self.navigationController pushViewController:content animated:YES];
    }
}
@end

