#include <cstrike>
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

int g_DamageDone[MAXPLAYERS+1][MAXPLAYERS+1];
int g_HitCounter[MAXPLAYERS+1][MAXPLAYERS+1];

public void OnPluginStart() {
    HookEvent("round_start", RoundStart);
    HookEvent("round_end", RoundEnd, EventHookMode_Post);
    HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    if (IsWarmup()) return;

    PrintToChatAll("\x01 \x06Counter-Terrorists (%i - %i) Terrorists", CS_GetTeamScore(CS_TEAM_CT), CS_GetTeamScore(CS_TEAM_T));
    PrintToConsoleAll("Counter-Terrorists (%i - %i) Terrorists", CS_GetTeamScore(CS_TEAM_CT), CS_GetTeamScore(CS_TEAM_T));

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsPlayer(i)) continue;

        int attackingTeam = GetClientTeam(i);
        if (attackingTeam != CS_TEAM_CT && attackingTeam != CS_TEAM_T) 
            continue; 

        int otherTeam = (attackingTeam == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;

        for (int j = 1; j <= MaxClients; j++) {
            if (!IsValid(j) || GetClientTeam(j) != otherTeam) 
                continue;

            char nickname[64];
            GetClientName(j, nickname, sizeof(nickname));

            PrintToChat(
                i, 
                "\x01 \x06To: (%i / %i hits) from: (%i / %i hits) - %s (%i hp)",
                g_DamageDone[i][j], g_HitCounter[i][j], g_DamageDone[j][i], g_HitCounter[j][i], nickname, GetClientHealth(j)
            );
        }
    }
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        for (int j = 1; j <= MaxClients; j++) {
            g_DamageDone[i][j] = 0;
            g_HitCounter[i][j] = 0;
        }
    }
}

public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int attacking = GetClientOfUserId(event.GetInt("attacker"));
    int attacked = GetClientOfUserId(event.GetInt("userid"));


    if (!IsValid(attacking) || !IsValid(attacked)) return;
    int dmg = event.GetInt("dmg_health");
    int health = GetClientHealth(attacked);

    g_DamageDone[attacking][attacked] += health >= 0 ? dmg : health + dmg;//dmg;
    g_HitCounter[attacking][attacked]++;
}

public bool IsValid(int client) {
    return client && client <= MaxClients && IsClientInGame(client);
}

public bool IsPlayer(int client) {
    return IsValid(client) && !IsFakeClient(client);
}

public bool IsWarmup() {
    return GameRules_GetProp("m_bWarmupPeriod") != 0;
}