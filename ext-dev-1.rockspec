package = 'ext'
version = 'dev-1'
source = {
	url = 'git+https://github.com/thenumbernine/lua-ext.git',
}
description = {
	summary = 'Commonly used extensions to the Lua default libraries.',
	detailed = 'Commonly used extensions to the Lua default libraries.',
	homepage = 'https://github.com/thenumbernine/lua-ext',
	license = 'MIT'
}
build = {
	type = 'builtin',
	modules = {
		['ext.class'] = 'class.lua',
		['ext.coroutine'] = 'coroutine.lua',
		['ext.env'] = 'env.lua',
		['ext'] = 'ext.lua',
		['ext.file'] = 'file.lua',
		['ext.fromlua'] = 'fromlua.lua',
		['ext.gcmem'] = 'gcmem.lua',
		['ext.io'] = 'io.lua',
		['ext.math'] = 'math.lua',
		['ext.meta'] = 'meta.lua',
		['ext.number'] = 'number.lua',
		['ext.op'] = 'op.lua',
		['ext.os'] = 'os.lua',
		['ext.range'] = 'range.lua',
		['ext.reload'] = 'reload.lua',
		['ext.string'] = 'string.lua',
		['ext.table'] = 'table.lua',
		['ext.tolua'] = 'tolua.lua',
	}
}
