if (pcall(require, "pgsql")) then
	return require "database_pgsql"
else
	return require "database_dummy"
end
