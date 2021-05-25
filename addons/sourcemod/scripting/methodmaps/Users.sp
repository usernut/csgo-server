methodmap Users < ArrayList {    
    public Users() {
        return view_as<Users>(new ArrayList());
    }

    public void Push(User user) {
        this.Push(user);
    }

    public void Clear() {
        this.Clear();
    }

    // public void print() {
    //     for (int j = 0; j < this.Length; j++) {
    //         User user = this.Get(j);

    //         char output[512];
    //         user.Encode(output, sizeof(output));
    //         PrintToServer("%s", output);
    //     }
    // }

    public int getDataByClient(int client, char[] prop) {
        char clientSteamid[32];
        char playerSteamid[32];

        GetClientAuthId(client, AuthId_SteamID64, clientSteamid, sizeof(clientSteamid));

        for (int i = 0; i < this.Length; i++) {
            User user = this.Get(i);

            user.steamid(playerSteamid, sizeof(playerSteamid));
            
            if(!StrEqual(playerSteamid, clientSteamid)) continue;

            return user.getIntPropertyByName(prop);
        }

        return -1;
    }
}