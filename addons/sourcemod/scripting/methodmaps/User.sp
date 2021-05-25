methodmap User < JSON_Object {    
    public User() {
        return view_as<User>(new JSON_Object());
    }

    property int team {
        public get() {
            return this.GetInt("team");
        }
    }

    property int user_id {
        public get() {
            return this.GetInt("user_id");
        }
    }

    public bool steamid(char[] buffer, int max_size) {
        return this.GetString("steamid", buffer, max_size);
    }

    public int getIntPropertyByName(char[] prop) {
        return this.GetInt(prop);
    }
}