public bool IsWarmup() {
    return GameRules_GetProp("m_bWarmupPeriod") != 0;
}

public bool IsPlayer(int client) {
    return IsValid(client) && !IsFakeClient(client);
}

public bool IsValid(int client) {
    return client && client <= MaxClients && IsClientInGame(client);
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

public void KickAllPlayers(const char[] reason) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i)) KickClient(i, reason);
    }
}

public bool isHalfTime() {
    bool halftimeEnabled = FindConVar("mp_halftime").IntValue ==  0;
    if (halftimeEnabled) return false;

    int roundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");
    int roundsHalf = FindConVar("mp_maxrounds").IntValue / 2;
    int roundsOTHalf = FindConVar("mp_overtime_maxrounds").IntValue / 2;

    int otrounds = roundsPlayed - roundsHalf * 2;

    if (roundsPlayed == roundsHalf || roundsPlayed > roundsHalf * 2 && ((otrounds) + roundsOTHalf) % (2 * roundsOTHalf) == 0)
        return true;

    return false;
}
//0 - team_id, 1 - team, 2 - user_id
// public int getMemberInfo(ArrayList members, int client, int index) {
//     char clientSteamid[32];
//     GetClientAuthId(client, AuthId_SteamID64, clientSteamid, sizeof(clientSteamid));

//     for (int j = 0; j < members.Length; j++) {
//         ArrayList member = members.Get(j);

//         char memberSteamid[32];
//         member.GetString(3, memberSteamid, sizeof(memberSteamid));

//         if(!StrEqual(memberSteamid, clientSteamid)) continue;

//         return member.Get(index);
//     }

//     return -1;
// }

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


// public void UpdatePlayerStats() {
// 	int iEnt = FindEntityByClassname(-1, "cs_player_manager"); // GetPlayerResourceEntity()
// 	for(int i = 1; i <= MaxClients; i++) {
// 		if(!IsValidClient(i)) continue;

// 		int kills = GetEntProp(iEnt, Prop_Send, "m_iKills", _, i);
// 		int deaths = GetEntProp(iEnt, Prop_Send, "m_iDeaths", _, i);
// 		int MVPs = GetEntProp(iEnt, Prop_Send, "m_iMVPs", _, i);
//         int hs = GetEntProp(iEnt, Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, i);

// 	}
// }

// public void OnClientPutInServer(int client) {
//     KickClient(client, "Join Our New IP: XXX.XXX.XXX.XXX");
// }

// public void OnMapStart() {
// 	CreateTimer(g_aConVarlist.fCalcTime, TimerCheckAfk, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
// }

// enum struct PlayerChecks_s {
// 	int iPingClient;
// 	int iPingCheckFail;
// 	float fOldAngles[3]; // Roll, Yaw, Pitch
// 	float fOldPos[3]; // X, Y, Z
// 	float fAfkCheckTime;
// 	float fAntiCampCheckTime;
// }
// PlayerChecks_s g_aPlayerCheks[MAXPLAYERS + 1];

// public Action TimerCheckAfk(Handle timer, any data) {
// 	float fGetAngles[3], fGetPos[3], fAfkCalcTime, fAntiCampCalcTime; int iClientButtons; bool iFakeAnglesGet;
	
// 	for (int client = 1; client <= MaxClients; client++) {
// 		if (IsValidClient(client) && IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_FROZEN) && (GetEntityFlags(client) & FL_ONGROUND) && !GameRules_GetProp("m_bFreezePeriod")) {
// 			fGetAngles = g_aPlayerCheks[client].fOldAngles;
// 			fGetPos = g_aPlayerCheks[client].fOldPos;

// 			GetClientEyeAngles(client, g_aPlayerCheks[client].fOldAngles);
// 			GetClientAbsOrigin(client, g_aPlayerCheks[client].fOldPos);

// 			iClientButtons = GetClientButtons(client)
// 			iFakeAnglesGet = (g_aPlayerCheks[client].fOldAngles[0] == fGetAngles[0] && g_aPlayerCheks[client].fOldAngles[1] == fGetAngles[1]) || (iClientButtons & (IN_LEFT|IN_RIGHT) != 0);
// 			if (iFakeAnglesGet && (GetVectorDistance(g_aPlayerCheks[client].fOldPos, fGetPos) < g_aConVarlist.fAfkOriginThreshold) && (g_aConVarlist.iAfkFlagEnable != 2 || !(GetUserFlagBits(client) & g_aConVarlist.iAfkFlag))) {
// 				g_aPlayerCheks[client].fAfkCheckTime += g_aConVarlist.fCalcTime;
// 				fAfkCalcTime = g_aConVarlist.fAfkMove - g_aPlayerCheks[client].fAfkCheckTime;
// 				if(fAfkCalcTime <= g_aConVarlist.fCalcTimeWarn) {
// 					if(g_aPlayerCheks[client].fAfkCheckTime >= g_aConVarlist.fAfkMove) {
// 						CPrintToChatAll("%s%t", g_aConVarlist.szTag, "AFK Announce Spec", client);
// 						if(g_aConVarlist.iAfkKillEnable || GetPlayerCountEx(client, true, true, true) == 1)
// 							ForcePlayerSuicide(client); // round end fix
// 						ChangeClientTeam(client, CS_TEAM_SPECTATOR);
// 					} else {
// 						CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "AFK Warning Spec", fAfkCalcTime);
// 						EmitSoundToClient(client, g_aConVarlist.szSoundWarn, SOUND_FROM_PLAYER, SNDCHAN_BODY, 0, SND_NOFLAGS, 1.0, 100, _, NULL_VECTOR, NULL_VECTOR, true);
// 						g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
// 					}
// 				}
// 			} else {
// 				g_aPlayerCheks[client].fAfkCheckTime = 0.0;
// 			}

// 		} else if (IsValidClient(client) && GetClientTeam(client) <= CS_TEAM_SPECTATOR && (!g_aConVarlist.iAfkFlagEnable || !(GetUserFlagBits(client) & g_aConVarlist.iAfkFlag)) && GetPlayerCountEx(client, false, false, false) >= g_aConVarlist.iAfkKickMin) {
// 			g_aPlayerCheks[client].fAfkCheckTime += g_aConVarlist.fCalcTime;
// 			fAfkCalcTime = g_aConVarlist.fAfkKick - g_aPlayerCheks[client].fAfkCheckTime;
// 			if(fAfkCalcTime <= g_aConVarlist.fCalcTimeWarn) {
// 				if(g_aPlayerCheks[client].fAfkCheckTime >= g_aConVarlist.fAfkKick) {
// 					CPrintToChatAll("%s%t", g_aConVarlist.szTag, "AFK Announce Kick", client);
// 					KickClientEx(client, "%t", "AFK Message Kick");
// 				} else {
// 					CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "AFK Warning Kick", fAfkCalcTime);
// 					EmitSoundToClient(client, g_aConVarlist.szSoundWarn, SOUND_FROM_PLAYER, SNDCHAN_BODY, 0, SND_NOFLAGS, 1.0, 100, _, NULL_VECTOR, NULL_VECTOR, true);
// 				}
// 			}
// 		}
// 	}
// }




// enum struct PlayerData {
//     int team_id;
//     int team;
//     int user_id;
//     char steamid[32];

//     void init (int team_id, int team, int user_id) {
//         this.team_id = team_id;
//         this.team = team;
//         this.user_id = user_id;
//     }
// }
