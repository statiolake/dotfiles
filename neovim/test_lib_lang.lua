package.path = package.path .. ';./rtp/lua/?.lua'

describe('test rc.lib.lang.stringext', function()
  require 'rc.lib.lang.stringext'

  it('starts_with', function()
    assert.is_true(('hello'):starts_with 'hell')
    assert.is_true(not ('hello'):starts_with 'hal')
  end)
end)

describe('test rc.lib.lang.tableext', function()
  require 'rc.lib.lang.tableext'

  it('iter_values(), ipairs', function()
    local iter = table.iter_values({ 1, 2, 3 }, ipairs)
    assert.is_equal(1, iter:next())
    assert.is_equal(2, iter:next())
    assert.is_equal(3, iter:next())
    assert.is_equal(nil, iter:next())
  end)

  local function add(a, b)
    return a + b
  end

  it('iter_values(), pairs', function()
    local iter = table.iter_values({ 1, 2, 3 }, pairs)
    assert.is_equal(iter:fold(0, add), 6)
  end)

  it('iter_values, pairs, dict', function()
    local iter = table.iter_values({ a = 1, b = 2, c = 3 }, pairs)
    assert.is_equal(iter:fold(0, add), 6)
  end)

  it('iter_keys, ipairs', function()
    local iter = table.iter_keys({ 2, 3, 4 }, ipairs)
    assert.is_equal(1, iter:next())
    assert.is_equal(2, iter:next())
    assert.is_equal(3, iter:next())
    assert.is_equal(nil, iter:next())
  end)

  it('iter_keys, pairs', function()
    local iter = table.iter_keys({ 2, 3, 4 }, pairs)
    assert.is_equal(iter:fold(0, add), 6)
  end)

  it('iter_keys, pairs, dict', function()
    local iter = table.iter_keys({ a = 1, b = 2, c = 3 }, pairs)
    local collect = iter:fold({}, function(t, k)
      t[k] = true
      return t
    end)
    assert.is_true(collect.a)
    assert.is_true(collect.b)
    assert.is_true(collect.c)
    assert.is_true(not collect.d)
  end)
end)

describe('test rc.lib.lang.iterator', function()
  local iterator = require 'rc.lib.lang.iterator'

  it('new(), to_list()', function()
    local iter = iterator.new(function(max, i)
      i = i + 1
      if i < max then
        return i
      else
        return nil
      end
    end, 4, 0)
    local result = iter:to_table()
    assert.is_equal(3, #result)
    assert.is_equal(1, result[1])
    assert.is_equal(2, result[2])
    assert.is_equal(3, result[3])
  end)

  local function add(a, b)
    return a + b
  end
  local function is_even(a)
    return a % 2 == 0
  end

  it('range()', function()
    local iter = iterator.range(1, 10)
    assert.is_equal(iter:fold(0, add), 55)
  end)

  it('take()', function()
    local iter = iterator.range(1):take(100)
    assert.is_equal(iter:fold(0, add), 5050)
  end)

  it('skip()', function()
    local iter = iterator.range(-9):skip(10):take(100)
    assert.is_equal(iter:fold(0, add), 5050)
  end)

  it('filter()', function()
    local iter = iterator.range(1):filter(is_even):take(100)
    assert.is_equal(iter:fold(0, add), 10100)
  end)
end)
