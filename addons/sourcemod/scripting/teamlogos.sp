#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define MAX_TEAMNAME_LENGTH 128

Handle g_hTeamLogos = null;
Handle g_hTeamLogo1 = null;
Handle g_hTeamLogo2 = null;
Handle g_hTeamName1 = null;
Handle g_hTeamName2 = null;

Handle g_hRandomLogos = null;
bool g_bRandomLogos = false;

Handle g_hDefaultTeams = null;
bool g_bDefaultTeams = false;

Handle g_hTeamNames = null;
bool g_bTeamNames = false;

Handle g_hHalftimeTeamswitch = null;
bool g_bHalftimeTeamswitch = false;

Handle g_hAutoLogos = null;
bool g_bAutoLogos = false;

char g_cTeamLogo1Cache[MAX_TEAMNAME_LENGTH];
char g_cTeamLogo2Cache[MAX_TEAMNAME_LENGTH];

static bool g_bCacheTeamLogo = true;

public Plugin myinfo =
{
    name = "Team Logo Management",
    author = "Neuro Toxin, uspeek, crashzk",
    description = "Team Logo Management",
    version = "1.5.0"
};

public void OnPluginStart()
{
	g_hTeamLogo1 = FindConVar("mp_teamlogo_1");
	if (g_hTeamLogo1 == null)
	{
		SetFailState("Unable to cache convar handle for 'mp_teamlogo_1'");
		return;
	}
	HookConVarChange(g_hTeamLogo1, OnConvarChanged);
	
	g_hTeamLogo2 = FindConVar("mp_teamlogo_2");
	if (g_hTeamLogo2 == null)
	{
		SetFailState("Unable to cache convar handle for 'mp_teamlogo_2'");
		return;
	}
	HookConVarChange(g_hTeamLogo2, OnConvarChanged);
	
	g_hTeamName1 = FindConVar("mp_teamname_1");
	if (g_hTeamName1 == null)
	{
		SetFailState("Unable to cache convar handle for 'mp_teamname_1'");
		return;
	}
	
	g_hTeamName2 = FindConVar("mp_teamname_2");
	if (g_hTeamName2 == null)
	{
		SetFailState("Unable to cache convar handle for 'mp_teamname_2'");
		return;
	}

	g_hRandomLogos = CreateConVar("teamlogo_randomlogos", "0", "Enables selection of random team logos on map load");
	g_bRandomLogos = GetConVarBool(g_hRandomLogos);
	HookConVarChange(g_hRandomLogos, OnConvarChanged);
	
	g_hDefaultTeams = CreateConVar("teamlogo_defaultlogos", "0", "Adds the Valve default logos to the team logo list if 'teamlogo_randomlogo' is set to 1");
	g_bDefaultTeams = GetConVarBool(g_hDefaultTeams);
	HookConVarChange(g_hDefaultTeams, OnConvarChanged);
	
	g_hTeamNames = CreateConVar("teamlogo_teamnames", "0", "Team names will be loaded from .cfg files with the same name and location as the logo file");
	g_bTeamNames = GetConVarBool(g_hTeamNames);
	HookConVarChange(g_hTeamNames, OnConvarChanged);
	
	g_hHalftimeTeamswitch = CreateConVar("teamlogo_halftime_teamswitch", "0", "Plugin will switch team logos and names at half time");
	g_bHalftimeTeamswitch = GetConVarBool(g_hHalftimeTeamswitch);
	HookConVarChange(g_hHalftimeTeamswitch, OnConvarChanged);
	
	g_hAutoLogos = CreateConVar("teamlogo_autologos", "0", "Plugin will auto-select team logos based on player clan tags");
	g_bAutoLogos = GetConVarBool(g_hAutoLogos);
	HookConVarChange(g_hAutoLogos, OnConvarChanged);
	
	HookEvent("announce_phase_end", OnAnnouncePhaseEnd);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
}

public void OnConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (cvar == g_hRandomLogos)
	{
		g_bRandomLogos = StringToInt(newVal) == 0 ? false : true;
		OnMapStart();
	}
	else if (cvar == g_hDefaultTeams)
	{
		g_bDefaultTeams = StringToInt(newVal) == 0 ? false : true;
		OnMapStart();
	}
	else if (cvar == g_hTeamNames)
	{
		g_bTeamNames = StringToInt(newVal) == 0 ? false : true;
		OnMapStart();
	}
	else if (cvar == g_hTeamLogo1)
	{
		if (g_bCacheTeamLogo)
			CacheTeamLogo(CS_TEAM_CT);
		
		if (g_bTeamNames && !StrEqual(oldVal, newVal))
			SetTeamName(newVal, 1);
	}
	else if (cvar == g_hTeamLogo2)
	{
		if (g_bCacheTeamLogo)
			CacheTeamLogo(CS_TEAM_T);
			
		if (g_bTeamNames && !StrEqual(oldVal, newVal))
			SetTeamName(newVal, 2);
	}
	else if (cvar == g_hHalftimeTeamswitch)
	{
		g_bHalftimeTeamswitch = StringToInt(newVal) == 0 ? false : true;
	}
	else if (cvar == g_hAutoLogos)
	{
		g_bAutoLogos = StringToInt(newVal) == 0 ? false : true;
		if (g_bAutoLogos)
		{
			SetTeamAutoLogo(CS_TEAM_CT);
			SetTeamAutoLogo(CS_TEAM_T);
		}
		else
		{
			RestoreTeamLogo(CS_TEAM_CT);
			RestoreTeamLogo(CS_TEAM_T);
		}
	}
}

public void OnMapStart()
{
	if (g_hTeamLogos != null)
		CloseHandle(g_hTeamLogos);
	
	if (g_bRandomLogos)
		g_hTeamLogos = CreateArray(MAX_TEAMNAME_LENGTH);
		
	AddTeamLogosToDownloadTable();
	
	if (g_bDefaultTeams && g_bRandomLogos)
		AddDefaultTeamLogos();
}

public void OnConfigsExecuted()
{
	if (g_bRandomLogos)
	{
		int logocount = GetArraySize(g_hTeamLogos);
		if (logocount == 0)
		{
			PrintToServer("[SM] You can add team logos to 'resource/flash/econ/tournaments/teams/' or enable 'teamlogo_usedefaulticons'");
			return;	
		}
		
		SetTeamLogos(logocount);
	}
	
	if (g_bTeamNames)
		SetTeamNames();
}

stock void AddTeamLogosToDownloadTable()
{
	Handle dir = OpenDirectory("resource/flash/econ/tournaments/teams/");
	if (dir == null)
	{
		LogError("[SM] Unable to read directory: 'resource/flash/econ/tournaments/teams'");
		return;
	}
	FileType type;
	char filename[PLATFORM_MAX_PATH];
	char fullpath[PLATFORM_MAX_PATH];
	while (ReadDirEntry(dir, filename, sizeof(filename), type))
	{
		if (type != FileType_File)
			continue;
		
		if (!StrEqual(filename[strlen(filename) - 4], ".png"))
			continue;
		
		PrintToServer("[SM] Loading team logo: %s", filename);
		Format(fullpath, sizeof(fullpath), "resource/flash/econ/tournaments/teams/%s", filename);
		AddFileToDownloadsTable(fullpath);
		
		if (g_bRandomLogos)
		{
			filename[strlen(filename) - 4] = '\0';
			PushArrayString(g_hTeamLogos, filename);
		}
	}
	CloseHandle(dir);
	
	// check for Panorama UI images
	dir = OpenDirectory("materials/panorama/images/tournaments/teams/");
	if (dir == null)
	{
		LogError("[SM] Unable to read directory: 'materials/panorama/images/tournaments/teams'");
		return;
	}
	
	while (ReadDirEntry(dir, filename, sizeof(filename), type))
	{
		if (type != FileType_File)
			continue;
		
		if (!StrEqual(filename[strlen(filename) - 4], ".svg") && !StrEqual(filename[strlen(filename) - 4], ".png"))
			continue;
		
		PrintToServer("[SM] Loading team logo: %s", filename);
		Format(fullpath, sizeof(fullpath), "materials/panorama/images/tournaments/teams/%s", filename);
		AddFileToDownloadsTable(fullpath);
		
		if (g_bRandomLogos)
		{
			filename[strlen(filename) - 4] = '\0';
			PushArrayString(g_hTeamLogos, filename);
		}
	}
	CloseHandle(dir);
}

stock void SetTeamLogos(int logocount)
{
	int team1logo; int team2logo;
	if (logocount == 1)
	{
		team1logo = 0;
		team2logo = 0;
	}
	else if (logocount == 2)
	{
		team1logo = GetRandomInt(0, 1);
		if (team1logo == 0)
			team2logo = 1;
		else
			team2logo = 0;
	}
	else
	{
		team1logo = GetRandomInt(0, logocount - 1);
		team2logo = GetRandomInt(0, logocount - 1);
		
		while (team1logo == team2logo)
			team2logo = GetRandomInt(0, logocount - 1);
	}

	char logo1[MAX_TEAMNAME_LENGTH]; char logo2[MAX_TEAMNAME_LENGTH];
	GetArrayString(g_hTeamLogos, team1logo, logo1, MAX_TEAMNAME_LENGTH);
	GetArrayString(g_hTeamLogos, team2logo, logo2, MAX_TEAMNAME_LENGTH);
	
	SetConVarString(g_hTeamLogo1, logo1);
	SetConVarString(g_hTeamLogo2, logo2);
	
	PrintToServer("[SM] mp_teamlogo_1 set to %s", logo1);
	PrintToServer("[SM] mp_teamlogo_2 set to %s", logo2);
}

stock void AddDefaultTeamLogos()
{
	PushArrayString(g_hTeamLogos, "astr1");
	PushArrayString(g_hTeamLogos, "big1");
	PushArrayString(g_hTeamLogos, "boom1");
	PushArrayString(g_hTeamLogos, "chs1");
	PushArrayString(g_hTeamLogos, "cld91");
	PushArrayString(g_hTeamLogos, "col1");
	PushArrayString(g_hTeamLogos, "dig1");
	PushArrayString(g_hTeamLogos, "dtna1");
	PushArrayString(g_hTeamLogos, "eg1");
	PushArrayString(g_hTeamLogos, "enc1");
	PushArrayString(g_hTeamLogos, "faze1");
	PushArrayString(g_hTeamLogos, "fnt1");
	PushArrayString(g_hTeamLogos, "fria1");
	PushArrayString(g_hTeamLogos, "g3x1");
	PushArrayString(g_hTeamLogos, "g21");
	PushArrayString(g_hTeamLogos, "impe1");
	PushArrayString(g_hTeamLogos, "isur1");
	PushArrayString(g_hTeamLogos, "keyd1");
	PushArrayString(g_hTeamLogos, "liqu1");
	PushArrayString(g_hTeamLogos, "mibr1");
	PushArrayString(g_hTeamLogos, "mous1");
	PushArrayString(g_hTeamLogos, "navi1");
	PushArrayString(g_hTeamLogos, "nip1");
	PushArrayString(g_hTeamLogos, "pain1");
	PushArrayString(g_hTeamLogos, "redc1");
	PushArrayString(g_hTeamLogos, "tone1");
	PushArrayString(g_hTeamLogos, "vita1");
	PushArrayString(g_hTeamLogos, "vp1");
	PushArrayString(g_hTeamLogos, "w7m1");
}

stock void SetTeamName(const char[] logo, int team)
{
	char cfgpath[PLATFORM_MAX_PATH]; char teamname[MAX_TEAMNAME_LENGTH];
	Format(cfgpath, sizeof(cfgpath), "resource/flash/econ/tournaments/teams/%s.cfg", logo);
	Handle cfgstream = OpenFile(cfgpath, "r");
	
	if (cfgstream == INVALID_HANDLE)
	{
		LogError("Teamname config not found for logo '%s'", logo);
		return;
	}
	
	if (ReadFileString(cfgstream, teamname, MAX_TEAMNAME_LENGTH) > 0)
	{
		if (team == 1)
			SetConVarString(g_hTeamName1, teamname);
		else
			SetConVarString(g_hTeamName2, teamname);
	}
	
	CloseHandle(cfgstream);
}

stock void SetTeamNames()
{
	char logo[MAX_TEAMNAME_LENGTH];
	GetConVarString(g_hTeamLogo1, logo, MAX_TEAMNAME_LENGTH);
	if (!StrEqual(logo, ""))
		SetTeamName(logo, 1);
	
	GetConVarString(g_hTeamLogo2, logo, MAX_TEAMNAME_LENGTH);
	if (!StrEqual(logo, ""))
		SetTeamName(logo, 2);
}

public Action OnAnnouncePhaseEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bTeamNames || !g_bHalftimeTeamswitch)
		return Plugin_Continue;
		
	char logo1[MAX_TEAMNAME_LENGTH]; char logo2[MAX_TEAMNAME_LENGTH];
	
	GetConVarString(g_hTeamLogo1, logo1, MAX_TEAMNAME_LENGTH);
	if (StrEqual(logo1, ""))
		return Plugin_Continue;

	GetConVarString(g_hTeamLogo2, logo2, MAX_TEAMNAME_LENGTH);
	if (StrEqual(logo2, ""))
		return Plugin_Continue;
		
	SetConVarString(g_hTeamLogo1, logo2);
	SetConVarString(g_hTeamLogo2, logo1);
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bAutoLogos)
		return Plugin_Continue;
		
	SetTeamAutoLogo(CS_TEAM_T);
	SetTeamAutoLogo(CS_TEAM_CT);
	return Plugin_Continue;
}

public Action OnPlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bAutoLogos)
		return Plugin_Continue;
		
	SetTeamAutoLogo(CS_TEAM_T);
	SetTeamAutoLogo(CS_TEAM_CT);
	return Plugin_Continue;
}

public Action OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bAutoLogos)
		return Plugin_Continue;
		
	SetTeamAutoLogo(CS_TEAM_T);
	SetTeamAutoLogo(CS_TEAM_CT);
	return Plugin_Continue;
}

public void SetTeamAutoLogo(int team)
{	
	char name[MAX_TEAMNAME_LENGTH];
	bool found = false;
	bool match = true;
	
	for (int client=1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;
		
		if (GetClientTeam(client) != team)
			continue;
			
		char newname[MAX_TEAMNAME_LENGTH];
		CS_GetClientClanTag(client, newname, MAX_TEAMNAME_LENGTH);
		if (newname[0] != EOS)
		{
			if (found)
			{
				if (!StrEqual(name, newname))
				{
					match = false;
					break;
				}
			}
			else
			{
				found = true;
				strcopy(name, MAX_TEAMNAME_LENGTH, newname);
			}
		}
	}
	
	if (found && match)
	{
		if (team == CS_TEAM_CT)
			team = 1;
		else if (team == CS_TEAM_T)
			team = 2;
		
		char logo[6];
		int j=0;
		for (int i=0; i<= MAX_TEAMNAME_LENGTH; i++)
		{
			if (name[i] == EOS || j == 5)
			{
				logo[j] = EOS;
				break;
			}
			else if (IsCharAlpha(name[i]) || IsCharNumeric(name[i]))
			{
				logo[j] = name[i];
				j++;
			}
		}
		
		g_bCacheTeamLogo = false;
		ServerCommand("mp_teamlogo_%d \"%s\"", team, logo);
		g_bCacheTeamLogo = true;
	}
	else
		RestoreTeamLogo(team);
}

public void CacheTeamLogo(int team)
{
	if (team == CS_TEAM_CT)
		GetConVarString(g_hTeamLogo1, g_cTeamLogo1Cache, MAX_TEAMNAME_LENGTH);
	else if (team == CS_TEAM_T)
		GetConVarString(g_hTeamLogo2, g_cTeamLogo2Cache, MAX_TEAMNAME_LENGTH);
}

public void RestoreTeamLogo(int team) 
{
	if (team == CS_TEAM_CT)
		ServerCommand("mp_teamlogo_1 \"%s\"", g_cTeamLogo1Cache);
	else if (team == CS_TEAM_T)
		ServerCommand("mp_teamlogo_2 \"%s\"", g_cTeamLogo2Cache);
}
