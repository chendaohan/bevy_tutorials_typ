#set page(fill: rgb(35, 35, 38, 255), height: auto, paper: "a3")
#set text(fill: color.hsv(0deg, 0%, 90%, 100%), size: 22pt, font: "Microsoft YaHei")
#set raw(theme: "themes/Material-Theme.tmTheme")

= 1. 辉光
“Bloom”效果会在亮光周围产生光晕。虽然这不是一种物理上准确的效果，但它受到了通过脏或不完美镜头看光线的启发。

Bloom在帮助感知非常亮的光线方面表现出色，尤其是在显示硬件不支持HDR输出时。你的显示器只能显示一定的最大亮度，因此Bloom是一种常见的艺术选择，用于传达比显示器能显示的亮度更高的光强。

Bloom在使用去饱和非常亮颜色的色调映射算法时效果最佳。Bevy的默认设置是一个不错的选择。

Bloom需要在你的相机上启用HDR模式。添加BloomSettings组件到相机以启用Bloom并配置效果。
```rust
commands.spawn((
    Camera3dBundle {
        camera: Camera {
            hdr: true,
            ..default()
        },
        ..default()
    },
    BloomSettings::NATURAL,
));
```

= 2. Bloom设置
Bevy提供了许多参数来调整Bloom效果的外观。

默认模式是“节能模式”，更接近真实光物理的行为。它试图模仿光散射的效果，而不人为地增加图像亮度。效果更加微妙和“自然”。

还有一种“加法模式”，它会使所有东西变亮，让人感觉亮光在“发光”不自然。这种效果在许多游戏中很常见，尤其是2000年代的老游戏。

Bevy提供了三种Bloom“预设”：
- NATURAL：节能模式，微妙，自然的外观。
- OLD_SCHOOL：“发光”效果，类似于老游戏的外观。
- SCREEN_BLUR：非常强烈的Bloom，使所有东西看起来模糊。

你也可以通过调整BloomSettings中的所有参数来创建完全自定义的配置。使用预设作为灵感。

以下是Bevy预设的设置：
```rs
fn toggle_bloom_presets(
    mut bloom_settings: Query<&mut BloomSettings>,
    keys: Res<ButtonInput<KeyCode>>,
) {
    let Ok(mut bloom_settings) = bloom_settings.get_single_mut() else {
        return;
    };
    if keys.just_pressed(KeyCode::Digit1) {
        *bloom_settings = BloomSettings::NATURAL;
    } else if keys.just_pressed(KeyCode::Digit2) {
        *bloom_settings = BloomSettings::OLD_SCHOOL;
    } else if keys.just_pressed(KeyCode::Digit3) {
        *bloom_settings = BloomSettings::SCREEN_BLUR;
    }
}
```