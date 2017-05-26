# WG24HPicker
未来24小时时间选择器

### 引言
> 最近公司有个需求, 要做一个`PickerView`三级联动的菜单, 要求实现可供用户选择未来24小时内任一时间点的功能, 最小可选单位为分. 其中第一列为今天或明天, 第二列为时, 第三列为分. 由于前列时间点的选择会影响后列时间点的可选范围, 这就涉及到联动问题. 网上的联动例子也有不少, 不过感觉大都是同一个例子, 都是说的城市, 而且只是二级联动(虽然三级联动也大同小异), 毕竟这个案例自己也是花了点心思, 希望大家可以赏面来看看, 如果有刚好要做类似功能的朋友, 也希望能对你们有所帮助. 这是最终效果图:
![1.gif](http://upload-images.jianshu.io/upload_images/2404215-e0d9cb1f33f84933.gif?imageMogr2/auto-orient/strip)

### 正文
> 主要想就项目过程中遇到的几个点说一下自己的想法:

> 1. 关于时间数据源
这个问题确实有点恶心的, 第一列只要展示`今天`和`明天`, 没问题; 
第二列问题也不太大, 就2组数据, 根据第一列的选择情况分别展示即可, 不过这里需要注意的是, 如果当前时间为59分时, 当前的时就不需要展示了, 因为第三列已经没有可供用户选择的范围了, 比如说现在是10时59分, 那么10时就不需要显示了, 应该直接跳到11时; 
最恶心的是第三列, 有3组数据, 需要根据前2列的选中状态来共同决定, 而且如果当前时间为59分时, 还要注意数据源的切换.

> 2. 关于联动的崩溃
这是个非常经典的问题, 网上很多地方也有说到, 几乎是做过联动的朋友都会遇到的, 就是在同时滑动2列数据的时候很容易出现数组访问越界的情况, 然后就悲剧了. 具体的原因是在数据源方法`- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;①`中使用了方法`- (NSInteger)selectedRowInComponent:(NSInteger)component;②`去获取当前所选元素的下标, 然后去对应的数组获取第`row`个下标的元素, 乍看之下感觉没什么问题, 这也是为什么这么多人都会遇到这个崩溃情况的原因, 那究竟是哪里出问题了呢? 原因在于代理方法`- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;③`的调用时机. 这个方法是在某列滚动停止后就会调用, 我们一般会在此方法中刷新对应其它列的数据, 实现联动功能. 那么问题来了, 上面的数据源方法`①`调用的频率是很高的, 在滑动过程中会不停地调用, 冲突就来了.
举个例子来说, 比如现在是20时30分, 当第一列选择今天时, 第二列的数据只有20-23这4个元素可选. 而当第一列选择明天时, 第二列的数据就多了, 有00-20共21个元素可选. 如果此时第一列选择明天, 第二列正在往下标大的元素方向滑动进行中, 然后第一列突然向今天滑去, 在滑到今天且准备停止时, 代理方法`③`还未能调用, 也就是第二列的数据未能刷新数据源, 说白了就是未能重新走一次数据源方法`- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;④`来重新获取需要展示的元素个数, 也就是说进去数据源方法`①`中的参数`row`还可以达到20这个下标, 而此时在数据源方法`①`中调用方法`②`获取第一列被选中的元素下标时却能获取到被选中的是今天这个下标, 也就是说会从20-23这4个元素中去拿值, 在只有4个元素的数组中取下标为20的值, 就造成崩溃了.
可能说得有点乱, 简单来说就是方法`②`是直接拿到当前被选中的元素下标, 而代理方法`③`则是在某一列停止滚动时才会被调用, 所以这里出现了数据没匹对上的情况. 解决方法就是满足调用次数少的一方, 也就是增加2个全局属性来记录当前被选中的元素下标, 当然是在代理方法`③`中进行更新赋值操作, 并且要在刷新其它列数据的命令之前, 取数据源时直接通过这2个全局属性替换掉原来的用方法`②`获取当前被选中元素下标的做法:
![2.png](http://upload-images.jianshu.io/upload_images/2404215-4a14b95e083a5e47.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![3.png](http://upload-images.jianshu.io/upload_images/2404215-941f73fb131ce5f7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![4.png](http://upload-images.jianshu.io/upload_images/2404215-1f256706ec7405dd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> 3. 输出所选结果
来到这里其实已经没有什么问题了, 想提一下的是可能通过上面2中的论述有人会觉得方法`②`很可怕, 拿到的东西不准不敢用了, 其实并不是拿不准, 反而是拿得非常精准, 只是用在了不应该用的地方, 而在代理方法`③`中
输出结果的时候就非用它不可了, 因为无论动哪一列都需要把整个结果输出. 
![5.png](http://upload-images.jianshu.io/upload_images/2404215-ef43b642cfb3030f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 后记
> 其实在做这个案例时我还想到了其它奇奇怪怪的解决方案, 比如在数据源方法`①`中刷新某一列的数据, 或者在数据源方法`①`中输出结果等等, 不过这些做法都太影响性能了, 还有可能会产生其它BUG, 最后觉得还是目前这样的处理方法比较可行, 也希望大家有好的想法可以一起分享指正, 谢谢~
