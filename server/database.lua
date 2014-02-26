require "luapgsql.pgsql"

local Database = class {}

function Database:init()
	self.connection = pgsql.connectdb('dbname=cah user=cah')
	print(self.connection:errorMessage())
	if self.connection:status() ~= pgsql.CONNECTION_OK then
		print "Unable to connect to PgSQL database."
		print(self.connection:errorMessage())
	end
end

function Database:pick_card(type)
	local rows = self.connection:exec("select * from black_cards")
	print(rows:ntuples())
	--print(self.connection:errorMessage())
end
