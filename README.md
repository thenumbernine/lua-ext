I found myself recreating so many extensions to the base lua classes over and over again.
I thought I'd just put them in one place.
I'm sure this will grow out of hand.

Note to users: I often use "require 'ext'" in place of "require 'ext.ext'" in my code.
This is courtesy of a `LUA_PATH` pattern "foo/?/?.lua" in addition to the typical "foo/?.lua".

Descriptions of the Files:
- coroutine.lua, io.lua, math.lua, os.lua, string.lua, table.lua: extensions to the Lua builtin tables
- class.lua: class functionality for inheritence
- env.lua: adds all tables to the specified Lua environment table.  Also sets _ to os.execute for shorthand shell scripting.
- ext.lua: sets up global environment with ext.env and ext.meta 
- file.lua: file-as-table access (WIP)
- fromlua.lua, tolua.lua: serialization
- gcmem.lua: provides FFI-based functions for manually or automatically allocating and freeing memory
- meta.lua: extends off of builtin metatables for all types 
- number.lua: holds some extra number metatable functionality
- range.lua: a very simple function for creating tables of numeric for-loops
- reload.lua: removes from package.loaded, re-requires a file, and returns its result

NOTICE:
- file.lua will optionally use luafilesystem, if available
- gcmem.lua depends on ffi, particularly some ffi headers of stdio found in my lua-ffi-bindings project: https://github.com/thenumbernine/lua-ffi-bindings