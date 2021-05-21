#include <sourcemod>

#pragma semicolon 1

public OnPluginStart() {
    HookEvent("server_cvar", server_cvar, EventHookMode_Pre);
}

public Action server_cvar(Handle event, const String:name[], bool:dontBroadcast) {
    return Plugin_Handled;
}