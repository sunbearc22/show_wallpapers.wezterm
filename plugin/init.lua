--[[
About his Plugin:
- It does the following:
    - Access "directory" to get the paths of all image files and stores them in
      wezterm.GLOBAL.images. Its default to $HOME/Pictures/Wallpapers/ but you can
      specify directory of your preference.
    - Randomly chooses an image from wezterm.GLOBAL.images and displays it as
      a wallpaper by appyling it to config.background.
    - The image index is stored in wezterm.GLOBAL.image_index.
    - The image brightness is stored in wezterm.GLOBAL.brightness.
    - Let you toggle the wallpaper choice forward and backward using Super+b and Super+Shift+B,
      and updates wezterm.GLOBAL.image_index.
    - Let you brighten and dim the wallpaper using Super+Alt+b and Super+Alt+B and
      updates wezterm.GLOBAL.brightness.
-- Special thanks to @bew for advices/guidance during initial development.
]]
local M = {}

local wezterm = require("wezterm")


---@param config unknown
---@param opts {
---directory: string?,
---brightness: number?,
---toggle_forward_key: string?,
---toggle_forward_mods: string?,
---toggle_backward_key: string?,
---toggle_backward_mods: string?,
---increase_brightness_key: string?,
---increase_brightness_mods: string?,
---decrease_brightness_key: string?,
---decrease_brightness_mods: string?}
-- Module funtion to apply to config
function M.apply_to_config(config, opts)
  local directory = opts.directory or wezterm.home_dir .. "/Pictures/Wallpapers"
  local brightness = opts.brightness or 0.06
  local toggle_forward_key = opts.toggle_forward_key or "b"
  local toggle_forward_mods = opts.toggle_forward_mods or "SUPER"
  local toggle_backward_key = opts.toggle_backward_key or "B"
  local toggle_backward_mods = opts.toggle_backward_mods or "SUPER|SHIFT"
  local increase_brightness_key = opts.increase_brightness_key or "b"
  local increase_brightness_mods = opts.increase_brightness_mods or "SUPER|ALT"
  local decrease_brightness_key = opts.decrease_brightness_key or "B"
  local decrease_brightness_mods = opts.decrease_brightness_mods or "SUPER|ALT|SHIFT"

  -- Function to define the fields of a single layer of config.background.
  local function create_blayer(image, bvalue)
    if image then
      return {
        source = { File = image },
        hsb = { hue = 1.0, saturation = 1.0, brightness = bvalue },
        opacity = 1.0,
        height = "100%",
        width = "100%",
      }
    else
      print("Functon create_blayer parameter 'image' not defined.")
      return {}
    end
  end

  -- Function to get filepath of all image files and return them in a table
  local function get_images(dir)
    -- Check if directory exists and is accessible
    local handle = io.popen('test -d "' .. dir .. '" && echo "exists" || echo "not found"', "r")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if string.match(result, "not found") then
        return {}
      end
    else
      return {} -- Return empty table instead of erroring
    end
    -- Build the find command using your specified approach
    local find_cmd = 'find "' .. dir
        .. '" -type f -print0 2>/dev/null| xargs -0 file --mime-type | grep -F "image/" | cut -d: -f1 | sort'
    -- Execute the command and capture output
    local handle = io.popen(find_cmd, "r")
    if not handle then
      return {}
    end
    local results = handle:read("*a")
    handle:close()
    -- Parse the output
    local images = {}
    for line in string.gmatch(results, "[^\n]+") do
      if line ~= "" then -- Filter out empty lines
        table.insert(images, line)
      end
    end
    return images
  end

  -- Handler for toggle-wallpaper event
  wezterm.on("toggle-wallpaper", function(window, pane, direction)
    local old_index = wezterm.GLOBAL.image_index
    wezterm.log_info("[WALLPAPERS] direction = " .. direction)
    wezterm.log_info("[WALLPAPERS] old image index : " .. old_index)
    if direction == "forward" then
      wezterm.GLOBAL.image_index = (old_index % #wezterm.GLOBAL.images) + 1
    elseif direction == "backward" then
      wezterm.GLOBAL.image_index = old_index - 1
      if wezterm.GLOBAL.image_index < 1 then
        wezterm.GLOBAL.image_index = #wezterm.GLOBAL.images
      end
    else
      wezterm.error("arg: direction is not defined.")
    end
    local new_index = wezterm.GLOBAL.image_index
    local new_image = wezterm.GLOBAL.images[new_index]
    wezterm.log_info("[WALLPAPERS] Image changed to : " .. new_index .. " " .. new_image)
    local overrides = window:get_config_overrides() or {}
    overrides.background = {
      create_blayer(new_image, wezterm.GLOBAL.brightness),
    }
    window:set_config_overrides(overrides)
    wezterm.log_info("[WALLPAPERS] window:set_config_overrides(overrides) done.")
  end)

  -- Handler for toggle-brightness event
  wezterm.on("toggle-brightness", function(window, pane, direction)
    local old_brightness = wezterm.GLOBAL.brightness
    local delta = 0.02
    wezterm.log_info("[WALLPAPERS] direction = " .. direction)
    wezterm.log_info("[WALLPAPERS] old brightness : " .. old_brightness)
    if direction == "increase" then
      wezterm.GLOBAL.brightness = old_brightness + delta
      if wezterm.GLOBAL.brightness > 1.0 then
        wezterm.GLOBAL.brightness = 1.0
      end
    elseif direction == "decrease" then
      wezterm.GLOBAL.brightness = old_brightness - delta
      if wezterm.GLOBAL.brightness < 0.0 then
        wezterm.GLOBAL.brightness = 0.0
      end
    end
    local new_brightness = wezterm.GLOBAL.brightness
    wezterm.log_info("[WALLPAPERS] new_brightness = " .. new_brightness)
    local image = wezterm.GLOBAL.images[wezterm.GLOBAL.image_index]
    local overrides = window:get_config_overrides() or {}
    overrides.background = { create_blayer(image, new_brightness) }
    window:set_config_overrides(overrides)
  end)

  -- Get images
  wezterm.GLOBAL.images = get_images(directory)
  wezterm.log_info("[WALLPAPERS] #wezterm.GLOBAL.images = " .. #wezterm.GLOBAL.images)

  -- Initial state
  if not wezterm.GLOBAL.image_index then
    wezterm.GLOBAL.image_index = math.random(1, #wezterm.GLOBAL.images)
  end
  if not wezterm.GLOBAL.brightness then
    wezterm.GLOBAL.brightness = brightness
  end

  -- Set initial wallpaper
  config.background = {
    create_blayer(wezterm.GLOBAL.images[wezterm.GLOBAL.image_index], brightness),
  }

  -- Define keys to toggle wallpaper and brightness
  local keys = {
    -- Toggle forward
    {
      key = toggle_forward_key,
      mods = toggle_forward_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("toggle-wallpaper", window, pane, "forward")
      end),
    },
    -- Toggle backwards
    {
      key = toggle_backward_key,
      mods = toggle_backward_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("toggle-wallpaper", window, pane, "backward")
      end),
    },
    -- Increase brightness
    {
      key = increase_brightness_key,
      mods = increase_brightness_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("toggle-brightness", window, pane, "increase")
      end),
    },
    -- Decrease brightness
    {
      key = decrease_brightness_key,
      mods = decrease_brightness_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("toggle-brightness", window, pane, "decrease")
      end),
    },
  }

  -- Load keys into config.keys
  if not config.keys then
    config.keys = {}
  end
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end
end

return M
