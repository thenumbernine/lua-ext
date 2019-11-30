#!/usr/bin/env lua
-- this is for making the ext.rockspec in particular
-- running this script requires ext and template
require 'ext'
local template = require 'template'
file['ext.rockspec'] = template([[
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
<? 
for f in io.dir'.' do 
	if f:sub(-4) == '.lua' then
		if f == 'make_rockspec.lua' then
			-- this isn't a part of the ext lib, just a script for making the rockspec
		elseif f == 'ext.lua' then
?>			['ext'] = 'ext/ext.lua',
<?		else
?>			'ext/<?=f?>',
<?		end
	end
end
?>		}
	}
}
]])
