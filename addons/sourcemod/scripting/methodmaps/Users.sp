methodmap Users < ArrayList {    
    public Users() {
        return view_as<Users>(new ArrayList());
    }

    public void Clear() {
        for (int j = 0; j < this.Length; j++) {
            User user = this.Get(j);
            user.ban_timer.stop()
        }
  
        ServerCommand("removeallids");
        this.Clear();
    }

    public User getUser(int client) {
        if (!IsPlayer(client)) return null;

        char clientSteamid[32];

        GetClientAuthId(client, AuthId_SteamID64, clientSteamid, sizeof(clientSteamid));

        for (int i = 0; i < this.Length; i++) {
            char playerSteamid[32];
            User user = this.Get(i);

            user.steamid(playerSteamid, sizeof(playerSteamid));
            
            if(!StrEqual(playerSteamid, clientSteamid)) continue;

            return user;
        }

        return null;
    }

    public bool unconnected(char[] buffer, int max_size) {
        JSON_Array arr = new JSON_Array();

        for (int j = 0; j < this.Length; j++) {
            char playerSteamid[32];
            User user = this.Get(j);

            user.steamid(playerSteamid, sizeof(playerSteamid));

            if (!isUserInGame(playerSteamid)) {
                arr.PushInt(user.user_id);
            }
        }

        char unconnected[512];
        arr.Encode(unconnected, sizeof(unconnected));

        json_cleanup_and_delete(arr);

        Format(buffer, max_size, unconnected);
    }

    public bool json(char[] buffer, int max_size) {
        JSON_Array arr = new JSON_Array();

        for (int j = 0; j < this.Length; j++) {
            JSON_Object obj = new JSON_Object();
            User user = this.Get(j);

            obj.SetInt("user_id", user.user_id);
            obj.SetObject("stats", user.stats.ShallowCopy());

            arr.PushObject(obj);
        }

        char data[2048];
        arr.Encode(data, sizeof(data));
        
        json_cleanup_and_delete(arr);
        
        Format(buffer, max_size, data);
    }

    public void updateStats() {
        for (int client = 1; client <= MaxClients; client++) {
            User user = this.getUser(client);

            if (!user) continue;

            user.stats.update(client);
        }
    }
}