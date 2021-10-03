#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <json>
#include <SteamWorks>

#include "services/utils.sp"
#include "services/blockers.sp"

#include "methodmaps/User.sp"
#include "methodmaps/Users.sp"
#include "methodmaps/Http.sp"
#include "methodmaps/Game.sp"

#pragma semicolon 1

Game game;

public void OnPluginStart() {
    HookEvent("round_start", RoundStart);
    HookEvent("round_end", RoundEnd);
    HookEvent("cs_intermission", GameEnd);
    HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Post); 

    AddCommandListener(joingame, "joingame");
    AddCommandListener(jointeam, "jointeam");
    AddCommandListener(BlockReloadMapOnJoin, "map");

    game = new Game();
    ///////////////////// delete after testing
    RegConsoleCmd("sm_test", test);
    RegConsoleCmd("sm_kek", kek);
    game.init();
    /////////////////////
}

public OnMapStart () {
    GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
}

public OnMapEnd () {
    // Удалить все баны
    game.clear();
}

public void forceEndGame() {
    if (game.id != 0) game.clear();

    new ent = CreateEntityByName("game_end");
    DispatchSpawn(ent);
    AcceptEntityInput(ent, "EndGame");
}

public Action kek(int client, int args) { 
    // game.users.updateStats();
    KickClient(client, "Your SteamID is not allowed");
}

public Action test(int client, int args) { 
    // char json[2048];
    // game.users.json(json, sizeof(json));

    // PrintToServer("pizda %s", json);

    BanClient(client, 1, BANFLAG_AUTHID, "ss", "ss");
}


public int setGameDataFromHTTP(const char[] body, any args) {
    PrintToServer("%s", body);

    JSON_Object obj = json_decode(body);
    JSON_Object data = obj.GetObject("data");

    if(data == null) {
        json_cleanup_and_delete(obj);
        forceEndGame();
        return;
    }

    game.setData(data.GetInt("game_id"), data.GetInt("total_users"));

    JSON_Array members = view_as<JSON_Array>(data.GetObject("members"));

    for (int i = 0; i < members.Length; i++) {
        JSON_Object member = view_as<JSON_Object>(members.GetObject(i));

        char steamid[32];
        member.GetString("steamid", steamid, sizeof(steamid));
        int team = member.GetInt("team");
        int user_id = member.GetInt("user_id");

        User user = new User(team, user_id, steamid);

        game.users.Push(user);
    }

    json_cleanup_and_delete(obj);

    ServerCommand("bot_quota %i", game.total_users);
    ServerCommand("mp_endwarmup_player_count %i", game.total_users);
}

public void OnClientPutInServer(int client) {
    if (!IsPlayer(client)) return;

    if (game.id == 0) {
        KickClient(client, "Your SteamID is not allowed");
        return;
    }

    User user = game.users.getUser(client);
    
    if (!user) {
        KickClient(client, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
        return;
    }
}

public Action joingame(int client, const char[] command, args) {    
    User user = game.users.getUser(client);

    if (!user) {
        KickClient(client, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
        return;
    }

    user.ban_timer.stop();
    int team = user.team;

    if (game.switched) team = !team;

    ChangeClientTeam(client, team + 2);
} 

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    if (IsWarmup()) return;
    
    if (game.id == 0) {
        forceEndGame();
        return;
    }
    
    game.sendScore();

    if (isHalfTime()) game.switchTeams();
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) {
    // Начало карты
    if(IsWarmup()) {
        game.init();
        return;
    }
    // Начало первого раунда
    if (game.status == 0) {
        game.startOrCancel();
        return;
    }
}

public Action GameEnd(Event event, const char[] name, bool dontBroadcast) {
    // У игры статус cancel
    if (game.id == 0) return;

    game.end();
}