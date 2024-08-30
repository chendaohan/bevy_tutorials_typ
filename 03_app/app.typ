#set page(fill: rgb(35, 35, 38, 255), height: auto, paper: "a3")
#set text(fill: color.hsv(0deg, 0%, 90%, 100%), size: 22pt, font: "Microsoft YaHei")
#set raw(theme: "themes/Material-Theme.tmTheme")

= 1. App
App 是你定义构成项目的所有事物的方式：插件、系统（运行条件、排序、系统集）、事件类型、状态、调度等。
```Rust
App::new()
  .add_plugins(MinimalPlugins)
  .register_type::<MyReflectCompoent>()
  .register_type_data::<MyReflectCompoent, ReflectMyReflectTrait>()
  .init_state::<GameState>()
  .insert_state(GameState::Start)
  .init_resource::<MyResource>()
  .insert_resource(InsertMyResource { field_1: 0., field_2: 0 })
  .add_event::<MyEvent>()
  .configure_sets(Startup, MySystemSet)
  .add_systems(Startup, system.in_set(MySystemSet))
  .run()
```

= 2. 内置 Bevy 功能
Bevy 游戏引擎的功能被表示为插件，根据不同的场景将内置插件合成了插件组。
- #[
  ```Rust DefaultPlugins```：如果你正在制作完整的游戏/应用。

  有 日志插件（LogPlugin）、任务池插件（TaskPoolPlugin）、窗口插件（WindowPlugin）、资产插件（AssetPlugin）、窗口管理插件（WinitPlugin）、渲染插件（RenderPlugin）、图片插件（ImagePlugin）、Pbr 插件（PbrPlugin）、Gltf 插件（GltfPlugin）、音频插件（AudioPlugin）等提供配置选项的插件。
]
- #[
  ```Rust MinimalPlugins```：用于类似无头服务器的东西。

  有 任务池插件（TaskPoolPlugin）、类型注册插件（TypeRegistrationPlugin）、帧计数插件（FrameCountPlugin）、时间插件（TimePlugin）、时间表运行器插件（SheduleRunnerPlugin）、CI 测试插件（CiTestingPlugin）全部插件。
]