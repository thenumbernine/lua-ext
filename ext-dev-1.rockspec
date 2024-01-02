package = "ext"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-ext.git"
}
description = {
	summary = "Commonly used extensions to the Lua default libraries.",
	detailed = [[
Commonly used extensions to the Lua default libraries.
Note to users: The structure of the source code doesn"t exactly match the structure in the rock install destination.
This is because I personally use a `LUA_PATH` pattern of "?/?.lua" in addition to the typical "?.lua".
To work with compatability of everyone else who does not use this convention, I have the rockspec install `ext/ext.lua` into `ext.lua` and keep `ext/everything_else.lua` at `ext/everything_else.lua`.
]],
	homepage = "https://github.com/thenumbernine/lua-ext",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "builtin",
	modules = {
		["ext.asserttype"] = "asserttype.lua",
		["ext.class"] = "class.lua",
		["ext.cmdline"] = "cmdline.lua",
		["ext.coroutine"] = "coroutine.lua",
		["ext.debug"] = "debug.lua",
		["ext.detect_ffi"] = "detect_ffi.lua",
		["ext.detect_lfs"] = "detect_lfs.lua",
		["ext.detect_os"] = "detect_os.lua",
		["ext.env"] = "env.lua",
		["ext"] = "ext.lua",
		["ext.path"] = "path.lua",
		["ext.fromlua"] = "fromlua.lua",
		["ext.gcmem"] = "gcmem.lua",
		["ext.io"] = "io.lua",
		["ext.math"] = "math.lua",
		["ext.meta"] = "meta.lua",
		["ext.number"] = "number.lua",
		["ext.op"] = "op.lua",
		["ext.os"] = "os.lua",
		["ext.range"] = "range.lua",
		["ext.reload"] = "reload.lua",
		["ext.string"] = "string.lua",
		["ext.table"] = "table.lua",
		["ext.timer"] = "timer.lua",
		["ext.tolua"] = "tolua.lua"
	}
}
