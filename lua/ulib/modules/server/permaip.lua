--[[
	Please do not change anything in this file.
]]--

local ip_cache = {}

local function LogIP(ply, ip)
	ip_cache[ip] = true
	sql.Query("INSERT INTO ulib_ip_bans (ip, steamid) VALUES ('" .. ip .."', '" .. ply:SteamID64() .. "')")
end

local function BanIP(ply, ip)
	ULib.ban(ply, 0, "Attempt to circumvent permanent ban")
end

-- can't use ULibPlayerBanned here because it only provides their SteamID, and they're kicked before it's called so we can't access player.GetBySteamID
local function OnPlayerBanned(ply)
	if not ULib.bans[ply:SteamID()] or ULib.bans[ply:SteamID()].unban ~= 0 then return end
	local ip = ply:IPAddress():sub(1, -7)
	LogIP(ip)
end
hook.Add("PlayerDisconnected", "OnPlayerBanned", OnPlayerBanned)

local function IsPlayerBanned(ply)
	local ip = ply:IPAddress():sub(1, -7) -- strip port from IP

	local result = sql.QueryRow("SELECT * FROM ulib_ip_bans WHERE ip = '" .. ip .. "'")

	if (result or ip_cache[ip]) and not ULib.bans[ply:SteamID()] then
		BanIP(ply, ip)
	end
end
hook.Add("PlayerInitialSpawn", "CheckPlayerBanned_InitialSpawn", IsPlayerBanned)

if not sql.TableExists("ulib_ip_bans") then
	sql.Query("CREATE TABLE ulib_ip_bans (ip TEXT NOT NULL PRIMARY KEY, steamid TEXT)")
end
