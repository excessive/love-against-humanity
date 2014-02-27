if not love then
	math.randomseed(os.time())
	love = {
		event = {
			quit = function() end
		},
		math = {
			random = function(...)
				return math.random(...)
			end
		}
	}
	hate = not love
end
