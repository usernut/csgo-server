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

#pragma semicolon 1

Users users;
Http http;

bool isDataLoaded = false;
bool isMatchStarted = false;
bool isTeamSwitched = false;

int total_users;
int game_id;

methodmap Game < StringMap {
    public Game(int game_id, int total_users) {
        Game self = view_as<Game>(new StringMap());
        
        self.SetValue("game_id", game_id);
        self.SetValue("total_users", total_users);

        return self;
    }
}

public void OnPluginStart() {
    HookEvent("round_start", RoundStart);
    HookEvent("round_end", RoundEnd);
    HookEvent("cs_intermission", GameEnd);
    // HookEvent("player_say", PlayerSay);

    AddCommandListener(joingame, "joingame");
    AddCommandListener(jointeam, "jointeam");
    AddCommandListener(BlockReloadMapOnJoin, "map");

    users = new Users();
    http = new Http("http://127.0.0.1:3001/api/server/");

    ///////////////////// delete after testing
    RegConsoleCmd("sm_test", test);
    http.send("{\"t\": 1}", getDataCallback);
    /////////////////////
}


public void OnMapStart () {
    GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
    isMatchStarted = false;
    isTeamSwitched = false;
}

public Action test(int client, int args) {
    // CS_TerminateRound(0.0, CSRoundEnd_Draw);

    int team = users.getDataByClient(client, "user_id");
    PrintToChatAll("%i", team);

    // PrintToChatAll("%i", client);

    // m_iMatchStats_HeadShotKills_Total
    // GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, client);
    // int avg =  GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_Kills_Total", _, client);
    // PrintToChatAll("avg: %i", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, client));
}

public int setGameDataFromHTTP(const char[] body, any args) {
    PrintToServer("%s", body);

    JSON_Object obj = json_decode(body);
    JSON_Object data = obj.GetObject("data");

    // TODO: if data === null |> return

    JSON_Array members = view_as<JSON_Array>(data.GetObject("members"));

    game_id = data.GetInt("game_id");
    total_users = data.GetInt("total_users");

    for (int i = 0; i < members.Length; i++) {
        JSON_Array member = view_as<JSON_Array>(members.GetObject(i));

        User user = view_as<User>(member);

        users.Push(user);
    }

    // json_cleanup_and_delete(obj);

    ServerCommand("mp_endwarmup_player_count %i", total_users);
    isDataLoaded = true;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen) {
    // if (!isDataLoaded) {
    //     strcopy(rejectmsg, maxlen, "Your SteamID is not allowed");
    //     return false;
    // }

    // int team = getMemberInfo(ArrMembers, client, "team");

    // if (team == -1) {
    //     strcopy(rejectmsg, maxlen, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
    //     return false;
    // }

    return true;
}

public Action joingame(int client, const char[] command, args) {    
    // int team = getMemberInfo(ArrMembers, client, 1);

    // if (team == -1) {
    //     KickClient(client, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
    //     return;
    // }
    // 
    // team == 0 && !isTeamSwitched || team == 1 && isTeamSwitched ?
    //     ChangeClientTeam(client, CS_TEAM_T) :
    //     ChangeClientTeam(client, CS_TEAM_CT);
} 

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    // int team = GetEventInt(event, "winner");

    if (IsWarmup()) {
        return;
    }
    
    //TODO: отправлять счет
    int T0Score = CS_GetTeamScore(CS_TEAM_T);
    int T1Score = CS_GetTeamScore(CS_TEAM_CT);

    if (isTeamSwitched) { 
        T0Score = CS_GetTeamScore(CS_TEAM_CT);
        T1Score = CS_GetTeamScore(CS_TEAM_T);
    }

    char json[128];
    Format(json, sizeof(json), "{\"t\":1,\"data\":{\"game_id\": %i,\"scores\": [%i, %i]}}", game_id, T0Score, T1Score);
    http.send(json, defaultCallback);

    if (isHalfTime()) {
        isTeamSwitched = !isTeamSwitched;
        PrintToChatAll("switched");    
    }
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if(IsWarmup()) {
        initGame();
        return;
    }

    if (!isMatchStarted) {
        startGame();
        return;
    }
}

public Action GameEnd(Event event, const char[] name, bool dontBroadcast) {
    PrintToChatAll("The match is over. Thanks for the game!");
    /*
        Определяем какая команда победила и отправляем запрос на сервер
        Выставляем статус игры 
        Выдаем деньги победителям
        Меняем статус сервера на свободен
        Статус команд у одной меняем на проиграла у другой на выиграла
    */
    // CreateTimer(7.0, KickAllPlayers);
}

public void initGame() {
    if(isDataLoaded) return;

    http.send("{\"t\": 1}", getDataCallback);
    ServerCommand("bot_kick");
}

public void startGame() {
    if (GetRealClientsCount() != 1/*total_users*/) {
        http.send("{\"t\": 5}", defaultCallback); //Отправить не подключенных людей
        PrintToChatAll("Game canceled"); //TODO: заменить на KickAllPlayers("Game canceled");
        return;
    }
    isMatchStarted = true;
    http.send("{\"t\": 2}", defaultCallback);
    PrintToChatAll("Игра началась");
}

  
  
// #include <sourcemod>
// #include <sdktools>
// #include <cstrike>
// #include <ripext>
// #include <json>

// public void OnPluginStart() {
// 	sendHttp()
// }

// public void sendHttp() {
//     char output[1024];

//     PrintToServer("[CSGO Remote] Round End!");

//     HTTPClient http = new HTTPClient("http://127.0.0.1:3001");
// 	http.SetHeader("Accept", "application/json");
// 	http.SetHeader("Content-Type", "application/json");


//     JSON_Object main = new JSON_Object();
//     main.SetString("strkey", "fuck ripext");
//     main.SetInt("intkey", 1651);

//     main.Encode(output, sizeof(output));
//     main.Cleanup();

//     delete main;

//     JSON obj = JSONObject.FromString(output);
//     http.Post("/api/mm/test", obj, OnRESTCall);

//     delete http
// }

// public void OnRESTCall(HTTPResponse response, any value) {
//     if (response.Status != HTTPStatus_OK) {
//         PrintToServer("[CSGO Remote] REST Failed!");
//         return;
//     }

//     PrintToServer("[CSGO Remote] REST Success!");
// }
