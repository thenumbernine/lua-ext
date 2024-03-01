local table = require 'ext.table'
return function(env)
	env = env or _G
	env.math = require 'ext.math'
	env.table = table
	env.string = require 'ext.string'
	env.coroutine = require 'ext.coroutine'
	env.io = require 'ext.io'
	env.os = require 'ext.os'
	env.path = require 'ext.path'
	env.tolua = require 'ext.tolua'
	env.fromlua = require 'ext.fromlua'
	env.class = require 'ext.class'
	env.reload = require 'ext.reload'
	env.range = require 'ext.range'
	env.timer = require 'ext.timer'
	env.op = require 'ext.op'
	env.getCmdline = require 'ext.cmdline'
	env.cmdline = env.getCmdline(table.unpack(arg or {}))
	env._ = os.execute
	-- requires ffi
	--env.gcnew = require 'ext.gcmem'.new
	--env.gcfree = require 'ext.gcmem'.free
	for k,v in pairs(require 'ext.assert') do
		env['assert'..k] = v
	end
end
