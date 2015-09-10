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

local ffi = require 'ffi'
require 'ffi.c.stdlib'

--[[
uses C malloc paired with ffi-based garbage collection 
typecasts correctly
and retains the ability to manually free
(so you don't have to manually free it)
NOTICE casting *AFTER* wrapping will crash, probably due to the gc thinking the old pointer is gone
also ffi.gc retains type, so no worries about casting before
--]]
local function gcnew(T, n)
	local ptr = ffi.C.malloc(n * ffi.sizeof(T))
	ptr = ffi.cast(T..'*', ptr)
	ptr = ffi.gc(ptr, ffi.C.free)
	return ptr
end

--[[
manual free of a pointer
frees the ptr and removes it from the gc 
(just in case you want to manually free a pointer)
--]]
local function gcfree(ptr)
	ffi.C.free(ffi.gc(ptr, nil))
end

return {
	new = gcnew,
	free = gcfree,
}
