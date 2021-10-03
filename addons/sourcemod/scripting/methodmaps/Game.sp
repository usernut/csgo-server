methodmap Game < StringMap {
    public Game() {
        Game self = view_as<Game>(new StringMap());
        Users users = new Users();
        Http http = new Http("http://127.0.0.1:3001/api/server/");
        
        self.SetValue("id", 0);
        self.SetValue("total_users", 0);
        self.SetValue("switched", false);

        self.SetValue("users", users);
        self.SetValue("http", http);

        self.SetValue("status", 0); // 0 - warmup, 1 - started

        return self;
    }

    property Users users {
        public get() {
            Users users;
            this.GetValue("users", users);
            return users;
        }
    }

    property Http http {
        public get() {
            Http http;
            this.GetValue("http", http);
            return http;
        }
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
        this.SetValue("switched", false);
        this.SetValue("status", 0);

        this.users.Clear();
    }
    /* Запуск карты начало разминки*/
    public void init() {
        if(this.id != 0) return;

        this.http.post("{\"t\": 1}", getDataCallback);
        SetConVarInt(FindConVar("mp_autokick"), 0);
    }
    /* Начало первого раунда */
    public void start() {
        char json[128];
        
        if(this.id == 0) return;

        Format(json, sizeof(json), "{\"t\":2,\"data\":{\"game_id\": %i}}", this.id);
        this.http.post(json, defaultCallback);

        this.status = 1;

        PrintToChatAll("Игра началась");
    }
    /* Остановка матча */
    public void cancel() {
        char json[512];
        char unconnected[512];

        this.users.unconnected(unconnected, sizeof(unconnected));

        Format(json, sizeof(json), "{\"t\":6,\"data\":{\"game_id\": %i,\"unconnected\": %s}}", this.id, unconnected);
        this.http.post(json, defaultCallback); 

        forceEndGame();
        KickAllPlayers(15.0, "Game canceled"); 
    }

    public void startOrCancel() {
        if (GetRealClientsCount() != 1 /*this.total_users*/) { //TODO: временное исправление для теста
            this.cancel();
            return;
        }
        SetConVarInt(FindConVar("mp_autokick"), 1);
        this.start();
    }

    public void end() { //TODO: исправить
        char json[2048];
        char message[128] = "The match is over";

        int winner = 0;
        int team0 = CS_GetTeamScore(CS_TEAM_CT);
        int team1 = CS_GetTeamScore(CS_TEAM_T);

        if (team1 > team0) winner = 1;

        this.users.updateStats();

        char users[2048];
        this.users.json(users, sizeof(users));

        Format(json, sizeof(json), "{\"t\":4,\"data\":{\"game_id\": %i,\"team\": %i, \"users\": %s }}", this.id, winner, users);
        this.http.post(json, defaultCallback);

        this.clear();

        PrintToChatAll(message);
        KickAllPlayers(20.0, message);
    }

    public void sendScore() {
        ArrayList score = new ArrayList();

        score.Push(CS_GetTeamScore(CS_TEAM_T));
        score.Push(CS_GetTeamScore(CS_TEAM_CT));

        if (this.switched) score.SwapAt(0, 1);

        char json[128];
        Format(json, sizeof(json), "{\"t\":3,\"data\":{\"game_id\": %i,\"scores\": [%i, %i]}}", this.id, score.Get(0), score.Get(1));
        this.http.post(json, defaultCallback);
    }
}