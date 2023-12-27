-- here's a quick hack for debugging
-- it's not meta-lua, not dependent on my parser lib, nothing like that
-- just this: when you require() a file, if the debug flag is set, then grep all --DEBUG: lines to remove the comment
-- usage" lua -lext.debug ..."


-- replace the package.loaders[2] / package.searchers[2] table entry
-- make it to replace file contents before loading


-- TODO will lua 5.1 package.loaders[2] return the filename?
local searchers = assert(package.searchers or package.loaders, "couldn't find searchers")
local oldsearchfile = searchers[2]

-- don't require ext.table just yet ...
local function pack(...)
	local t = {...}
	t.n = select('#', ...)
	return t
end

local function newsearchfile(req, ...)
	--[[ using the old:
	local res = pack(oldsearchfile(req, ...))
	print('require()', req)
	print('...res:', table.unpack(res, 1, res.n))
	return table.unpack(res, 1, res.n)
	--]]
	-- [[ using my replacement:
	local filename, err = package.searchpath(req, package.path)
	if not filename then return err end
	
	--[=[
	return loadfile(filename)
	--]=]
	-- [=[
	local f, err = io.open(filename, 'r')
	if not f then return err end
	local d, err = f:read'*a'
	f:close()
	if err then return err end

	-- and here I gsub all the --DEBUG: strings out of it ...
	d = d:gsub('%-%-DEBUG:', '')

	return load(d, filename)
	--]=]
	--]]
end
searchers[2] = newsearchfile
