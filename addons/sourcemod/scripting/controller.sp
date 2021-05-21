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

methodmap Game < StringMap {
    public Game() {
        Game self = view_as<Game>(new StringMap());
        
        self.SetValue("id", 0);
        self.SetValue("total_users", 0);
        self.SetValue("status", 0); // 0 - warmup, 1 - started, 2 - end
        self.SetValue("switched", false);

        return self;
    }

    property int id {
        public get() {
            int id;
            this.GetValue("id", id);
            return id;
        }
    }

    property int total_users {
        public get() {
            int total_users;
            this.GetValue("total_users", total_users);
            return total_users;
        }
    }

    property int status {
        public get() {
            int status;
            this.GetValue("status", status);
            return status;
        }
        public set(int status) {
            this.SetValue("status", status);
        }
    }

    property bool switched {
        public get() {
            bool switched;
            this.GetValue("switched", switched);
            return switched;
        }
    }

    public void switchTeams() {
        this.SetValue("switched", !this.switched);
    }

    public void setData(int id, int total_users) {
        this.SetValue("id", id);
        this.SetValue("total_users", total_users);
    }

    public void clear() {
        this.SetValue("id", 0);
        this.SetValue("total_users", 0);
        this.SetValue("status", 0);
        this.SetValue("switched", false);
        
        users.Clear();
    }

    public void init() {
        if(this.id != 0) return;

        http.post("{\"t\": 1}", getDataCallback);
        ServerCommand("bot_kick");
    }

    public void start() {
        char json[128];

        Format(json, sizeof(json), "{\"t\":2,\"data\":{\"game_id\": %i}}", this.id);
        http.post(json, defaultCallback);

        this.status = 1;

        PrintToChatAll("Игра началась");
    }

    public void cancel() {
        char json[512];
        char unconnected[512];
        JSON_Array arr = new JSON_Array();

        for (int j = 0; j < users.Length; j++) {
            char playerSteamid[32];
            User user = users.Get(j);

            user.steamid(playerSteamid, sizeof(playerSteamid));

            if (!isUserInGame(playerSteamid)) {
                arr.PushInt(user.user_id);
            }
        }

        arr.Encode(unconnected, sizeof(unconnected));
        json_cleanup_and_delete(arr);

        Format(json, sizeof(json), "{\"t\":6,\"data\":{\"game_id\": %i,\"unconnected\": %s}}", this.id, unconnected);
        http.post(json, defaultCallback); 

        this.clear();
        // KickAllPlayers(15.0, "Game canceled"); 
        //TODO: game end
    }

    public void startOrCancel() {
        if (GetRealClientsCount() != this.total_users) {
            this.cancel();
            return;
        }
        this.start();
    }

    public void end() {
        char json[512];
        char message[128] = "The match is over. Thanks for the game!";

        int winner = 0;
        int team0 = CS_GetTeamScore(CS_TEAM_CT);
        int team1 = CS_GetTeamScore(CS_TEAM_T);

        if (team1 > team0) winner = 1;
        // TODO: отправлять статистику игроков
        Format(json, sizeof(json), "{\"t\":4,\"data\":{\"game_id\": %i,\"team\": %i}}", this.id, winner);
        http.post(json, defaultCallback);

        this.clear();

        PrintToChatAll(message);
        KickAllPlayers(15.0, message);
    }

    public void sendScore() {
        ArrayList score = new ArrayList();

        score.Push(CS_GetTeamScore(CS_TEAM_T));
        score.Push(CS_GetTeamScore(CS_TEAM_CT));

        if (this.switched) { 
            score.SwapAt(0, 1);
        }

        char json[128];
        Format(json, sizeof(json), "{\"t\":3,\"data\":{\"game_id\": %i,\"scores\": [%i, %i]}}", this.id, score.Get(0), score.Get(1));
        http.post(json, defaultCallback);
    }
}

Game game;

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
    game = new Game();

    ///////////////////// delete after testing
    RegConsoleCmd("sm_test", test);
    game.init();
    /////////////////////
}


public void OnMapStart () {
    GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
    game.clear();
}

public Action test(int client, int args) { 
    new ent = CreateEntityByName("game_end");
    DispatchSpawn(ent);
    AcceptEntityInput(ent, "EndGame");

    // m_iMatchStats_HeadShotKills_Total
    // GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, client);
    // int avg =  GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_Kills_Total", _, client);
    // PrintToChatAll("avg: %i", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, client));
}



public int setGameDataFromHTTP(const char[] body, any args) {
    PrintToServer("%s", body);

    JSON_Object obj = json_decode(body);
    JSON_Object data = obj.GetObject("data");

    if(data == null) {
        json_cleanup_and_delete(obj);
        // TODO: game end
        return;
    }

    JSON_Array members = view_as<JSON_Array>(data.GetObject("members"));

    game.setData(data.GetInt("game_id"), data.GetInt("total_users"));

    for (int i = 0; i < members.Length; i++) {
        JSON_Array member = view_as<JSON_Array>(members.GetObject(i));

        User user = view_as<User>(member);

        users.Push(user);
    }

    // json_cleanup_and_delete(obj); TODO: переписать на StringMap

    ServerCommand("mp_endwarmup_player_count %i", game.total_users);
}

public void OnClientAuthorized(int client, const char[] auth) {
    if (game.id == 0) {
        KickClient(client, "Your SteamID is not allowed");
        return;
    }

    int team = users.getDataByClient(client, "team");

    if (team != 0 && team != 1) {
        KickClient(client, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
        return;
    }
}

// --- ready ---
public Action joingame(int client, const char[] command, args) {    
    int team = users.getDataByClient(client, "team");

    if (team != 0 && team != 1) {
        KickClient(client, "Your SteamID is not allowed. Make sure you are logged in with the correct account");
        return;
    }
    
    if (game.switched) {
        team = !team;
    }

    ChangeClientTeam(client, team + 2);
} 

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    if (IsWarmup()) {
        return;
    }
    
    game.sendScore();

    if (isHalfTime()) {
        game.switchTeams();
    }
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
    //У игры статус cancel
    if (game.id == 0) {
        return;
    }
    game.end();
}