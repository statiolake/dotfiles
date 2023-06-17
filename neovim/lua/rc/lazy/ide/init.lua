local c = require 'rc.config'
return {
  import = string.format('rc.lazy.ide.%s', c.ide),
}
