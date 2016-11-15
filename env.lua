--[[
	Copyright (c) 2015 Christopher E. Moore ( christopher.e.moore@gmail.com / http://christopheremoore.net )

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
--]]

return function(env)
	env = env or _G
	env.math = require 'ext.math'
	env.table = require 'ext.table'
	env.string = require 'ext.string'
	env.io = require 'ext.io'
	env.file = require 'ext.file'
	env.tolua = require 'ext.tolua'
	env.class = require 'ext.class'
	env.reload = require 'ext.reload'
	env.range = require 'ext.range'
	env._ = os.execute
	env.gcnew = require 'ext.gcmem'.new
	env.gcfree = require 'ext.gcmem'.free
end
