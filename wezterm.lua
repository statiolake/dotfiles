local wezterm = require 'wezterm'

local is_unix = pcall(wezterm.run_child_process, { 'uname', '-a' })

local function k(ch)
  local key = {
    key = ch,
    mods = {},
  }

  function key.with_mod(self, mod)
    local found = false
    for _, v in ipairs(self.mods) do
      if v == mod then
        found = true
        break
      end
    end
    if not found then
      table.insert(self.mods, mod)
    end
    return self
  end

  function key.alt(self)
    return self:with_mod 'ALT'
  end

  function key.ctrl(self)
    return self:with_mod 'CTRL'
  end

  function key.shift(self)
    return self:with_mod 'SHIFT'
  end

  function key.leader(self)
    return self:with_mod 'LEADER'
  end

  function key.finalize(self)
    return {
      key = self.key,
      mods = table.concat(self.mods, '|'),
    }
  end

  return key
end

local function with_action(key, action)
  return {
    key = key.key,
    mods = key.mods,
    action = wezterm.action(action),
  }
end

local fonts
local font_size
if is_unix then
  fonts = { 'PlemolJP Console NF' }
  font_size = 12.0
else
  fonts = { 'Consolas', 'MeiryoKe_Gothic' }
  font_size = 12.0
end

local cfg = {
  font = wezterm.font_with_fallback(fonts),
  front_end = 'WebGpu',
  freetype_load_flags = "NO_HINTING",
  freetype_load_target = "HorizontalLcd",
  freetype_render_target = "HorizontalLcd",
  webgpu_power_preference = 'HighPerformance',
  font_rules = {
    {
      intensity = 'Bold',
      font = wezterm.font_with_fallback((function()
        local res = {}
        for _, font in ipairs(fonts) do
          table.insert(res, { family = font, weight = 'Bold' })
        end
        return res
      end)()),
    },
  },
  exit_behavior = 'Close',
  font_size = font_size,
  line_height = 1.0,
  animation_fps = 1,
  cursor_thickness = '1.5pt',
  underline_thickness = '1.5pt',
  initial_rows = 25,
  initial_cols = 100,
  use_fancy_tab_bar = false,
  enable_tab_bar = false,
  window_close_confirmation = 'NeverPrompt',
  --window_decorations = 'RESIZE',
  colors = {
    -- Builtin Tango Dark
    foreground = '#dfdfaf',
    background = '#1c1c1c',
    cursor_bg = '#dfdfaf',
    cursor_border = '#ffffff',
    cursor_fg = '#1c1c1c',
    selection_bg = '#af5f5f',
    selection_fg = '#121212',
    ansi = {
      '#1c1c1c',
      '#af5f5f',
      '#87875f',
      '#dfaf87',
      '#878787',
      '#875f5f',
      '#87afaf',
      '#dfdfaf',
    },
    brights = {
      '#878787',
      '#af5f5f',
      '#87875f',
      '#dfaf87',
      '#878787',
      '#875f5f',
      '#87afaf',
      '#dfdfaf',
    },
  },
  -- colors = {
  --   -- Builtin Tango Dark
  --   foreground = '#ffffff',
  --   background = '#000000',
  --   cursor_bg = '#ffffff',
  --   cursor_border = '#ffffff',
  --   cursor_fg = '#000000',
  --   selection_bg = '#b5d5ff',
  --   selection_fg = '#000000',
  --   ansi = {
  --     '#000000',
  --     '#cc0000',
  --     '#4e9a06',
  --     '#c4a000',
  --     '#3465a4',
  --     '#75507b',
  --     '#06989a',
  --     '#d3d7cf',
  --   },
  --   brights = {
  --     '#555753',
  --     '#ef2929',
  --     '#8ae234',
  --     '#fce94f',
  --     '#729fcf',
  --     '#ad7fa8',
  --     '#34e2e2',
  --     '#eeeeec',
  --   },
  -- },
  leader = k('q'):shift():ctrl():finalize(),
  keys = {
    with_action(
      k('s'):leader():finalize(),
      { SplitVertical = { domain = 'CurrentPaneDomain' } }
    ),
    with_action(
      k('v'):leader():finalize(),
      { SplitHorizontal = { domain = 'CurrentPaneDomain' } }
    ),
    with_action(
      k('c'):leader():finalize(),
      { SpawnTab = 'CurrentPaneDomain' }
    ),
    with_action(
      k('h'):leader():finalize(),
      { ActivatePaneDirection = 'Left' }
    ),
    with_action(
      k('j'):leader():finalize(),
      { ActivatePaneDirection = 'Down' }
    ),
    with_action(k('k'):leader():finalize(), { ActivatePaneDirection = 'Up' }),
    with_action(
      k('l'):leader():finalize(),
      { ActivatePaneDirection = 'Right' }
    ),
    with_action(
      k('H'):leader():shift():finalize(),
      { AdjustPaneSize = { 'Left', 5 } }
    ),
    with_action(
      k('J'):leader():shift():finalize(),
      { AdjustPaneSize = { 'Down', 5 } }
    ),
    with_action(
      k('K'):leader():shift():finalize(),
      { AdjustPaneSize = { 'Up', 5 } }
    ),
    with_action(
      k('L'):leader():shift():finalize(),
      { AdjustPaneSize = { 'Right', 5 } }
    ),
    with_action(k('n'):leader():finalize(), { ActivateTabRelative = 1 }),
    with_action(k('p'):leader():finalize(), { ActivateTabRelative = -1 }),
    with_action(k('1'):leader():finalize(), { ActivateTab = 0 }),
    with_action(k('2'):leader():finalize(), { ActivateTab = 1 }),
    with_action(k('3'):leader():finalize(), { ActivateTab = 2 }),
    with_action(k('4'):leader():finalize(), { ActivateTab = 3 }),
    with_action(k('5'):leader():finalize(), { ActivateTab = 4 }),
    with_action(k('6'):leader():finalize(), { ActivateTab = 5 }),
    with_action(k('7'):leader():finalize(), { ActivateTab = 6 }),
    with_action(k('8'):leader():finalize(), { ActivateTab = 7 }),
    with_action(k('9'):leader():finalize(), { ActivateTab = 8 }),
    with_action(
      k('&'):leader():shift():finalize(),
      { CloseCurrentTab = { confirm = true } }
    ),
    with_action(
      k('x'):leader():finalize(),
      { CloseCurrentPane = { confirm = true } }
    ),
  },
}

local function update_cfg_for_pwsh(cfg)
  cfg.default_prog = { [[C:\Program Files\WindowsApps\Microsoft.PowerShell_7.3.5.0_x64__8wekyb3d8bbwe\pwsh.exe]] }
  cfg.default_cwd = os.getenv 'HOME' or os.getenv 'USERPROFILE'
  cfg.leader = k('q'):ctrl():finalize()
  cfg.enable_tab_bar = true
end

local function update_cfg_for_rsh(cfg)
  cfg.default_prog = { 'rsh.exe' }
  cfg.default_cwd = os.getenv 'HOME' or os.getenv 'USERPROFILE'
  cfg.leader = k('q'):ctrl():finalize()
  cfg.enable_tab_bar = true
end

local function update_cfg_for_nyagos(cfg)
  cfg.default_prog = { 'nyagos.exe' }
  cfg.default_cwd = os.getenv 'HOME' or os.getenv 'USERPROFILE'
  cfg.leader = k('q'):ctrl():finalize()
  cfg.enable_tab_bar = true
end

local function update_cfg_for_wsl(cfg)
  -- WSL でのユーザー名も Windows でのユーザー名と同様とする
  local wsl_user_name = os.getenv 'USER'
  cfg.window_close_confirmation = 'NeverPrompt'
  cfg.default_prog = { 'wsl.exe', '-d', 'Ubuntu' }
  cfg.default_cwd = [[\\wsl$\Ubuntu\home\]] .. wsl_user_name
  cfg.leader = k('q'):shift():ctrl():finalize()
  cfg.enable_tab_bar = false
end

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  local use_wsl = false
  local has_wsl = wezterm.run_child_process { 'wsl.exe', '--list' }
  if use_wsl and has_wsl then
    -- default: WSL
    update_cfg_for_wsl(cfg)
  else
    -- fallback
    cfg.unix_domains = { { name = 'unix' } }
    cfg.default_gui_startup_args = { 'connect', 'unix' }
    update_cfg_for_pwsh(cfg)
  end
end

return cfg
