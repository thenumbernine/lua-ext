-- this runs just once and then gets cached in package.path
-- but return the function, not the value, because the value could be false, which (I don't believe) package.path will cache
local result, ffi
local function detect_ffi()
	if result == nil then
		result, ffi = pcall(require, 'ffi')
	end
	return ffi
end
return detect_ffi
