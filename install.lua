-- ============================================
-- ChunkMine Installer
-- wget https://raw.githubusercontent.com/JJBanana13/Chunkminer/main/install.lua install.lua
-- install.lua disk
-- ============================================

local args = {...}
local target = args[1] or 'disk'
if target == 'disk' then target = '/disk' end

local base = 'https://raw.githubusercontent.com/JJBanana13/Chunkminer/main/'

local files = {
    'hub.lua',
    'hub_files/basics.lua',
    'hub_files/config.lua',
    'hub_files/events.lua',
    'hub_files/monitor.lua',
    'hub_files/report.lua',
    'hub_files/startup.lua',
    'hub_files/state.lua',
    'hub_files/update',
    'hub_files/user.lua',
    'hub_files/whosmineisitanyway.lua',
    'turtle.lua',
    'turtle_files/actions.lua',
    'turtle_files/basics.lua',
    'turtle_files/config.lua',
    'turtle_files/mastermine.lua',
    'turtle_files/receive.lua',
    'turtle_files/report.lua',
    'turtle_files/startup.lua',
    'turtle_files/state.lua',
    'turtle_files/update',
    'pocket.lua',
    'pocket_files/info.lua',
    'pocket_files/report.lua',
    'pocket_files/startup.lua',
    'pocket_files/update',
    'pocket_files/user.lua',
}

local empty = {
    'hub_files/updated',
    'turtle_files/updated',
    'pocket_files/updated',
}

print('=== ChunkMine Installer ===')
print('Ziel: ' .. target)
print('')

for _, dir in pairs({'hub_files','turtle_files','pocket_files'}) do
    local p = fs.combine(target, dir)
    if not fs.exists(p) then fs.makeDir(p) end
end

local ok, fail = 0, 0
for i, file in pairs(files) do
    local path = fs.combine(target, file)
    if fs.exists(path) then fs.delete(path) end
    write(string.format('[%d/%d] %s ... ', i, #files, file))
    shell.run('wget', base .. file, path)
    if fs.exists(path) then
        ok = ok + 1
        print('OK')
    else
        fail = fail + 1
        print('FEHLER')
    end
end

for _, file in pairs(empty) do
    local p = fs.combine(target, file)
    if not fs.exists(p) then fs.open(p, 'w').close() end
end

print('')
print(ok .. '/' .. #files .. ' Dateien geladen')
if fail > 0 then
    print(fail .. ' Fehler - pruefe HTTP config!')
end
print('')
print('Naechste Schritte:')
print('  1. edit ' .. target .. '/hub_files/config.lua')
print('     -> mine_entrance = {x=?, y=?, z=?}')
print('  2. ' .. target .. '/hub.lua')
print('  3. Turtles: ' .. target .. '/turtle.lua <HUB_ID>')
print('  4. Am Hub: on')
