local cmd = require 'rc.lib.command'
local msg = require 'rc.lib.msg'
local k = require 'rc.lib.keybind'
local env = require 'rc.lib.env'

return {
  {

    'thinca/vim-quickrun',
    dependencies = { 'vim-quickrun-runner-nvimterm' },
    init = function()
      local deepcopy = require('rc.lib.lang.object').deepcopy
      -- full_pred[&filetype](lines) が true なら、この lines は
      -- part_{filetype} ではなく {filetype} で実行される。
      -- これはあとで setup_{filetype} のところで個別に設定する
      local full_pred = {}
      local function setup_proass(config)
        config.proass = {
          exec = { 'procon-assistant run --force-compile' },
          ['hook/shebang/enable'] = 0,
          ['outputter/error/error'] = 'buffer',
        }
      end
      local function setup_cpp(config)
        config['cpp'] = {
          command = 'g++',
          tempfile = '%{tempname()}.cpp',
        }
        local cmdopt = {
          '-Wall',
          '-Wextra',
          '-std=c++20',
        }
        config.cpp['cmdopt'] = table.concat(cmdopt, ' ')
        if env.is_win32 then
          config.cpp['exec'] = {
            '%c %o %s -o %s:p:r.exe',
            '%s:p:r.exe %a',
          }
          config.cpp['hook/sweep/files'] = { '%S:p:r.exe' }
        else
          config.cpp['exec'] = {
            '%c %o %s -o %s:p:r',
            '%s:p:r %a',
          }
          config.cpp['hook/sweep/files'] = { '%S:p:r' }
        end
        -- part_cpp
        config.part_cpp = deepcopy(config.cpp)
        config.part_cpp['hook/shebang/enable'] = 0
        config.part_cpp['hook/eval/enable'] = 1
        config.part_cpp['hook/eval/template'] = table.concat({
          '#include <cassert>',
          '#include <cctype>',
          '#include <cerrno>',
          '#include <cfloat>',
          '#include <ciso646>',
          '#include <climits>',
          '#include <clocale>',
          '#include <cmath>',
          '#include <csetjmp>',
          '#include <csignal>',
          '#include <cstdarg>',
          '#include <cstddef>',
          '#include <cstdio>',
          '#include <cstdlib>',
          '#include <cstring>',
          '#include <ctime>',
          '#include <ccomplex>',
          '#include <cfenv>',
          '#include <cinttypes>',
          '#include <cstdbool>',
          '#include <cstdint>',
          '#include <ctgmath>',
          '#include <cwchar>',
          '#include <cwctype>',
          '#include <algorithm>',
          '#include <bitset>',
          '#include <complex>',
          '#include <deque>',
          '#include <exception>',
          '#include <fstream>',
          '#include <functional>',
          '#include <iomanip>',
          '#include <ios>',
          '#include <iosfwd>',
          '#include <iostream>',
          '#include <istream>',
          '#include <iterator>',
          '#include <limits>',
          '#include <list>',
          '#include <locale>',
          '#include <map>',
          '#include <memory>',
          '#include <new>',
          '#include <numeric>',
          '#include <ostream>',
          '#include <queue>',
          '#include <set>',
          '#include <sstream>',
          '#include <stack>',
          '#include <stdexcept>',
          '#include <streambuf>',
          '#include <string>',
          '#include <typeinfo>',
          '#include <utility>',
          '#include <valarray>',
          '#include <vector>',
          '#include <array>',
          '#include <atomic>',
          '#include <chrono>',
          '#include <condition_variable>',
          '#include <forward_list>',
          '#include <future>',
          '#include <initializer_list>',
          '#include <mutex>',
          '#include <random>',
          '#include <ratio>',
          '#include <regex>',
          '#include <system_error>',
          '#include <thread>',
          '#include <tuple>',
          '#include <typeindex>',
          '#include <type_traits>',
          '#include <unordered_map>',
          '#include <unordered_set>',
          '#include <iostream>',
          '#include <iomanip>',
          'int main(void) {',
          '%s',
          'return 0;',
          '}',
        }, '\n')
        full_pred.cpp = function(lines)
          local joined = table.concat(lines, '\n')
          return joined:find '#include'
            and (joined:find 'int main' or joined:find 'void main')
        end
      end
      local function setup_c(config)
        config.c = {
          command = 'clang',
          tempfile = '%{tempname()}.c',
        }
        config.c['cmdopt'] = '-Wall -Wextra -std=c11'
        if env.is_win32 then
          config.c['exec'] = {
            '%c %o %s -o %s:p:r.exe',
            '%s:p:r.exe %a',
          }
          config.c['hook/sweep/files'] = { '%S:p:r.exe' }
        else
          config.c['exec'] = {
            '%c %o %s -o %s:p:r',
            '%s:p:r %a',
          }
          config.c['hook/sweep/files'] = { '%S:p:r' }
        end
        -- part_c
        config.part_c = deepcopy(config.c)
        config.part_c['hook/shebang/enable'] = 1
        config.part_c['hook/eval/enable'] = 1
        config.part_c['hook/eval/template'] = table.concat({
          '#include <stdio.h>',
          '#include <stdlib.h>',
          '#include <string.h>',
          'int main(void) {',
          '%s',
          'return 0;',
          '}',
        }, '\n')
      end
      local function setup_rust(config)
        config.rust = {
          command = 'rust-runner',
          exec = { '%c %s' },
          ['hook/shebang/enable'] = 0,
        }
        config.part_rust = deepcopy(config.rust)
        config.part_rust['hook/eval/enable'] = 1
        config.part_rust['hook/eval/template'] = 'fn main() {\n%s\n}'
        full_pred.rust = function(lines)
          local joined = table.concat(lines, '\n')
          return joined:find 'fn main()'
        end
        config.cargo = {
          command = 'cargo',
          exec = { '%c run' },
          ['hook/shebang/enable'] = 0,
        }
      end
      local function setup_python(config)
        if env.is_win32 then
          config.python = {
            ['hook/output_encode/encoding'] = 'sjis',
          }
        end
      end
      local function setup_html(config)
        if vim.fn.executable 'open' ~= 0 then
          config.html = {
            command = 'open',
            exec = { '%c %s' },
            runner = 'shell',
            tempfile = '%{tempname()}.html',
            ['hook/shebang/enable'] = 0,
          }
        end
        if env.is_win32 then
          config.python = {
            ['hook/output_encode/encoding'] = 'sjis',
          }
        end
      end
      local function setup_typescript(config)
        local function quote(value)
          if env.is_win32 then
            return string.format('""%s""', value)
          else
            return string.format('\\"%s\\"', value)
          end
        end
        local compiler_options = {
          [quote 'target'] = quote 'es2017',
          [quote 'lib'] = '[' .. table.concat({
            quote 'dom',
            quote 'es2015',
            quote 'es5',
            quote 'es6',
            quote 'es2017',
          }, ', ') .. ']',
        }
        compiler_options = table
          .iter(compiler_options, pairs)
          :map(function(k, v)
            return k .. ': ' .. v
          end)
          :to_table()
        compiler_options = '"{ '
          .. table.concat(compiler_options, ', ')
          .. ' }"'
        local cmdopt = table.concat({
          '--compiler-options',
          compiler_options,
        }, ' ')
        config.tsnode = {
          exec = '%c %o %s',
          cmdopt = cmdopt,
          command = 'ts-node',
        }
        config.typescript = {
          exec = '%c run %o %s',
          cmdopt = '--allow-env --allow-read --allow-write --allow-net',
          command = 'deno',
        }
      end
      local function setup_racket(config)
        config.scheme = {
          command = 'racket',
          exec = '%c %s',
          ['hook/shebang/enable'] = 0,
        }
      end
      local function populate_config()
        local config = {
          _ = {
            runner = 'nvimterm',
            ['runner/nvimterm/vsplit_width'] = 100,
          },
        }
        setup_proass(config)
        setup_cpp(config)
        setup_c(config)
        setup_rust(config)
        setup_python(config)
        setup_html(config)
        setup_typescript(config)
        setup_racket(config)
        return config
      end
      local function call_with_range(original_filetype, first, last)
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(bufnr, first, last, true)
        -- part_{filetype} ではなく {filetype} を使うべきかどうかを判断する
        local should_full = full_pred[original_filetype]
          or function(_)
            return false
          end
        local filetype
        if should_full(lines) then
          filetype = original_filetype
        else
          filetype = 'part_' .. original_filetype
          if vim.g.quickrun_config[filetype] == nil then
            -- part_ 用の設定がない場合は元々の設定で試す。
            filetype = original_filetype
          end
        end
        local quickrun_cmd =
          string.format(':%d,%dQuickRun %s', first + 1, last, filetype)
        vim.cmd(quickrun_cmd)
      end
      local function partial_markdown(first, last)
        -- 最低でも ```{lang}, ``` と中身の3行が必要。行数が少なすぎる場合は
        -- エラーとする。
        -- first, last は exclusive なことに注意
        if last - first < 3 then
          error(
            'The specified range is too short: '
              .. 'at least 3 lines are needed'
          )
          return
        end
        -- 言語判定
        local curr_buf = vim.api.nvim_get_current_buf()
        local marker = vim.api
          .nvim_buf_get_lines(curr_buf, first, first + 1, true)[1]
          :gsub('%s+', '')
        if marker:sub(1, 3) ~= '```' then
          error(
            'VISUAL region is not markdown snippet: '
              .. 'not starting with ```'
          )
          return
        end
        local filetype = marker:sub(4)
        -- 最終行が ``` であるかを確認
        marker = vim.api.nvim_buf_get_lines(curr_buf, last - 1, last, true)[1]
        if marker ~= '```' then
          error(
            'VISUAL region is not markdown snippet: '
              .. ' not ending with ```'
          )
          return
        end
        print('detected filetype: ' .. filetype)
        -- 呼び出す
        call_with_range(filetype, first + 1, last - 1)
      end
      local function partial_other(filetype, first, last)
        call_with_range(filetype, first, last)
      end
      local function partial_quickrun(first, last)
        -- zero-indexed, exclusive にする (Neovim API の仕様に合わせる)
        first = first - 1
        last = last
        local filetype = vim.opt.filetype:get()
        -- markdown, pandoc.markdown, etc
        if filetype:match 'markdown' then
          partial_markdown(first, last)
        else
          partial_other(filetype, first, last)
        end
      end
      -- 各言語ごとの設定を反映する
      vim.g.quickrun_config = populate_config()
      -- キーバインド
      -- 部分実行 QuickRun
      k.xno('<Plug>(partial-quickrun)', partial_quickrun, { range = true })
      -- バッファで実行
      k.n('<Leader>r', function()
        local kind = vim.b.quickrun_kind or vim.opt.filetype:get()
        return k.t(k.cmd(string.format('QuickRun %s', kind)))
      end, { expr = true })
      k.x('<Leader>r', '<Plug>(partial-quickrun)')
      k.n(
        '<Leader>P',
        k.cmd 'QuickRun proass -runner system -outputter buffer'
      )
      -- 種類を設定
      cmd.add('QuickRunSetKind', function(ctx)
        vim.b.quickrun_kind = ctx.args[1]
        msg.info('<Leader>r で :QuickRun %s を実行します', ctx.args[1])
      end, {
        nargs = '1',
        complete = require('rc.lib.completer_helper').create_completer_from_static_list(
          table
            .iter_keys(vim.g.quickrun_config, pairs)
            :filter(function(v)
              return v ~= '_'
            end)
            :to_table()
        ),
      })
    end,
  },
  {
    'statiolake/vim-quickrun-runner-nvimterm',
  },
}
