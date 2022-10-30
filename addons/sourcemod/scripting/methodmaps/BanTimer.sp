methodmap BanTimer < StringMap {
    public BanTimer() {
        BanTimer self = view_as<BanTimer>(new StringMap());

        self.SetString("nickname", "");
        self.SetString("steamid64", "");
        self.SetValue("time", 5);
        self.SetValue("banned", false);

        return self;
    }

    property bool banned {
        public get() {
            bool banned;
            this.GetValue("banned", banned);
            return banned;
        }
        public set(bool banned) {
            this.SetValue("banned", banned);
        }
    }

    property int time {
        public get() {
            int time;
            this.GetValue("time", time);
            return time;
        }
        public set(int time) {
            this.SetValue("time", time);
        }
    }

    property Handle timer {
        public get() {
            Handle timer;
            this.GetValue("timer", timer);
            return timer;
        }
        public set(Handle timer) {
            this.SetValue("timer", timer);
        }
    }

    public void alert() {
        char nickname[32];
        this.GetString("nickname", nickname, sizeof(nickname));

        PrintToChatAll("\x01 \x07%s has disconnected from the server. They have %i minutes to rejoin the server or they will be issued a cool down", nickname, this.time);

        this.time--;
    }

    public void ban() {
        this.Remove("timer");
        this.banned = true;

        char nickname[32];
        this.GetString("nickname", nickname, sizeof(nickname));

        char steamid64[32];
        this.GetString("steamid64", steamid64, sizeof(steamid64));
        
        PrintToChatAll("%s was banned for abandoned the match", nickname);

        BanIdentity(steamid64, 60, BANFLAG_AUTHID, "You have been banned from this server");
    }

    public void start(int client) {
        if (this.timer || this.banned) return;

        this.time = 5;
        
        char nickname[32];
        GetClientName(client, nickname, sizeof(nickname));
        this.SetString("nickname", nickname);

        char steamid64[128];
        GetClientAuthId(client, AuthId_Engine, steamid64, sizeof(steamid64));
        this.SetString("steamid64", steamid64);

        this.alert();

        this.timer = CreateTimer(3.0, Timer_BanUser, this, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }

    public void stop() {
        if (!this.timer) return;

        KillTimer(this.timer);

        this.Remove("timer");
    }
}