-- FIXME: neovim#16363 を仮に実装してしまう
-- Python (pyright, pyls) のように複数のサーバーを使っている環境で意図しない
-- フォーカスが発生してしまうため。
-- <https://www.reddit.com/r/neovim/comments/nytu9c/how_to_prevent_focus_on_floating_window_created/>
local prev_params = nil
local prev_contents = nil
local handled_clients = {}
local focus_toggle_clients = {}
local function hover_handler(_, result, ctx, config)
  local util = vim.lsp.util

  config = config or {}
  config.focus_id = ctx.method
  if not (result and result.contents) then
    return
  end

  local contents = util.convert_input_to_markdown_lines(result.contents)
  contents = util.trim_empty_lines(contents)

  -- 新しい情報が空なら何もしない
  if vim.tbl_isempty(contents) then
    return
  end

  -- 以前のパラメータと同じでクライアントも異なる = 追記したものを表示する
  local same_param = prev_params and vim.deep_equal(prev_params, ctx.params)
  if same_param and not handled_clients[ctx.client_id] then
    -- 保存しておいた以前のコンテンツを今のコンテンツの前に挿入する
    local tmp = {}
    vim.list_extend(tmp, prev_contents)
    vim.list_extend(tmp, { '---' })
    vim.list_extend(tmp, contents)
    contents = tmp

    -- このときは複数のサーバーからの返答なので、ユーザーの入力ではなさそう。
    -- focus はしない
    config.focus = false
  elseif same_param then
    -- このときは既にハンドルしたクライアントから同じパラメータできているとい
    -- うことなので、(LS がバグっていなければ) 同じ場所で二回ホバーを呼び出し
    -- たということ。サーバーから来た単一の内容ではなく、既に出揃っているはず
    -- の前回の内容を表示する。
    contents = prev_contents
    -- しかし... すでにフォーカスしている場合、Neovim は元のウィンドウにカーソ
    -- ルを戻そうとする。ということは、異なる2つのサーバーから2回目のレスポン
    -- スが帰ってきた場合、フォーカスが行って戻ってくるということになる。それ
    -- は問題があるので、その場合でもフォーカスを戻させない必要がある。
    if focus_toggle_clients[ctx.client_id] then
      -- 同じクライアントから複数回のレスポンスを受け取った場合。このときはフ
      -- ォーカスをトグルしてよい。focus_toggle_clients はリセットしておく。
      focus_toggle_clients = {}
    else
      -- このときはフォーカスをトグルしてはならない。何なら、すでにフロートは、
      -- 画面に表示されているはずなので新たに表示する必要もない。
      return
    end
  elseif not same_param then
    -- 以前のパラメータと違うときは新しいコンテンツをそのまま新しいフロートに
    -- 表示する。ハンドルしたクライアントはリセットしておく。
    handled_clients = {}
  end

  -- 今回の結果を次に引き継ぐ。
  prev_params = vim.deepcopy(ctx.params)
  prev_contents = vim.deepcopy(contents)
  handled_clients[ctx.client_id] = true
  focus_toggle_clients[ctx.client_id] = true

  if vim.tbl_isempty(contents) then
    return
  end

  return util.open_floating_preview(contents, 'markdown', config)
end

local M = {}

function M.enable_multi_server_hover()
  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(hover_handler, {
    border = get_global_config 'ui.border',
  })
end

function M.enable_multi_server_signature_help()
  -- TODO: multi server support for signature help...
  vim.lsp.handlers['textDocument/signatureHelp'] =
    vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = get_global_config 'ui.border',
    })
end

function M.disable_diagnostics_virtual_text()
  vim.lsp.handlers['textDocument/publishDiagnostics'] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = false,
    })
end

return M
