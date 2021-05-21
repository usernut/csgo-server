public Action jointeam(int client, const char[] command, args) {    
    if (!IsPlayer(client)) return Plugin_Continue;

    PrintToChat(client, "\x01 \x07You cannot change your team during a match!");

    return Plugin_Stop;
}

public Action BlockReloadMapOnJoin(int client, const char[] command, int args) {
	if (client != 0) {
        return Plugin_Continue;
    }
    char buffer[PLATFORM_MAX_PATH];

    GetCmdArgString(buffer, sizeof(buffer));
    
    if(StrContains(buffer, " reserved") >= 0 && !GetRealClientsCount()) {
        PrintToServer(" - BLOCK map '%s'", buffer);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}