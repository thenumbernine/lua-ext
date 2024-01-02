-- here's a quick hack for debugging
-- it's not meta-lua, not dependent on my parser lib, nothing like that
-- just this: when you require() a file, if the debug tag is set, then grep all --DEBUG: lines to remove the comment
-- usage" lua -lext.debug ..."

-- replace the package.loaders[2] / package.searchers[2] table entry
-- make it to replace file contents before loading


-- TODO will lua 5.1 package.loaders[2] return the filename?
local searchers = assert(package.searchers or package.loaders, "couldn't find searchers")
local oldsearchfile = searchers[2]

-- don't require ext.string just yet ...
local escapeFind = '[' .. ([[^$()%.[]*+-?]]):gsub('.', '%%%1') .. ']'
local function patescape(s)
	return (s:gsub(escapeFind, '%%%1'))
end

local tags = {}

local function newsearchfile(req, ...)
	local filename, err = package.searchpath(req, package.path)
	if not filename then return err end

	local f, err = io.open(filename, 'r')
	if not f then return err end
	local d, err = f:read'*a'
	f:close()
	if err then return err end

	-- and here I gsub all the --DEBUG: strings out of it ...
	d = d:gsub(patescape('--DEBUG:'), '')
	-- gsub all --DEBUG(${tag}): strings out as well
	for _,tag in ipairs(tags) do
		d = d:gsub(patescape('--DEBUG('..tag..'):'), '')
	end

	local f, err = load(d, filename)
	return f or err
end
searchers[2] = newsearchfile

--[[
TODO debug-levels? debug-tags?  enable dif tags for dif reports?
have this return a function which you can call with some kind of tags to be used for how to parse out debug stuff...

lua -lext.debug ...
	to turn all on?  or just turn the no-tags stuff on?
lua -e "require'ext.debug' 'list,of,comma,separated,tags,to,enable'" ...
	to enable specific runlevel tags
--]]
return function(reqtags)
	local t = type(reqtags)
	tags = {}
	if t == 'table' then	-- list-of-strings
		tags = reqtags
	elseif t == 'string' then
		for k in reqtags:gmatch'[^,]+' do
			table.insert(tags, k)
		end
	end
end
