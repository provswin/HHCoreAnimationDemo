# HHCoreAnimationDemo
HHCoreAnimationDemo是一个iOS Core Animation的Demo,是按照这本由Nick Lockwood著作的iOS Core Animation Advanced Techniques开发教材的结构进行代码编写的。

Demo按照我的理解进行略微调整后分为了以下章节(Nick Lockwood原本有15章节，Demo中只取了前11章的内容，后4章因为主要涉及到性能调优等方面的知识，它主要考验的是概念的理解和工具的使用，因此没写进Demo中来)：
## 1、CALayer的能力
    阴影
    圆角
    边框
    3D变换
    非矩形范围
    透明遮罩
    多级非线性动画（空）
    拉伸过滤
    组透明
## 2、寄宿图
    contents属性
      contentsGravity
      contentsScale
      maskToBounds
      contentsRect
      contentsCenter
    Custom Drawing
## 3、图形几何学
    布局
      frame、bounds、position
    anchorPoint锚点
    翻转的几何结构（geometryFlipped）
    Z坐标轴
    Hit Testing
## 4、变换
    仿射变换
    3D变换
    透视投影
    灭点
    sublayerTransform属性
    背面
    扁平化图层
    固体对象、光亮和阴影、点击事件
## 5、专用图层
    CAShapeLayer
    CATextLayer
    CATransformLayer
    CAGradientLayer
    CAReplicatorLayer、反射
    CAScrollLayer
    CATiledLayer
    CAEmitterLayer
    CAEAGLLayer
    AVPlayerLayer
## 6、隐式动画
    事务、完成块
    图层行为
    呈现层与模型层
## 7、显式动画
    属性动画
    关键帧动画
    虚拟属性
    动画组
    过渡
    自定义动画
    在动画过程中取消动画
## 8、图层时间
    持续和重复
    相对时间
    fillMode
    层级关系时间
      手动动画
## 9、缓冲
    动画速度
    UIView的动画缓冲
    缓冲和关键帧动画
    自定义缓冲函数
      三次贝塞尔曲线
        EaseIn
        Linear
        EaseOut
        EaseInEaseOut
      更加复杂的动画曲线
      流程自动化
## 10、基于定时器的动画
    定时帧
      NSTimer
      CADisplayLink
