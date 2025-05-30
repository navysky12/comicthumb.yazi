local M = {}

function M:peek(job)
	local ok, err = self:preload(job)
	if not ok or err then return end

	local cache = ya.file_cache(job)
	if not cache then return end

	ya.dbg("Peek", tostring(job.skip), tostring(cache))

	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err and ui.Text(tostring(err)):area(job.area):wrap(ui.Wrap.YES))
end

function M:seek(job)
	-- TODO: cx.active.preview.skip isn't the same as job.skip, somehow carry over #filenames?
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then return end

	local step = math.max(0, cx.active.preview.skip + ya.clamp(-1, job.units, 1))
	ya.dbg("Seek", tostring(step), tostring(job.file.url))
	ya.emit("peek", { step, only_if = job.file.url })
end

function M:preload(job)
	local list_child = Command("7z")
		:arg({ "-ba", "l", tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	local awk_child = Command("awk")
		:arg({
			[[length($0) > 53 && tolower(substr($0, 54)) ~ /\.(jpg|jpeg|png|gif)$/ { print substr($0, 54) }]]
		})
		:stdin(list_child:take_stdout())
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	local awk_output = awk_child:wait_with_output()
	local filenames = {}
	for filename in awk_output.stdout:gmatch("[^\n]+") do
		table.insert(filenames, filename)
	end
	table.sort(filenames)
	job.skip = job.skip >= #filenames and (#filenames - 1) or job.skip
	ya.dbg("Table", tostring(job.skip), tostring(#filenames - 1))

	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then return true end

	local extract_output = Command("7z")
		:arg({ "-so", "e", tostring(job.file.url), filenames[job.skip + 1] })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	local write_output, write_err = fs.write(cache, extract_output.stdout)
	if not write_output then
		return false, Err("Failed to write cache: %s", write_err)
	end

	return true
end

return M
