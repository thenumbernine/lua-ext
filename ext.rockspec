package = 'Ext'
version = '0.1'
source = {
	url = 'https://github.com/thenumbernine/lua-ext',
}
description = {
	summary = 'Commonly used extensions to the Lua default libraries.',
	detailed = 'Commonly used extensions to the Lua default libraries.',
	homepage = 'https://github.com/thenumbernine/lua-ext',
	license = 'MIT',
}
dependencies = {
	'lua >= 5.1',
	-- luafilesystem is used if available
	-- luajit is used if available
}
build = {
	type = 'builtin',
	install = {
		lua = {
			['ext'] = 'ext/ext.lua',
			'ext/table.lua',
			'ext/range.lua',
			'ext/os.lua',
			'ext/op.lua',
			'ext/fromlua.lua',
			'ext/coroutine.lua',
			'ext/file.lua',
			'ext/gcmem.lua',
			'ext/io.lua',
			'ext/meta.lua',
			'ext/class.lua',
			'ext/string.lua',
			'ext/number.lua',
			'ext/tolua.lua',
			'ext/env.lua',
			'ext/reload.lua',
			'ext/math.lua',
		}
	}
}
