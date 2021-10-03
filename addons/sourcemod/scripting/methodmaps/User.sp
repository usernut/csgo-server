#include "methodmaps/BanTimer.sp"
#include "methodmaps/Stats.sp"

methodmap User < StringMap {    
    public User(int team, int user_id, char[] steamid) {
        User self = view_as<User>(new StringMap());
        BanTimer ban_timer = new BanTimer();
        Stats stats = new Stats();

        self.SetValue("team", team);
        self.SetValue("user_id", user_id);
        self.SetString("steamid", steamid);

        self.SetValue("stats", stats);
        self.SetValue("ban_timer", ban_timer);
        
        return self;
    }

    property int team {
        public get() {
            int team;
            this.GetValue("team", team);
            return team;
        }
    }

    property int user_id {
        public get() {
            int user_id;
            this.GetValue("user_id", user_id);
            return user_id;
        }
    }

    public bool steamid(char[] buffer, int max_size) {
        return this.GetString("steamid", buffer, max_size);
    }

    property BanTimer ban_timer {
        public get() {
            BanTimer ban_timer;
            this.GetValue("ban_timer", ban_timer);
            return ban_timer;
        }
    }

    property Stats stats {
        public get() {
            Stats stats;
            this.GetValue("stats", stats);
            return stats;
        }
    }
}