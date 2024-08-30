#set page(fill: rgb(35, 35, 38, 255), height: auto, paper: "a3")
#set text(fill: color.hsv(0deg, 0%, 90%, 100%), size: 22pt, font: "Microsoft YaHei")
#set raw(theme: "themes/Material-Theme.tmTheme")

= 1. 2D 和 3D 场景
Bevy 在游戏世界中使用右手 Y 向上坐标系。为了保持一致，3D 和 2D 的坐标系相同。
- X 轴从左向右（正 X 指向右侧）
- Y 轴从下到上（正 Y 指向上）
- Z 轴从远到近（正 Z 指向你）

原点默认情况下在屏幕中心。

这是右手坐标系，你可以使用右手的手指来可视化 3 个轴：拇指 = X，食指 = Y，中指 = Z。

#image("images/handedness.png")

= 2. UI
对于 UI，Bevy 遵循与大多数其他 UI 工具包、Web 相同的约定。
- 原点位于屏幕左上角
- Y 轴指向下方
- X 轴从屏幕左边缘到屏幕右边缘
- Y 轴从屏幕上边缘到屏幕下边缘

= 3. 光标和屏幕
光标位置和任何其他窗口（屏幕空间）坐标遵循与 UI 相同的约定。