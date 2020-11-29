#include <sourcemod>
#include <sdktools>
#include <csgo_colors>
#include <zombiereloaded>

#define PLUGIN_NAME					"Zm Teleport"
#define PLUGIN_AUTHOR				"Anubis"
#define PLUGIN_DESCRIPTION	"SourceMod replacement for the Mani teleport functionality"
#define PLUGIN_VERSION			"1.0-A"
#define PLUGIN_URL					""

new Handle:g_hCvar_TeleportEnabled, bool:b_Teleport_Enabled,
	Handle:g_hCvar_AdminEnabled, bool:b_Admin_Enabled;

new Float:originSaves[MAXPLAYERS+1][3];
new Float:angleSaves[MAXPLAYERS+1][3];

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	LoadTranslations("zm_teleport.phrases");
	LoadTranslations("common.phrases");
	
	g_hCvar_TeleportEnabled = CreateConVar("zm_teleport_enabled", "1", "Teleport Players", 0, true, 0.0, true, 1.0);
	g_hCvar_AdminEnabled = CreateConVar("zm_teleport_admin_enabled", "1", "Admin Teleport Players", 0, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_savetele", SaveLocation, "Saves the current location for teleport commands");
	RegConsoleCmd("sm_stele", Teleport, "sm_teleport <#id|name>");
	
	b_Teleport_Enabled = GetConVarBool(g_hCvar_TeleportEnabled);
	b_Admin_Enabled = GetConVarBool(g_hCvar_AdminEnabled);
	
	HookConVarChange(g_hCvar_TeleportEnabled, OnConVarChanged);
	HookConVarChange(g_hCvar_AdminEnabled, OnConVarChanged);
	
	AutoExecConfig(true, "zm_teleport");

}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hCvar_TeleportEnabled)
	{
		b_Teleport_Enabled = bool:StringToInt(newValue);
	}
	else if (convar == g_hCvar_AdminEnabled)
	{
		b_Admin_Enabled = bool:StringToInt(newValue);
	}
}

public OnMapStart()
{
	if(b_Teleport_Enabled)
	{
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			ResetSaves(i);
		}
	}
}

public OnMapEnd()
{
	if(b_Teleport_Enabled)
	{
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			ResetSaves(i);
		}
	}
}

ResetSaves(client)
{
	originSaves[client] = NULL_VECTOR;
	angleSaves[client] = NULL_VECTOR;
}

public Action:SaveLocation(client, args)
{
	if (!IsValidClient(client)) return Plugin_Handled;

	if(!b_Teleport_Enabled)	
	{
		CPrintToChat(client, "%t", "Plugin Disabled");
		return Plugin_Handled;
	}

	if(CheckCommandAccess(client, "tptarget", ADMFLAG_SLAY) && (b_Admin_Enabled))
	{
		if (GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) != -1)
		{
			GetClientAbsOrigin(client, originSaves[client]);
			GetClientAbsAngles(client, angleSaves[client]);
			CPrintToChat(client, "%t", "Current position saved");
		}
		else
		{
			CPrintToChat(client, "%t", "Not On Ground");
		}
		return Plugin_Handled;
	}

	if(ZR_IsClientHuman(client))
	{
		CPrintToChat(client, "%t", "No zombie players save");
		return Plugin_Handled;
	}

	if (GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) != -1)
	{
		GetClientAbsOrigin(client, originSaves[client]);
		GetClientAbsAngles(client, angleSaves[client]);
		CPrintToChat(client, "%t", "Current position saved");
	}
	else
	{
		CPrintToChat(client, "%t", "Not On Ground");
	}
	return Plugin_Handled;
}

public Action:Teleport(client, args)
{
	if (!IsValidClient(client)) return Plugin_Handled;

	if(!b_Teleport_Enabled)	
	{
		CPrintToChat(client, "%t", "Plugin Disabled");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		if(ZR_IsClientHuman(client))
		{
			CPrintToChat(client, "%t", "No zombie players teleport");
			return Plugin_Handled;
		}

		if (IsPlayerAlive(client))
		{
			if ( (GetVectorDistance(originSaves[client], NULL_VECTOR) > 0.00) && (GetVectorDistance(angleSaves[client], NULL_VECTOR) > 0.00) )
			{
				TeleportEntity(client, originSaves[client], angleSaves[client], NULL_VECTOR);
				CPrintToChat(client, "%t", "Teleport Player");
				ResetSaves(client);
			}
			else
			{
				CPrintToChat(client, "%t", "Please save a location first");
			}
		}
		return Plugin_Handled;
	}

	if(CheckCommandAccess(client, "tptarget", ADMFLAG_SLAY))	
	{
		if(!b_Admin_Enabled)	
		{
			CPrintToChat(client, "%t", "Admin Disabled");
			return Plugin_Handled;
		}

		if ( (GetVectorDistance(originSaves[client], NULL_VECTOR) == 0.00) && (GetVectorDistance(angleSaves[client], NULL_VECTOR) == 0.00) )
		{
			CPrintToChat(client, "%t", "Please save a location first");
			return Plugin_Handled;
		}

		new String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));

		new target_list[MAXPLAYERS];	
		new String:target_name[MAX_TARGET_LENGTH];
		new bool:target_ml;
		new target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), target_ml);

		if (target_count > 0)
		{

			for (new i = 0; i < target_count; i++)
			{
				TeleportEntity(target_list[i], originSaves[client], angleSaves[client], NULL_VECTOR);
			}

			new String:admin_name[MAX_NAME_LENGTH];
			GetClientName(client, admin_name, sizeof(admin_name));

			if (strcmp(arg, "@all") == 0)
			{
				CPrintToChatAll("%t", "Teleported all players", admin_name);
			}
			else if (strcmp(arg, "@ct") == 0)
			{
				CPrintToChatAll("%t", "Teleported all Cts", admin_name);
			}
			else if (strcmp(arg, "@t") == 0)
			{
				CPrintToChatAll("%t", "Teleported all Ts", admin_name);
			}
			else
			{
				if (strcmp(admin_name, target_name) == 0)
				{
					CPrintToChatAll("%t", "teleported himself herself", admin_name);
				}
				else
				{
					GetClientName(target_list[0], target_name, sizeof(target_name));
					CPrintToChatAll("%t", "Admin teleported player", admin_name, target_name);
				}
			}

		}
		else if (target_count == COMMAND_TARGET_NONE)
		{
			CPrintToChat(client, "%t", "Couldn t find any player named disconnected", arg);
		}
		else if (target_count == COMMAND_TARGET_NOT_ALIVE || target_count == COMMAND_TARGET_NOT_IN_GAME)
		{
			target_list[0] = FindTarget(client, arg);
			if (target_list[0] == client)
			{
				CPrintToChat(client, "%t", "You re not alive in-game");	
			}
			else
			{
				GetClientName(target_list[0], target_name, sizeof(target_name));
				CPrintToChat(client, "%t", "Player is not alive in-game", target_name);		
			}
		}
		else if (target_count == COMMAND_TARGET_EMPTY_FILTER)
		{
			CPrintToChat(client, "%t", "No matching players found");
		}
		return Plugin_Handled;
	}
	CPrintToChat(client, "%t", "No admin command");	
	return Plugin_Handled;
}

public IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
		return false;
	
	return true;
}