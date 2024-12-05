#set page(fill: rgb(35, 35, 38, 255), height: auto, paper: "a3")
#set text(fill: color.hsv(0deg, 0%, 100%, 100%), size: 18pt, font: "Microsoft YaHei")
#set raw(theme: "themes/Material-Theme.tmTheme")

= 1. （“必须组件”）必须组件
#image("images/required_component.svg", width: 50%)

首先，请系好安全带，因为“必须组件”是自 Bevy 首次发布以来对 Bevy API 表面的最深刻改进之一。

自 Bevy 创建以来，Bundle 一直是生成给定“类型”实体的抽象概念。Bundle 只是一个 Rust 类型，每个字段都是一个组件：
```rs
#[derive(Bundle, Default)]
struct PlayerBundle {
    player: Player,
    team: Team,
    sprite: Sprite,
    transform: Transform,
    global_transform: GlobalTransform,
    visibility: Visibility,
    inherited_visibility: InheritedVisibility,
    view_visibility: ViewVisibility,
}
```

每当需要生成一个新玩家时，开发人员会在一个实体上初始化并插入一个 PlayerBundle：
```rs
commands.spawn(PlayerBundle {
    player: Player { 
        name: "hello".into(),
        ..default()
    },
    team: Team::Blue,
    ..default()
});
```

这会插入 PlayerBundle 中的所有组件，包括那些未明确设置的组件。Bundle 概念是实用的（它已经使我们走到了今天），但它也远非理想：

+ 开发人员需要学习一整套全新的 API。想要生成 Player 实体的人需要知道 PlayerBundle 的存在。

+ 插入后 Bundle API 在运行时不存在……它们是开发人员需要考虑的额外生成概念。你不写 PlayerBundle 行为，而是写 Player 行为。

+ #[
Player 组件需要 PlayerBundle 中的组件才能作为 Player 运行。单独生成 Player 是可能的，但它可能（取决于实现）无法按预期运行。
#grid(
  columns: (3fr, 2fr),
  align()[
      ```rs
      commands.spawn((
          Player {
              name: "hello".into(),
              ..default()
          },
          team: Team::Blue,
          Sprite::default(),
          Transform::default(),
          GlobalTransform::default(),
          Visibility::default(),
          InheritedVisibility::default(),
          ViewVisibility::default(),
      ));
      ```
  ],
  align()[
      ```rs
      commands.spawn((
          Player {
            name: "hello".into(),
            ..default()
          },
          team: Team::Blue,
          Sprite::default(),
      ));
      ```
  ]
)
]

+ #[
  Bundle 总是“扁平的”（按惯例）。定义 Player 组件的人需要定义所有组件依赖项。Sprite 需要 Transform 和 Visibility，Transform 需要 GlobalTransform，Visibility 需要 InheritedVisibility 和 ViewVisibility。这种缺乏“依赖继承性”使得定义 Bundle 比需要的更难且更容易出错。它要求 API 的使用者对实现细节有深入的了解。当这些细节发生变化时，Bundle 的开发者需要注意并相应地更新 Bundle。支持嵌套 Bundle，但它们对用户来说是个麻烦，因此我们已经在上游 Bevy 包中禁止使用它们一段时间了。

  #image("images/player_structure.png")
]

+ PlayerBundle 实际上是由 Player 组件的需求定义的，但在生成时可能从未提到 Player 符号。例如：```rs commands.spawn(PlayerBundle::default())```。鉴于 Player 是“驱动概念”，这很奇怪。

+ Bundle 对 API 引入了显著的“停顿”。注意上面的 player: Player 和 team: Team。

+ Bundle 引入了额外的（可以说是过多的）嵌套和 ..default() 使用。

上述每一点都对日常使用 Bevy 的有巨大影响。在 Bevy 0.15 中，我们引入了“必须组件”，通过从根本上重新思考这一切解决了这些问题。

“必须组件”是我们“下一代场景/UI系统”工作的第一步，旨在使 Bevy 成为一流的应用/场景/UI 开发框架。“必须组件”自身就已经是对 Bevy 开发者生活的直接改善，但它们也为使 Bevy 即将推出的下一代场景系统（以及即将推出的 Bevy 编辑器）成为真正特别的东西奠定了基础。

= 2. 它们是什么？
“必须组件”使开发者能够定义给定组件需要哪些组件：
```rs
#[derive(Component, Default)]
#[require(Team, Sprite)]
struct Player {
    name: String,
}
```

当插入 Player 组件时，其“必须组件”和那些组件所需的组件也会自动插入！
```rs
commands.spawn(Player::default());
```

上面的代码会自动插入 Team 和 Sprite。Sprite 需要 Transform 和 Visibility，所以这些也会自动插入。同样，Transform 需要 GlobalTransform 和 Visibility 需要 InheritedVisibility 和 ViewVisibility。

这段代码产生的结果与上一节中的 PlayerBundle 代码相同：
```rs
commands.spawn((
    Player {
        name: "hello".into(),
        ..default()
    },
    Team::Blue,
))
```

更好吧？Player 类型更容易定义，不易出错，生成它的代码也更少，且更易读。

= 3. 效率
我们以一种使“必须组件”实际上“免费”的方式实现了它们：

+ 只有在调用者没有手动插入它们时才初始化和插入 “必须组件”。没有冗余！

+ “必须组件”与普通组件一起插入，这意味着（对于你们这些 ECS 爱好者来说）没有额外的原型变化或表移动。从这个角度来看，“必须组件” 版本的 Player 示例与手动定义所有组件的 PlayerBundle 方法相同。

+ “必须组件”缓存在原型图上，这意味着计算插入给定类型所需的组件只发生一次。

= 4. 组件初始化
默认情况下，“必须组件” 将使用组件的默认实现（如果不存在，将无法编译）：
```rs
#[derive(Component)]
#[require(Team)] // Team::Red 是默认值
struct Player {
    name: String,
}

#[derive(Component, Default)]
enum Team {
    #[default]
    Red,
    Blue,
}
```

这可以通过传递一个返回组件的函数来覆盖：
```rs
#[derive(Component)]
#[require(Team(blue_team))]
struct Player {
    name: String,
}

fn blue_team() -> Team {
    Team::Blue
}
```

为了节省空间，你还可以将闭包直接传递给 require：
```rs
#[derive(Component)]
#[require(Team(|| Team::Blue))]
struct Player {
    name: String,
}
```

= 5. 这不是有点像继承吗？
“必须组件” 可以被认为是一种继承形式。但它显然不是传统的面向对象继承。相反，它是“通过组合继承”。一个 Button Widget 可以（并且应该）需要 Node 使其成为“UI 节点”。在某种程度上，一个 Button“是一个”Node，就像在传统继承中一样。但与传统继承不同的是：

+ 它被表达为“具有”关系，而不是“是”关系。

+ Button 和 Node 仍然是两个完全独立的类型（具有各自的数据），你可以在 ECS 中分别查询它们。

+ 一个 Button 可以在 Node 之外需要更多组件。你不必局限于标准面向对象继承。组合仍然是主导模式。

+ 你不需要要求组件来添加它们。你仍然可以在生成过程中附加任何额外的组件，以正常的“组合风格”添加行为。

= 6. Bundle 会发生什么变化？
Bundle 特性将继续存在，并且它仍然是插入 API 的基本构建块（组件的元组仍然实现 Bundle）。开发人员仍然可以使用 Bundle 派生定义自己的自定义 Bundle。Bundle 与“必须组件”配合得很好，所以你可以同时使用它们。

话虽如此，从 Bevy 0.15 开始，我们已经弃用了所有内置的 Bundle，如 SpriteBundle、NodeBundle、PbrBundle 等，转而使用 “必须组件”。一般来说，“必须组件” 现在是首选的/惯用的方法。我们鼓励 Bevy 插件和应用开发人员将他们的 Bundle 转换为 “必须组件”。

= 7. 将 Bevy 移植到 “必须组件”
如前所述，所有内置的 Bevy Bundle 已被弃用，转而使用 “必须组件”。我们还进行了 API 更改以利用这一新范式。这确实意味着在某些地方会有破坏性的变化，但这些变化如此之好，我们认为人们不会抱怨太多 :

总体而言，我们正在朝着我们的下一代场景/UI 文档中指定的方向前进。一些通用设计指南：

+ 在生成实体时，一般应该有一个“驱动概念”组件。当实现一个新的实体类型/行为时，为其命名一个概念名称……那就是你的“驱动组件”的名称（例如：“玩家”概念是一个 Player 组件）。该组件应需要执行其功能所需的任何附加组件。

+ #[
  人们在生成时应该直接考虑组件及其字段。更喜欢直接在“概念组件”上使用组件字段作为该功能的“公共 API”。
  #grid(
    columns: (1fr, 1fr),
    [
      ```rs
      commands.spawn(Player {
          name: "hello".into(),    
          ..default()
      });
      ```
    ],
    [
      ```rs
      commands.spawn((
        Player::default(),
        Name("hello".into()),
      ));
      ```
    ]
  )
]

+ 优先使用简单的 API/不要过度组件化。默认情况下，如果你需要向概念添加新属性，只需将它们作为字段添加到该概念的组件中。只有在有充分理由时才分解出新的组件/概念，该理由应由用户体验或性能驱动（高度重视用户体验）。如果给定“概念”（例如：一个 Sprite）被分解成 10 个组件，用户将难以理解和使用。

+ 不要直接使用资产句柄作为组件，而是定义包含必要句柄的新组件。直接将原始资产句柄作为组件存在各种问题（一个大问题是你不能为它们定义特定上下文的 “必须组件”），因此我们移除了 Handle\<T> 的组件实现，以鼓励（好吧……是强制）人们采用这种模式。

= 8. UI
Bevy UI 从“必须组件”中受益匪浅。UI 节点需要各种组件才能运行，现在所有这些要求都在 Node 上集中。定义一个新的 UI 节点类型现在只需将 \#[require(Node)] 添加到你的组件中。
```rs
#[derive(Component)]
#[require(Node)]
struct MyNode;

commands.spawn(MyNode);
```

Style 组件字段已被移动到 Node 中。Style 从来都不是一个全面的“样式表”，而只是所有 UI 节点共享的属性集合。一个“真正的”ECS 样式系统将跨组件

如Node、Button等）样式属性。我们确实计划构建一个真正的样式系统。所有“计算”节点属性（如布局后的节点大小）都已移至ComputedNode组件。

这些更改使得在Bevy中生成UI节点更加清晰简洁：
```rs
commands.spawn(Node {
    width: Val::Px(100.),
    ..default()
});
```

与之前相比：
```rs
commands.spawn(NodeBundle {
    style: Style {
        width: Val::Px(100.),
        ..default()
    },
    ..default()
})
```

UI组件如Button、ImageNode（以前是UiImage）和Text现在需要Node。特别是，Text已被重新设计，更容易使用且更加以组件为驱动（我们将在下一节中详细介绍）：
```rs
commands.spawn(Text::new("Hello there!"));
```

MaterialNode\<M: UiMaterial>现在是一个适用于“UI材质着色器”的正确组件，并且它也需要Node：
```rs
commands.spawn(MaterialNode(my_material));
```

= 9. 文本
Bevy的文字API已被重新设计为更简单和更加组件驱动。现在仍有两个主要的文字组件：Text（UI文字组件）和Text2d（世界空间2D文字组件）。

首先，这些主要组件现在只是一个字符串新类型：
```rs
commands.spawn(Text("hello".to_string()))
commands.spawn(Text::new("hello"))
commands.spawn(Text2d("hello".to_string()))
commands.spawn(Text2d::new("hello"))
```

生成这些组件中的一个，你就拥有了文字！这两个组件现在需要以下组件：

+ TextFont：配置字体/大小

+ TextColor：配置颜色

+ TextLayout：配置文字的布局方式

Text，即UI组件，还需要Node，因为它是一个节点。同样，Text2d需要Transform，因为它定位在世界空间中。

Text和Text2d都是独立的“文本块”。这些顶级文本组件也会贡献一个单独的“文本片段”，该片段会被添加到“文本块”中。如果你需要带有多种颜色/字体/大小的“富文本”，可以将TextSpan实体作为Text或Text2d的子节点添加。TextSpan使用相同的TextFont和TextLayout组件来配置文本。每个TextSpan都会将其文本片段添加到其父文本中：
```rs
// 这个 Text UI 节点将 渲染 hello world!，而且 hello 是红色的，blue 是蓝色的
commands.spawn(Text::default())
    .with_child((
        TextSpan::new("hello"),
        TextColor::from(RED),
    ))
    .with_child((
        TextSpan::new(" world!"),
        TextColor::from(BLUE),
    ));
```

这会产生与在顶级Text组件上使用“默认”文本片段相同的输出：
```rs
commands.spawn((
    Text::new("hello"),
    TextColor::from(RED),
))
.with_child((
    TextSpan::new(" world!"),
    TextColor::from(BLUE),
));
```

这种“基于实体”的文本片段方法取代了以前Bevy版本中使用的“内部片段数组”方法。这样做带来了显著的好处。首先，它让你可以使用普通的Bevy ECS工具，如标记组件和查询，来标记一个文本片段并直接访问它。这比使用难以猜测且内容变化时不稳定的数组索引要容易（且更具弹性）：
```rs
#[derive(Component)]
struct NameText;

commands.spawn(Text::new("Name: "))
    .with_child((
        TextSpan::new("Unknown"),
        NameText, 
    ));

fn set_name(mut names: Query<&mut TextSpan, With<NameText>>) {
    names.single_mut().0 = "George".to_string();
}
```

作为实体的文本片段与Bevy场景（包括即将推出的下一代场景/UI系统）更好地配合，并且可以很好地与现有工具（如实体检查器、动画系统、计时器等）集成。

= 10. 精灵
精灵（Sprites）基本保持不变。除了“必须组件”（精灵现在需要Transform和Visibility）之外，我们还进行了一些组件整合。TextureAtlas组件现在是Sprite::texture_atlas的一个可选字段。同样，ImageScaleMode组件现在是Sprite::image_mode字段。生成精灵现在非常简单！
```rs
commands.spawn(Sprite {
    image: assets.load("player.png"),
    ..default()
});
```

= 11. 变换
Transform现在需要GlobalTransform。如果你希望你的实体具有“层次变换”，请需要Transform（这会添加GlobalTransform）。如果你只希望你的实体具有“扁平”的全局变换，请需要GlobalTransform。

大多数意图存在于世界空间中的Bevy组件现在需要Transform。

= 12. 可见性
Visibility组件现在需要InheritedVisibility和ViewVisibility，这意味着如果你希望你的实体可见，现在只需需要Visibility。Bevy内置的“可见”组件（如精灵）需要Visibility。

= 13. 摄像机
Camera2d和Camera3d组件现在各自需要Camera。Camera需要各种摄像机组件（如Frustum、Transform等）。这意味着你可以这样生成2D或3D摄像机：
```rs
commands.spawn(Camera2d);
commands.spawn(Camera2d::default());

commands.spawn(Camera3d::default());
```

Camera2d和Camera3d还需要设置相关默认渲染图和启用2D和3D上下文相关默认渲染功能的组件（分别）。

当然，你也可以显式设置其他组件的值：
```rs
commands.spawn((
    Camera3d::default(),
    Camera {
        hdr: true,
        ..default()
    },
    Transform {
        translation: Vec3::new(1.0, 2.0, 3.0),
        ..default()
    },
));
```

Bevy有许多启用“摄像机渲染功能”的组件：MotionBlur、TemporalAntiAliasing、ScreenSpaceAmbientOcclusion和ScreenSpaceReflections。这些摄像机功能中的一些依赖于其他摄像机功能组件才能运行。这些依赖关系现在使用“必须组件”表示并强制执行。例如，MotionBlur现在需要DepthPrepass和MotionVectorPrepass。这使得启用摄像机功能更加容易！
```rs
commands.spawn((
    Camera3d::default(),
    MotionBlur,
))
```

MotionBlur、TemporalAntiAliasing、ScreenSpaceAmbientOcclusion、ScreenSpaceReflections 这些组件不是 Camera3d 的“必须组件”，而是 Camera3d 的附加组件。Camera 是 Camera3d 的必须组件，没有 Camera 这个组件，Camera3d 就失去了相机的功能，而附加组件是在原来的相机功能的基础上添加更多功能，失去了这些附加组件，相机还是相机。

Bevy 的组件现在只有必须关系的约束，未来会添加更多的关系约束，就比如上面说的附加关系。

#image("images/more_relations.png")

= 14. 网格
旧的网格方法依赖于直接添加Handle\<Mesh>和Handle\<M: Material>组件（通过PbrBundle和MaterialMeshBundle），这两者都不兼容必须组件。

在Bevy 0.15中，你可以使用Mesh3d和MeshMaterial3d\<M: Material>来渲染3D中的网格：
```rs
commands.spawn((
    Mesh3d(mesh),
    MeshMaterial3d(material),
));
```

Mesh3d需要Transform和Visibility。

还有2D对应物：
```rs
commands.spawn((
    Mesh2d(mesh),
    MeshMaterial2d(material),
));
```

= 15. Meshlet
Bevy的“虚拟几何体”实现（类似于Nanite），也已移植。它使用与Mesh3d和Mesh2d相同的模式：
```rs
commands.spawn((
    MeshletMesh3d(mesh),
    MeshMaterial3d(material),
));
```
= 16. 灯光
灯光端口未对组件结构进行重大更改。所有空间光源类型（PointLight，DirectionalLight，SpotLight）现在都需要变换（Transform）和可见性（Visibility），每个光源组件都需要相关的光源特定配置组件（例如：PointLight 需要 CubemapFrusta 和 CubemapVisibleEntities）。

现在生成特定类型的光源就像这样简单：
```rs
commands.spawn(PointLight {
    intensity: 1000.0,
    ..default()
});
```

LightProbe组件现在也需要Transform和Visibility。

= 17. 体积雾
FogVolume组件现在需要Transform和Visibility，这意味着你现在可以这样添加体积雾：
```rs
commands.spawn(FogVolume {
    density_factor: 0.2,
    ..default()
});
```
= 18. 场景
场景以前使用原始的 Handle\<Scene> 组件，通过 SceneBundle 生成。Bevy 0.15 引入了 SceneRoot 组件，该组件包裹了场景句柄，并且需要 Transform 和 Visibility 组件。
```rs
commands.spawn(SceneRoot(some_scene));
```

同样，现在有了 DynamicSceneRoot，它与 SceneRoot 完全相同，但它包裹的是 Handle\<DynamicScene> 而不是 Handle\<Scene>。

= 19. 音频
音频也使用了通过AudioBundle生成的原始Handle\<AudioSource>。我们添加了一个新的AudioPlayer组件，当生成时会触发音频播放：
```rs
command.spawn(AudioPlayer(assets.load("music.mp3")));
```

AudioPlayer需要PlaybackSettings组件。

来自任意Decodable特征实现的非标准音频可以使用AudioSourcePlayer组件，该组件也需要PlaybackSettings。

= 20. IDE 集成
“必须组件”与Rust Analyzer配合得很好。你可以“转到定义”/按F12查看必须组件在代码中的定义位置。

= 21. 运行时必须组件
在某些情况下，没有直接控制组件的开发者可能希望在组件类型通过\#[require(Thing)]直接提供的组件之上添加额外的必须组件。这是支持的！
```rs
app.register_required_components::<Bird, Wings>();

app.register_required_components_with::<Wings, FlapSpeed>(|| FlapSpeed::from_duration(1.0 / 80.0));
```

请注意，只允许添加必须组件。从你不拥有的类型中删除必须组件是明确不支持的，因为这可能会使上游的假设无效。

一般来说，这用于非常具体的、有针对性的上下文，例如物理插件为其不控制的核心类型添加额外元数据。添加一个新组件要求可能会改变应用程序的性能特性或以意想不到的方式破坏它。不确定时，不要这样做！

= 22. 组件是“纯数据”还是“数据+行为”
Bevy 现在支持给你不拥有的组件添加必须组件，但却不支持从你不拥有的组件中删除必须组件。

关于要不要支持后一项，在社区中有过争议。

+ 认为组件是“纯数据”的社区成员觉得应该支持“删除必须组件”，因为如果不能删除必须组件，会损害组件的灵活性。

+ 而认为组件是“数据+行为”的社区成员觉得组件自由过了头，要限制组件的灵活性。比如我们写了一个控制玩家行为的系统，如果支持“删除必须组件”，我们在查询玩家时就要写非常复杂的过滤条件，以确保我们查到的实体有构成玩家所需的全部组件。如果不支持“删除必须组件”，那么我们只要判断查到的实体里有没有玩家的驱动组件 Player，如果有就它就是玩家。

Bevy 创始人 Cart 是坚定的“数据+行为”派的人，最后“数据+行为”派获得了最后的胜利。