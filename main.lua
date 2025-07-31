---@diagnostic disable: undefined-field, undefined-global --temp while fields are incomplete within types.yazi
---@diagnostic disable: redefined-local --reusing err
local M = {}

function M:peek(job)
	local ok, err = self:preload(job)
	if not ok or err then
		ya.dbg("Peek failed during preload: %s", err)
		return
	end

	local cache = ya.file_cache(job)
	if not cache then
		ya.dbg("No cache found for job")
		return
	end

	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err)
end

function M:seek(job)
	-- TODO: cx.active.preview.skip isn't the same as job.skip, somehow carry over #filenames?
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		ya.dbg("Hovered Element doesn't match job")
		return
	end

	local step = math.max(0, cx.active.preview.skip + ya.clamp(-1, job.units, 1))
	ya.dbg("Seek", tostring(step), tostring(job.file.url))
	ya.emit("peek", { step, only_if = job.file.url })
end

function M:preload(job)
	local list_child, err = Command("7z")
		:arg({ "-ba", "l", tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not list_child then
		return false, Err("Failed to spawn 7z: %s", err)
	end

	local list_stdout = list_child:take_stdout()
	if not list_stdout then
		return false, Err("Failed to list archive with 7z")
	end

	local awk_child, err = Command("awk")
		:arg({[[length($0) > 53 && tolower(substr($0, 54)) ~ /\.(jpg|jpeg|png|gif)$/ { print substr($0, 54) }]]})
		:stdin(list_stdout)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not awk_child then
		return false, Err("Failed to spawn awk: %s", err)
	end

	local awk_output, err = awk_child:wait_with_output()
	if not awk_output then
		return false, Err("Can't read awk output: %s", err)
	end

	local filenames = {}
	for filename in awk_output.stdout:gmatch("[^\n]+") do
		table.insert(filenames, filename)
	end
	table.sort(filenames)
	job.skip = job.skip >= #filenames and (#filenames - 1) or job.skip
	ya.dbg("Table", tostring(job.skip), tostring(#filenames - 1))

	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end

	local extract_output, err = Command("7z")
		:arg({ "-so", "e", tostring(job.file.url), filenames[job.skip + 1] })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not extract_output then
		return false, Err("Failed to start 7z to extract image: %s", err)
	end

	local write_output, err = fs.write(cache, extract_output.stdout)
	if not write_output then
		return false, Err("Failed to write cache: %s", err)
	end

	-- Unsure whether to simply return full resolution or allow image_precache() to deal with it
	-- Both work fine, the overhead of calling extra function is not noticeable
	return ya.image_precache(cache, cache)
end

return M
