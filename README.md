# show_wallpapers.wezterm
- Shows your wallpapers in WezTerm and lets you toggle their change forward and backward.
![toggle_wallpapers](images/toggle_wallpapers.gif)

- Lets you brighten and dim the wallpaper.
![toggle_brightness](images/toggle_brightness.gif)

## Usage

```lua
local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Add these lines (to use plugin and its default options):
swp = wezterm.plugin.require("https://github.com/sunbearc22/show_wallpapers.wezterm.git")
swp.apply_to_config(config, {})

return config
```

## Options

**Default options**

```lua
swp = wezterm.plugin.require("https://github.com/sunbearc22/show_wallpapers.wezterm.git")
swp.apply_to_config(config,
  {
    directory = "$HOME/Pictures/Wallpapers",        -- Wallpapers directory
    brightness = 0.06,                              -- Wallpaper initial brightness at 6%.
    toggle_forward_key = "b",                       -- see key bindings
    toggle_forward_mods = "SUPER",                  -- see key bindings
    toggle_backward_key = "B",                      -- see key bindings
    toggle_backward_mods = "SUPER|SHIFT",           -- see key bindings
    increase_brightness_key = "b",                  -- see key bindings
    increase_brightness_mods = "SUPER|ALT",         -- see key bindings
    decrease_brightness_key = "B",                  -- see key bindings
    decrease_brightness_mods = "SUPER|ALT|SHIFT"    -- see key bindings
  }
)
```
Change them to your preference.

## Key Bindings

**Default keys**

### Toggle Wallpaper
| Key Binding | Action |
| :----- | :------- |
| <kbd>SUPER</kbd><kbd>b</kbd>  | Change to next wallpaper. |
| <kbd>SUPER</kbd><kbd>SHIFT</kbd><kbd>B</kbd> | Change to previous wallpaper. |

### Toggle Brightness
| Key Binding | Action |
| :----- | :----- |
| <kbd>SUPER</kbd><kbd>ALT</kbd><kbd>b</kbd>  | Increase brightness by 2% |
| <kbd>SUPER</kbd><kbd>ALT</kbd><kbd>SHIFT</kbd><kbd>B</kbd> | Decrease brightness by 2% |


