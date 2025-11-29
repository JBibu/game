# PS1 Game Jam Project

A retro-styled game using authentic PlayStation 1 graphics rendering.

## Features

- PSX-style rendering with vertex jitter and affine texture mapping
- Color dithering post-processing effect
- Low-resolution pixelated rendering (420x360)
- Retro aesthetic using godot-psx shaders

## Project Structure

```
ps-1/
├── Assets/
│   ├── Models/           # 3D models
│   ├── Shaders/          # PSX shader files
│   └── Textures/         # Texture files
├── Audio/
│   ├── Music/            # Background music
│   └── SFX/              # Sound effects
├── Fonts/                # Font files
├── Levels/               # Level scenes
├── Materials/            # Material resources
├── Scenes/               # Game scenes
├── Scripts/              # GDScript files
└── UI/                   # User interface elements
```

## PSX Shaders

This project uses [godot-psx](https://github.com/AnalogFeelings/godot-psx) shaders:

- **psx_lit.gdshader** - Lit shader with vertex jitter and affine mapping
- **psx_unlit.gdshader** - Unlit version
- **psx_dither.gdshader** - Color depth reduction with dithering
- **psx_fade.gdshader** - Fade to black/white effect

## Credits

- PSX shaders by [Analog Feelings](https://github.com/AnalogFeelings)
- Textures from SBS Photorealistic Texture Pack

## License

MIT License (for PSX shaders)
