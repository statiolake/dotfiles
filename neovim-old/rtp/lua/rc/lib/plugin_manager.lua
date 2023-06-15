-- plugin manager, backed by minpac

local msg = require 'rc.lib.msg'
local prof = require 'rc.lib.profile'
local ac = require 'rc.lib.autocmd'
local vimfn = require 'rc.lib.vimfn'
local cg = get_global_config

local function msg_error(plugin, format, ...)
  if plugin then
    msg.error('plugin_manager: ' .. plugin:name() .. ': ' .. format, ...)
  else
    msg.error('plugin_manager: ' .. format, ...)
  end
end

---@generic T
---@param value T|nil
---@return (fun(plugin: Plugin): T) | nil
local function to_cached_fun(value)
  if value == nil then
    return nil
  end

  if type(value) == 'function' then
    -- 設定値が関数の場合は、一回だけ関数を評価してそれ以降はずっと同じ値を返
    -- すようにキャッシュを実装する
    return function(plugin)
      if type(value) == 'function' then
        value = value(plugin)
      end
      return value
    end
  else
    -- 設定値が値の場合は、その値をそのまま返す関数とする。
    return function(_)
      return value
    end
  end
end

-- Source {{{

---@class Source
---@field public kind fun(plugin: Plugin): string
---@field public url? fun(plugin: Plugin): string
---@field public path? fun(plugin: Plugin): string
---@field public rev? fun(plugin: Plugin): string
---@field public subdir? fun(plugin: Plugin): string
---@field public build? fun(plugin: Plugin): string
local Source = {}
function Source.new(source)
  vim.validate {
    source = { source, 'table' },
    kind = { source.kind, { 'string', 'function' } },
    url = { source.kind, { 'string', 'function' }, true },
    path = { source.kind, { 'string', 'function' }, true },
    rev = { source.rev, { 'string', 'function' }, true },
    subdir = { source.subdir, { 'string', 'function' }, true },
    build = { source.build, { 'string', 'function' }, true },
  }

  return {
    kind = to_cached_fun(source.kind),
    url = to_cached_fun(source.url),
    path = to_cached_fun(source.path),
    rev = to_cached_fun(source.rev),
    subdir = to_cached_fun(source.subdir),
    build = to_cached_fun(source.build),
  }
end

function Source.expand(self, plugin)
  return {
    kind = self.kind(plugin),
    url = self.url and self.url(plugin),
    path = self.path and self.path(plugin),
    rev = self.rev and self.rev(plugin),
    subdir = self.subdir and self.subdir(plugin),
    build = self.build and self.build(plugin),
  }
end

-- }}}

-- Plugin {{{

---@class Plugin
---@field public name fun(self: Plugin): string
---@field public source Source
---@field public enabled fun(self: Plugin): boolean
---@field public simple fun(self: Plugin): boolean
---@field public as_deps fun(self: Plugin): boolean
---@field public depends fun(self: Plugin): table
---@field public opt_depends fun(self: Plugin): table
---@field public load_on? fun(self: Plugin): table
---@field public before_load fun(self: Plugin)
---@field public after_load fun(self: Plugin)
---@field public _to_load boolean
---@field public _is_before_load_executed boolean
---@field public _is_loaded boolean
---@field public _is_after_load_executed boolean
local Plugin = {}

---@param source Source
---@return Plugin
function Plugin.new(source)
  -- foo/bar.vim.git -> bar.vim
  local function default_name(self)
    local base
    if self.source.kind(self) == 'remote' then
      base = self.source.url(self)
    else
      base = self.source.path(self)
    end
    return ({ base:gsub('.*[\\/]', ''):gsub('.git$', '') })[1]
  end

  local function default_simple(self)
    return self.source.kind(self) == 'local'
  end

  local obj = {
    name = default_name,
    source = source,
    enabled = to_cached_fun(true),
    simple = default_simple,
    as_deps = to_cached_fun(false),
    depends = to_cached_fun {},
    opt_depends = to_cached_fun {},
    load_on = nil,
    before_load = function() end,
    after_load = function() end,
    _to_load = false,
    _is_before_load_executed = false,
    _is_loaded = false,
    _is_after_load_executed = false,
  }

  setmetatable(obj, { __index = Plugin })
  return obj
end

function Plugin.check_installed(self)
  -- 直接プラグインディレクトリが存在するかどうかチェックする
  local plugin_path
  if self.source.kind(self) == 'remote' then
    plugin_path = vimfn.expand(
      string.format(
        '%s/site/pack/minpac/opt/%s',
        vim.fn.stdpath 'data',
        self:name()
      )
    )
  elseif self.source.kind(self) == 'local' then
    plugin_path = vimfn.expand(self.source.path(self))
  end

  return b(vim.fn.isdirectory(plugin_path))
end

function Plugin.to_load(self)
  return self._to_load
end

function Plugin.is_before_load_executed(self)
  return self._is_before_load_executed
end

function Plugin.is_loaded(self)
  return self._is_loaded
end

function Plugin.is_after_load_executed(self)
  return self._is_after_load_executed
end

function Plugin.should_load(self)
  return self:enabled() and (not cg 'editor.simpleMode' or self:simple())
end

-- }}}

---@type table<string, Plugin>
local plugins = {}

---`Plugin.new()` に指定する source を spec から取り出す。
local function extract_source_from_spec(spec)
  local source = {}

  if type(spec[1]) == 'string' or type(spec[1]) == 'function' then
    -- `use { 'foo/bar', ... }` スタイルの宣言
    source = {
      kind = 'remote',
      url = spec[1],
    }
    spec[1] = nil
  else
    -- `use { kind = 'remote', url = 'foo/bar', ... }` スタイルの宣言
    source.kind = spec.kind
    source.url = spec.url
    local path = spec.path
    source.path = path
      and to_cached_fun(function(plugin)
        if type(path) == 'function' then
          path = path(plugin)
        end
        return vimfn.expand(path)
      end)
    spec.kind = nil
    spec.url = nil
    spec.path = nil
  end

  return Source.new(source)
end

---spec に指定されている各種オプションを plugin の方へ反映する。
local function register_spec_to_plugin(spec, plugin)
  ---spec[param] が型 tyspec を持っているときにコールバックを呼び出す。
  local function on_specified(param, tyspec, callback)
    local actual_ty = type(spec[param])
    if actual_ty == 'nil' then
      -- spec[param] は指定されていないので何もしない。
      return
    end

    local expected_repr_ty = tyspec
    local expected_element_ty = nil

    -- 通常の Lua の型ではない型について確認する。
    -- FIXME: 一般化するべき？
    if tyspec == 'list<string>' then
      expected_repr_ty = 'table'
      expected_element_ty = 'string'
    end

    -- actual_ty が function のときは型を確かめようがないので諦め
    if actual_ty ~= 'function' and actual_ty ~= expected_repr_ty then
      -- 型の不一致でエラー
      msg_error(
        plugin,
        "error in spec: param '%s' should be of type %s, got %s",
        param,
        tyspec,
        actual_ty
      )
      return
    end

    -- actual_ty が function のときは型を確かめようがないので諦め
    if actual_ty ~= 'function' and expected_element_ty then
      -- spec[param] は expected_element_ty 型の値のリストであるべきなので、各
      -- 要素すべてを確認してその型であることを確認する。

      -- その型でないような最初の要素を探す。
      local value_of_invalid_ty = table
        .iter_values(spec[param], pairs)
        :filter(function(value)
          return type(value) ~= expected_element_ty
        end)
        :next()

      if value_of_invalid_ty then
        -- 異なる型が紛れ込んでいるのでエラー。
        msg_error(
          plugin,
          "error in spec: param '%s' should have elements of type %s, got %s",
          expected_element_ty,
          type(value_of_invalid_ty)
        )
        return
      end
    end

    -- 条件が整っているのでコールバックを呼び出し、処理した項目を元のテーブル
    -- から削除しておく。
    callback(spec[param])
    spec[param] = nil
  end

  on_specified('rev', 'string', function(rev)
    plugin.source.rev = to_cached_fun(rev)
  end)

  on_specified('subdir', 'string', function(subdir)
    plugin.source.subdir = to_cached_fun(subdir)
  end)

  on_specified('build', 'string', function(build)
    plugin.source.build = to_cached_fun(build)
  end)

  on_specified('name', 'string', function(name)
    plugin.name = to_cached_fun(name)
  end)

  on_specified('enabled', 'boolean', function(enabled)
    plugin.enabled = to_cached_fun(enabled)
  end)

  on_specified('simple', 'boolean', function(simple)
    plugin.simple = to_cached_fun(simple)
  end)

  on_specified('as_deps', 'boolean', function(as_deps)
    plugin.as_deps = to_cached_fun(as_deps)
  end)

  on_specified('depends', 'list<string>', function(depends)
    plugin.depends = to_cached_fun(depends)
  end)

  on_specified('opt_depends', 'list<string>', function(opt_depends)
    plugin.opt_depends = to_cached_fun(opt_depends)
  end)

  on_specified('on_ft', 'list<string>', function(on_ft)
    plugin.load_on = to_cached_fun { ft = on_ft }
  end)

  on_specified('before_load', 'function', function(before_load)
    plugin.before_load = before_load
  end)

  on_specified('after_load', 'function', function(after_load)
    plugin.after_load = after_load
  end)

  -- まだ消費していないキーが有るならそれは不明なオプション
  local unused_keys = table.iter_keys(spec, pairs):to_table()
  if #unused_keys > 0 then
    local quoted = table
      .iter_values(unused_keys, ipairs)
      :map(function(k)
        return "'" .. k .. "'"
      end)
      :to_table()
    local repr = table.concat(quoted, ', ')
    msg_error(plugin, 'unknown keys for plugin spec: %s', repr)
  end
end

---プラグインを登録する。
local function use(spec)
  if not spec then
    msg_error(nil, 'spec is nil')
    return
  end

  if type(spec) == 'string' then
    spec = { spec }
    -- 文字列で登録するようなものは before_load も after_load もないくらい単
    -- 純ということなのでデフォルトで simple = true をセットする
    spec.simple = true
  end

  local source = extract_source_from_spec(spec)
  local plugin = Plugin.new(source)
  register_spec_to_plugin(spec, plugin)

  if plugins[plugin:name()] ~= nil then
    -- plugin of the same name is already registered
    msg_error(
      plugin,
      "plugin name %s registered twice: one for '%s', another for '%s'",
      plugin:name(),
      plugins[plugin:name()].source:expand(plugin),
      plugin.source:expand(plugin)
    )
  else
    plugins[plugin:name()] = plugin
  end
end

local function use_as_deps(spec)
  if not spec then
    -- 指定なければ無視する
    return
  end

  if type(spec) == 'string' then
    spec = { spec }
  end

  -- シンプルなプラグインの dependency もシンプルであるべき
  spec.simple = true
  spec.as_deps = true

  use(spec)
end

---グラフを帰りがけ順で訪問する。
---@generic V 頂点
---@param graph table<V, table<V>> グラフ
---@param root_nodes table<V> 訪問の開始地点となる頂点
---@param leaf_only boolean 葉のみを yield するかどうか
---@param visitor fun(root: V, path: table<V>, current: V) コールバック関数
local function visit_postorder(graph, root_nodes, leaf_only, visitor)
  -- サイクルを発見したらそのサイクルのパスを found_cycles に追記する。
  local found_cycles = {}

  ---再帰呼び出し用のローカル関数
  ---@generic V
  ---@param root V
  ---@param path table<V>
  ---@param current V
  ---@return boolean @current 以降で visitor を呼び出さず終了したら false
  local function visit_recursive(root, path, current)
    -- 今までのパスの中に現在の頂点と同じものがあるならそれはサイクル
    local has_cycle = table.iter_values(path, ipairs):any(function(component)
      return component == current
    end)

    if has_cycle then
      -- cycle を発見したのでこれ以上発展させないよう打ち切る。
      table.insert(found_cycles, { unpack(path), current })

      -- この頂点は行き止まりなので false を返す。
      return false
    end

    -- パスに現在頂点を追加する。
    table.insert(path, current)

    -- この頂点以降を訪問したかどうか
    local visited = false

    -- 子供たちを訪問する。その際、子供たちが visitor を呼び出したかどうかをメ
    -- モしておく。
    for _, child in ipairs(graph[current] or {}) do
      visited = visit_recursive(root, path, child) or visited
    end

    if not leaf_only or not visited then
      -- leaf_only でないならこの頂点を訪問する。もし leaf_only なら、子供たち
      -- の誰も visited でない場合 (= current が葉である場合) に訪問する。
      visitor(root, path, current)
      visited = true
    end

    -- パスから current をとる (pop_back() 的なね)
    table.remove(path)

    return visited
  end

  for _, root in ipairs(root_nodes) do
    -- 各ルートノードから帰りがけ順探索をやる。
    visit_recursive(root, {}, root)
  end

  return found_cycles
end

---ロードシーケンスのグラフを作成する。
---@return table<string> そのプラグインより前に読むべきプラグイン
---@return table<string> そのプラグインより後に読むべきプラグイン
---@return table<string, table> そのプラグインに不足している依存関係
local function build_order_graph()
  -- そのプラグインよりも前に読み込むべきプラグイン。
  local load_before = {}

  -- そのプラグインよりも後に読み込むべきプラグイン。load_before の逆方向のグ
  -- ラフに相当する。
  local load_after = {}

  -- 足りていない依存関係。
  local missing_deps = {}

  for _, plugin in pairs(plugins) do
    -- dep を plugin よりも前に読み込む、という順序を登録するヘルパー関数
    local function sequence_before_plugin(dep)
      -- plugin の前に dep を読み込む
      if not load_before[plugin:name()] then
        load_before[plugin:name()] = {}
      end
      table.insert(load_before[plugin:name()], dep)

      -- dep の後に plugin を読み込む
      if not load_after[dep] then
        load_after[dep] = {}
      end
      table.insert(load_after[dep], plugin:name())
    end

    -- 必須依存関係
    for _, dep in ipairs(plugin:depends()) do
      if plugins[dep] then
        sequence_before_plugin(dep)
      else
        -- 足りていないので後で警告するように保存する。
        if not missing_deps[plugin:name()] then
          missing_deps[plugin:name()] = {}
        end
        table.insert(missing_deps[plugin:name()], dep)
      end
    end

    -- 必須でない依存関係
    for _, dep in ipairs(plugin:opt_depends()) do
      -- もし実際にインストールされていれば plugin より前に読み込む。
      if plugins[dep] then
        sequence_before_plugin(dep)
      else
        -- 足りていなくても opt なので警告しない。
      end
    end
  end

  return load_before, load_after, missing_deps
end

---ロードシーケンスグラフからルートプラグインと循環参照を探す
---@return table<string> ルートプラグイン
---@return table<string, table<string>> そのプラグインにある循環依存関係
local function find_root_plugins_and_cycles(load_after)
  -- ルートプラグイン (最初に読み込むべきプラグイン) を探す。これは、各プラグ
  -- インに対して load_after を leaf_only で訪問して得られる。
  --
  -- 「誰からも依存されていないパッケージ」としないのは、設定ミスにより cyclic
  -- な依存関係があった場合でも、その cycle のどこかのパッケージをルートノード
  -- として無理やり扱いたいからである。そうでないとその cycle に属するプラグイ
  -- ンを全く読み込まないことになり、激しく壊してほぼ素の Neovim が起動した暁
  -- には修正も面倒になる。 (Packer でもあった問題点)
  local is_root_plugin = {}
  local cyclic_paths = {}
  for _, plugin in pairs(plugins) do
    local found_cycles = visit_postorder(
      load_after,
      { plugin:name() },
      true,
      function(_, _, current)
        -- as_deps プラグインは単体ではロードしないので無視させる。
        if not plugins[current]:as_deps() then
          is_root_plugin[current] = true
        end
      end
    )
    -- cyclic な依存関係を見つけた場合は記録する
    if found_cycles then
      cyclic_paths[plugin:name()] = found_cycles
    end
  end

  local root_plugins = table.iter_keys(is_root_plugin, pairs):to_table()
  local filtered_cyclic_paths = {}
  for _, plugin_name in ipairs(root_plugins) do
    local plugin = plugins[plugin_name]
    if cyclic_paths[plugin:name()] then
      filtered_cyclic_paths[plugin:name()] = cyclic_paths[plugin:name()]
    end
  end

  return root_plugins, filtered_cyclic_paths
end

---missing_deps を確認し、読み込むべきプラグインの `plugin:to_load()` を true
---にする
local function check_and_find_to_load(root_plugins, load_before, missing_deps)
  local function visit(parent_name, current_name)
    local current = plugins[current_name]

    local parent = parent_name and plugins[parent_name]
    local is_required = parent
      and table.iter_values(parent:depends(), ipairs):any(function(dep)
        return current_name == dep
      end)

    if not current:should_load() then
      -- このプラグインは有効にしない。
      if parent then
        -- 親がいるのに有効にしないというのは問題のある依存関係なので記録する。
        -- ただ opt_depends の場合はなくてもいいので depends に含まれているこ
        -- とを確認する。
        if is_required then
          if not missing_deps[parent_name] then
            missing_deps[parent_name] = {}
          end
          table.insert(missing_deps[parent_name], current_name)
        end
      end
      return
    end

    -- このプラグインを有効にする。as_deps プラグインの場合は必須になっていれ
    -- ばロードする
    current._to_load = current._to_load
      or (not current:as_deps() or is_required)

    -- 子供たちも有効にする。
    for _, child in ipairs(load_before[current:name()] or {}) do
      visit(current:name(), child)
    end
  end

  -- root_plugins から順にたどっていく。
  for _, root in ipairs(root_plugins) do
    visit(nil, root)
  end
end

---ロードシーケンスのグラフを作成する。
---@return table<string> ルートプラグイン
---@return table<string> そのプラグインより前に読むべきプラグイン
---@return table<string> そのプラグインより後に読むべきプラグイン
---@return table<string, table> そのプラグインに不足している依存関係
---@return table<string, table<string>> そのプラグインにある循環依存関係
local function build_graph()
  local load_before, load_after, missing_deps = build_order_graph()
  local root_plugins, cyclic_paths = find_root_plugins_and_cycles(load_after)
  check_and_find_to_load(root_plugins, load_before, missing_deps)
  return root_plugins, load_before, load_after, missing_deps, cyclic_paths
end

local function warn_missing_deps(missing_deps)
  for plugin_name, deps in pairs(missing_deps) do
    msg_error(
      plugins[plugin_name],
      'dependency %s not found',
      table.concat(
        table
          .iter_values(deps, ipairs)
          :map(function(dep)
            return string.format("'%s'", dep)
          end)
          :to_table(),
        ', '
      )
    )
  end
end

local function warn_cyclic_paths(cyclic_paths)
  for plugin_name, paths in pairs(cyclic_paths) do
    for _, path in ipairs(paths) do
      msg_error(
        plugins[plugin_name],
        'cyclic dependency detected: ' .. 'there is a cyclic path: %s -> ...',
        table.concat(path, ' -> ')
      )
    end
  end
end

local function run_before_load(plugin)
  prof.zone(string.format('%s: before_load', plugin:name()), function()
    vim.cmd('doautocmd User PlugBeforeLoadPre_' .. plugin:name())
    local ok, err = pcall(plugin.before_load, plugin)
    if not ok then
      msg_error(plugin, 'running before_load hook: %s', err)
    end
    vim.cmd('doautocmd User PlugBeforeLoadPost_' .. plugin:name())
    plugin._is_before_load_executed = true
  end)
end

local function load_plugin(plugin, load_now)
  return prof.zone(string.format('%s: packadd', plugin:name()), function()
    if plugin.source.kind(plugin) == 'local' then
      vim.opt.runtimepath:append(plugin.source.path(plugin))

      -- -- helptags を追加する
      -- -- FIXME: 本来はインストールするときにするべき
      -- local doc_dir = vimfn.expand(plugin.source.path(plugin) .. '/doc/')
      -- if b(vim.fn.isdirectory(doc_dir)) then
      --   ok, res = pcall(vim.cmd, 'helptags ' .. doc_dir)
      --   if not ok then
      --     msg.error('failed to generate helptags: %s', res)
      --   end
      -- end
    else
      local packadd = load_now and 'packadd ' or 'packadd! '
      local ok, err = pcall(vim.cmd, packadd .. plugin:name())
      if not ok then
        msg_error(plugin, 'running packadd %s: %s', plugin:name(), err)
        return false
      end
    end

    plugin._is_loaded = true
    return true
  end)
end

local function run_after_load(plugin)
  prof.zone(string.format('%s: after_load', plugin:name()), function()
    vim.cmd('doautocmd User PlugAfterLoadPre_' .. plugin:name())
    local ok, err = pcall(plugin.after_load, plugin)
    if not ok then
      msg_error(plugin, 'running after_load hook: %s', err)
    end
    vim.cmd('doautocmd User PlugAfterLoadPost_' .. plugin:name())
    plugin._is_after_load_executed = true
  end)
end

-- filetype に応じて読み込むプラグイン
local lazy_plugins_on_ft = {}
local function load_plugins_on_ft(filetype)
  local plugins_on_ft = lazy_plugins_on_ft[filetype]

  -- plugins_on_ft は基本的に配列だが is_loaded メンバーももつ
  -- このへん Lua っぽいね
  if plugins_on_ft and not plugins_on_ft.is_loaded then
    -- 読み込むべきプラグインがある場合は読み込む
    local to_load = {}
    for _, plugin in ipairs(plugins_on_ft) do
      if plugin:to_load() and not plugin:check_installed() then
        msg_error(plugin, plugin:name() .. ' not found')
      else
        if not plugin:is_loaded() then
          to_load[plugin:name()] = plugin
        end
      end
    end

    -- before_load
    for _, plugin in pairs(to_load) do
      run_before_load(plugin)
    end

    -- load plugin
    for _, plugin in pairs(to_load) do
      load_plugin(plugin, true)
    end

    -- after_load
    for _, plugin in pairs(to_load) do
      run_after_load(plugin)
    end

    plugins_on_ft.is_loaded = true
    vim.cmd [[doautocmd <nomodeline> FileType]]
  end
end

-- 実際にプラグインを読み込む
local function load()
  local root_plugins, graph, _, missing_deps, cyclic_paths =
    prof.zone('load: build_graph()', build_graph)

  warn_missing_deps(missing_deps)
  warn_cyclic_paths(cyclic_paths)

  local ordered_plugins = {}
  visit_postorder(graph, root_plugins, false, function(_, _, plugin_name)
    local plugin = plugins[plugin_name]

    if not plugin:to_load() then
      -- ロードすべきでないなら読み込まない。
      return
    end

    if plugin:is_loaded() then
      -- ロード済みなら読み込まない。
      return
    end

    if not plugin:check_installed() then
      -- インストールされていない。
      msg_error(plugin, plugin:name() .. ' not found')
      return
    end

    if missing_deps[plugin_name] then
      -- インストールされていない依存関係がある。
      msg_error(
        plugin,
        string.format(
          'some of dependencies of %s is not satisfied: %s',
          plugin_name,
          table.concat(missing_deps[plugin_name], ', ')
        )
      )
      return
    end

    if plugin.load_on then
      -- 遅延ロードプラグインは後で読み込むことにする
      if plugin:load_on().ft then
        for _, ft in ipairs(plugin:load_on().ft) do
          if not lazy_plugins_on_ft[ft] then
            lazy_plugins_on_ft[ft] = { is_loaded = false }
          end
          table.insert(lazy_plugins_on_ft[ft], plugin)
        end
      end

      return
    end

    -- 一連の before_load を実行, 一連の packadd, 一連の after_load を実行、の
    -- 流れ。
    table.insert(ordered_plugins, plugin)
  end)

  -- まとめて before_load を読み込む。
  for _, plugin in ipairs(ordered_plugins) do
    run_before_load(plugin)
  end

  -- まとめて packadd する。
  for _, plugin in ipairs(ordered_plugins) do
    load_plugin(plugin)
  end
  vim.cmd [[packloadall]]

  -- まとめて after_load を読み込む。
  for _, plugin in ipairs(ordered_plugins) do
    run_after_load(plugin)
  end

  -- load_on.ft のプラグインのために autocmd を追加する
  ac.augroup('rc__plugin_load_on_ft', function(au)
    for filetype, _ in pairs(lazy_plugins_on_ft) do
      au('FileType', filetype, function()
        load_plugins_on_ft(filetype)
      end)
    end
  end)
end

local function tap(plugin_name)
  return deepcopy(plugins[plugin_name])
end

local function list()
  return vim.deepcopy(plugins)
end

local minpac_registered = false

local function register_to_minpac(batch_mode)
  if not minpac_registered then
    local ok = pcall(vim.cmd, 'packadd minpac')
    if not ok or not b(vim.fn.exists 'g:loaded_minpac') then
      msg_error(
        nil,
        'minpac is not installed; rerun install.py from dotfiles'
      )
      return false
    end

    vim.fn['minpac#init'] {
      dir = vimfn.expand(vim.fn.stdpath 'data' .. '/site', false, false),
      progress_open = 'vertical',
      status_open = batch_mode and 'vertical' or 'none',
      status_auto = false,
      jobs = 1,
      verbose = 3,
    }

    for _, plugin in pairs(plugins) do
      if plugin.source.kind(plugin) == 'remote' then
        vim.fn['minpac#add'](plugin.source.url(plugin), {
          name = plugin:name(),
          type = 'opt',
          rev = plugin.source.rev and plugin.source.rev(plugin),
          subdir = plugin.source.subdir and plugin.source.subdir(plugin),
          ['do'] = plugin.source.build and plugin.source.build(plugin),
        })
      end
    end

    minpac_registered = true
  end

  return true
end

local function open_dir(plugin_name)
  if not register_to_minpac() then
    return
  end

  local cwd = vim.fn['minpac#getpluginfo'](plugin_name).dir
  vim.cmd [[vnew]]
  vim.fn.termopen(require('rc.env').shell, {
    cwd = cwd,
  })
end

local function validate_depgraph()
  -- 問題を確認するためにグラフを作る
  local _, load_before, load_after, missing_deps, cyclic_paths = build_graph()

  -- 不足している依存関係と循環参照を警告
  warn_missing_deps(missing_deps)
  warn_cyclic_paths(cyclic_paths)

  -- load_on が指定されている関数に depends 関係があると警告する
  for _, plugin in pairs(plugins) do
    local sequenced = load_before[plugin:name()] or load_after[plugin:name()]
    if plugin.load_on and sequenced then
      msg_error(
        plugin,
        table.concat {
          'plugins loaded on some event cannot depend on or be dependency ',
          'of other plugins',
        }
      )
    end
  end

  return #missing_deps == 0 and #cyclic_paths == 0
end

--- minpac をロードし、すべてのプラグインをインストールする
local function update(targets, batch_mode)
  if type(targets) == 'string' then
    targets = { targets }
  end

  validate_depgraph()
  if not register_to_minpac(batch_mode) then
    return
  end

  local opts = { [vim.type_idx] = vim.types.dictionary }
  if batch_mode then
    opts['do'] = 'quitall!'
  end

  if targets then
    vim.fn['minpac#update'](targets, opts)
  else
    vim.fn['minpac#update']('', opts)
  end
end

local function update_and_quit(targets)
  return update(targets, true)
end

local function clean()
  -- minpac#clean() を呼び出すだけ
  validate_depgraph()
  if not register_to_minpac() then
    return
  end
  vim.fn['minpac#clean']()
end

local function add_hook(hook, plugin_name, func)
  if not plugins[plugin_name] then
    msg_error(
      nil,
      "add hook for %s: unknown plugin name '%s'",
      hook,
      plugin_name
    )
    return
  end
  ac.register_once('User', string.format('%s_%s', hook, plugin_name), func)
end

local function hook_before_load_pre(plugin_name, func)
  add_hook('PlugBeforeLoadPre', plugin_name, func)
end

local function hook_before_load_post(plugin_name, func)
  add_hook('PlugBeforeLoadPost', plugin_name, func)
end

local function hook_after_load_pre(plugin_name, func)
  add_hook('PlugAfterLoadPre', plugin_name, func)
end

local function hook_after_load_post(plugin_name, func)
  add_hook('PlugAfterLoadPost', plugin_name, func)
end

local helper = {}

function helper.local_if_exists(plugin)
  if b(vim.fn.isdirectory(plugin.source.path(plugin))) then
    return 'local'
  else
    return 'remote'
  end
end

return {
  use = use,
  use_as_deps = use_as_deps,
  hook_before_load_pre = hook_before_load_pre,
  hook_before_load_post = hook_before_load_post,
  hook_after_load_pre = hook_after_load_pre,
  hook_after_load_post = hook_after_load_post,
  load = load,
  tap = tap,
  list = list,
  update = update,
  update_and_quit = update_and_quit,
  clean = clean,
  open_dir = open_dir,
  helper = helper,
}
