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

function M:seek(units)
	local h = cx.active.current.hovered
	if h and h.url == self.file.url then
		local step = ya.clamp(-1, units, 1)
		ya.manager_emit("peek", { math.max(0, cx.active.preview.skip + step), only_if = self.file.url })
	end
end

function M:preload()
	local cache = ya.file_cache(self)
	if not cache or fs.cha(cache) then
		return 1
	end

	local list_output = Command("7z")
		:args({ "-ba", "l", tostring(self.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	local awk_output = Command("awk")
		:args({
			[[length($0) > 53 && tolower(substr($0, 54)) ~ /\.(jpg|jpeg|png|gif)$/ { print substr($0, 54) }]]
		})
		:stdin(list_output:take_stdout())
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	local filenames = {}
	for filename in awk_output.stdout:gmatch("[^\n]+") do
		table.insert(filenames, filename)
	end
	table.sort(filenames)
	self.skip = self.skip >= #filenames and (#filenames - 1) or self.skip

	local extract_output = Command("7z")
		:args({ "-so", "e", tostring(self.file.url), filenames[self.skip + 1] })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	return fs.write(ya.file_cache(self), extract_output.stdout) and 1 or 2
end

return M
