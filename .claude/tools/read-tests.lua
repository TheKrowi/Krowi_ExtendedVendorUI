-- Prints the /kevutest runs in KrowiEVU_Debug.Tests from a saved variables file as tab-separated records for
-- Read-GameTests.ps1, oldest first: RUN <n>, HEAD <key> <value>, STEP <n> <name> <banner text> <time> <screenshot>,
-- LINE <check>; NONE when there is no run.
local chunk, err = loadfile(arg[1])
if not chunk then
    io.stderr:write(tostring(err), '\n')
    os.exit(2)
end
chunk()

local tests = KrowiEVU_Debug and KrowiEVU_Debug.Tests
local runs = tests and (tests.Runs or (tests.LastRun and { tests.LastRun })) -- LastRun: before the history
if not runs or #runs == 0 then
    print('NONE')
    return
end

local function Clean(value)
    return (tostring(value):gsub('[\t\r\n]', ' '))
end

local function Head(key, value)
    if value ~= nil then
        print('HEAD\t' .. key .. '\t' .. Clean(value))
    end
end

for n, run in ipairs(runs) do
    print('RUN\t' .. n)
    Head('Time', run.Time)
    Head('Client', run.Client)
    Head('Version', run.Version)
    Head('Locale', run.Locale)
    Head('Vendor', run.Vendor)
    Head('Items', run.Items)
    Head('Options', run.Options)
    Head('Quality', run.ScreenshotQuality)
    Head('Addons', table.concat(run.Addons or {}, ', '))
    Head('Plugins', table.concat(run.Plugins or {}, ', '))
    Head('Stopped', run.Stopped)
    Head('Restore', run.RestoreError)
    Head('Passed', run.Passed)
    Head('Failed', run.Failed)
    Head('Skipped', run.Skipped)

    for _, step in ipairs(run.Steps or {}) do
        local screenshot = step.Screenshot == true and 'yes' or step.Screenshot == false and 'failed' or ''
        print(('STEP\t%s\t%s\t%s\t%s\t%s'):format(Clean(step.Step), Clean(step.Name), Clean(step.Text or ''), Clean(step.Time or ''), screenshot))
        for _, line in ipairs(step.Lines or {}) do
            print('LINE\t' .. Clean(line))
        end
    end
end