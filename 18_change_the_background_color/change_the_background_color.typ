#set page(fill: rgb(35, 35, 38, 255), height: auto, paper: "a3")
#set text(fill: color.hsv(0deg, 0%, 90%, 100%), size: 22pt, font: "Microsoft YaHei")
#set raw(theme: "themes/Material-Theme.tmTheme")

= 1. 更改背景颜色
使用 ClearColor 资源来选择默认的背景颜色。此颜色将作为所有相机的默认颜色，除非被覆盖。

请注意，如果没有相机存在，窗口将是黑色的。你必须至少生成一个相机。
```Rust
.insert_resource(ClearColor(Color::Srgba(tailwind::GREEN_300)))
```

要覆盖默认颜色并为特定相机使用不同的颜色，可以使用 Camera 组件进行设置。
```Rust
commands.spawn(Camera3dBundle {
        camera: Camera {
            viewport: Some(Viewport {
                physical_position: UVec2::new(1280 / 2, 0),
                physical_size: UVec2::new(1280 / 2, 720 / 2),
                ..default()
            }),
            order: 1,
            clear_color: ClearColorConfig::None,
            ..default()
        },
        transform: Transform::from_xyz(0., 140., 106.).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    })
```

所有这些位置（特定相机上的组件，全局默认资源）都可以在运行时进行更改，Bevy 将使用你的新颜色。使用资源更改默认颜色将把新颜色应用于所有未指定自定义颜色的现有相机，而不仅仅是新生成的相机。
