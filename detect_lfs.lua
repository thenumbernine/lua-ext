local detect_ffi = require 'ext.detect_ffi'
local lfs
local function detect_lfs()
	if lfs ~= nil then
		local result
		result, lfs = pcall(require, detect_ffi() and 'lfs_ffi' or 'lfs')
		if not result then 
			lfs = false	-- right? I can do this right?
		end
	end
	return lfs
end
return detect_lfs
