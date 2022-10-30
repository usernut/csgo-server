public bool IsWarmup() {
    return GameRules_GetProp("m_bWarmupPeriod") != 0;
}

public bool IsPlayer(int client) {
    return IsValid(client) && !IsFakeClient(client);
}

public bool IsValid(int client) {
    return client && client <= MaxClients && IsClientInGame(client);
}

public bool isUserInGame(char[] playerSteamid) {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsPlayer(client)) continue;

        char clientSteamid[32];
        GetClientAuthId(client, AuthId_SteamID64, clientSteamid, sizeof(clientSteamid));

        if(!StrEqual(playerSteamid, clientSteamid)) continue;

        return true;
    }
    return false;
}

public int GetRealClientsCount() {
    int clients = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i)) clients++;
    }
    return clients;
}

public int GetTeamPlayersCount(int team) {
    int clients = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && GetClientTeam(i) == team) clients++;
    }
    return clients;
}

public void KickAllPlayers(float time, char[] reason) {
    DataPack pack;
    CreateDataTimer(time, Timer_KickAllPlayers, pack, TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteString(reason);
}

public Action Timer_KickAllPlayers(Handle timer, Handle dataPack) {
    DataPack pack = view_as<DataPack>(dataPack);
    pack.Reset();

    char reason[128];
    pack.ReadString(reason, sizeof(reason));

    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i)) KickClient(i, reason);
    }

    return Plugin_Stop;
}

public bool isHalfTime() {
    bool halftimeEnabled = FindConVar("mp_halftime").IntValue ==  0;
    if (halftimeEnabled) return false;

    int roundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");
    int roundsHalf = FindConVar("mp_maxrounds").IntValue / 2;
    int roundsOTHalf = FindConVar("mp_overtime_maxrounds").IntValue / 2;

    int otrounds = roundsPlayed - roundsHalf * 2;

    return roundsPlayed == roundsHalf || roundsPlayed > roundsHalf * 2 && ((otrounds) + roundsOTHalf) % (2 * roundsOTHalf) == 0
}

// stock bool Record(const char[] demoName) {
//   char szDemoName[256];
//   strcopy(szDemoName, sizeof(szDemoName), demoName);
//   ReplaceString(szDemoName, sizeof(szDemoName), "\"", "\\\"");
//   ServerCommand("tv_record \"%s\"", szDemoName);

//   if (!IsTVEnabled()) {
//     LogError("Autorecording will not work with current cvar \"tv_enable\"=0. Set \"tv_enable 1\" in server.cfg (or another config file) to fix this.");
//     return false;
//   }

//   return true;
// }

// stock void StopRecording() {
//   ServerCommand("tv_stoprecord");
//   LogDebug("Calling Get5_OnDemoFinished(file=%s)", g_DemoFileName);
//   Call_StartForward(g_OnDemoFinished);
//   Call_PushString(g_DemoFileName);
//   Call_Finish();
// }