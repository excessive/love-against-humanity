-- https://github.com/mbalmer/luapgsql.git
-- http://www.postgresql.org/docs/9.1/static/libpq-exec.html#LIBPQ-EXEC-SELECT-INFO
require "pgsql"

local class = require "libs.hump.class"

local Database_PgSQL = class {}

function Database_PgSQL:init()
	self.connection = pgsql.connectdb('dbname=cah user=cah')
	print(self.connection:errorMessage())
	if self.connection:status() ~= pgsql.CONNECTION_OK then
		print "Unable to connect to PgSQL database."
		print(self.connection:errorMessage())
	end
end

function Database_PgSQL:get_table(result)
	local rows = {}
	for i = 1, result:ntuples() do
		table.insert(rows, {})
		
		for k = 1, result:nfields() do
			rows[#rows][result:fname(k)] = result:getvalue(i, k)
		end
	end
	
	for k, row in pairs(rows) do
		for name, col in pairs(row) do
			print(k, name, col)
		end
	end
	
	return rows
end

function Database_PgSQL:get_cards(type, packs)
	local where = ""
	for _, pack in pairs(packs) do
		where = string.format("%s pack=`%s` or ", where, pack)
	end
	
	where = where:sub(1, -5)
	
	local sql = string.format(
		"select distinct * from %s where %s order by random()",
		type .. "_cards", where
	)
	local result = self.connection:exec(sql)
	
	return self:get_table(result)
end

function Database_PgSQL:get_packs()
	local sql = "select * from card_set"
	local result = self.connection:exec(sql)
	
	return self:get_table(result)
end

return Database_PgSQL
