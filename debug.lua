--[[
Here's a quick hack for debugging
It's not meta-lua, not dependent on my parser lib, nothing like that
It does use my new load() shim layer ext.load
Just this: when you require() a file, if the debug tag is set, then grep all --DEBUG: lines to remove the comment
Usage" lua -lext.debug ..."
--]]

-- don't require ext.string just yet ...
local escapeFind = '[' .. ([[^$()%.[]*+-?]]):gsub('.', '%%%1') .. ']'
local function patescape(s)
	return (s:gsub(escapeFind, '%%%1'))
end

local tags = {}

--[[
Strip out DEBUG: and DEBUG(...): tags based on what tags were requested via `require 'ext.debug'(tag1,tag2,...)`

d = data
source = for require'd files will be an absolute file path, from ext.load, from package.searchers[2]

TODO How to handle multiple tags?  Then I get into AND vs OR queries
TODO Automatic tags for filenames and for functions (use parser.xform_load for functions / getting function names).  Abs vs rel source paths?
--]]
table.insert(require 'ext.load'().xforms, function(d, source)
	-- and here I gsub all the --DEBUG: strings out of it ...
	d = d:gsub(patescape('--DEBUG:'), '')
	-- gsub all --DEBUG(${tag}): strings out as well
	for _,tag in ipairs(tags) do
		d = d:gsub(patescape('--DEBUG('..tag..'):'), '')
	end
	return d
end)

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
