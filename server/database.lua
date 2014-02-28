if (pcall(require, "luapgsql.pgsql")) then
	return require "database_pgsql"
else
	return require "database_dummy"
end
