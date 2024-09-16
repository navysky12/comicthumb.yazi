local M = {}

function M:peek()
	local cache = ya.file_cache(self)
	if not cache then
		return
	end

	if self:preload() == 1 then
		ya.image_show(cache, self.area)
		ya.preview_widgets(self, {})
	end
end

function M:seek() end

function M:preload()
	local cache = ya.file_cache(self)
	if not cache or fs.cha(cache) then
		return 1
	end

	local list_output = Command("7z")
		:args({ "-ba", "l", tostring(self.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	fs.write(cache, list_output.stdout)
	local awk_output = Command("awk")
		:args({
				[[tolower($0) ~ /\.(jpg|jpeg|png|gif)$/ {print substr($0, index($0,$6))}]],
				tostring(cache)
			})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	local filenames = {}
	for filename in awk_output.stdout:gmatch("[^\n]+") do table.insert(filenames, filename) end
	table.sort(filenames)
	local extract_output = Command("7z")
		:args({ "-so", "e", tostring(self.file.url), filenames[1] })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	return fs.write(cache, extract_output.stdout) and 1 or 2
end

return M
