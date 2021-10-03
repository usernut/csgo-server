methodmap Stats < JSON_Object {
    public Stats() {
        Stats self = view_as<Stats>(new JSON_Object());

        self.SetInt("kills", 0);
        self.SetInt("assists", 0);
        self.SetInt("deaths", 0);
        self.SetInt("hs", 0);
        self.SetInt("dmg", 0);
        self.SetInt("mvps", 0);
        self.SetInt("score", 0);
        self.SetInt("ud", 0);
        self.SetInt("ef", 0);
        self.SetInt("k3", 0);
        self.SetInt("k4", 0);
        self.SetInt("k5", 0);

        return self;
    }

    public void update(int client) {
       this.SetInt("kills", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iKills", _, client));
       this.SetInt("assists", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iAssists", _, client));
       this.SetInt("deaths", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iDeaths", _, client));
       this.SetInt("hs", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_HeadShotKills_Total", _, client));
       this.SetInt("dmg", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_Damage_Total", _, client));
       this.SetInt("mvps", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMVPs", _, client));
       this.SetInt("score", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, client));
       this.SetInt("ud", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_UtilityDamage_Total", _, client));
       this.SetInt("ef", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_EnemiesFlashed_Total", _, client));
       this.SetInt("k3", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_3k_Total", _, client));
       this.SetInt("k4", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_4k_Total", _, client));
       this.SetInt("k5", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMatchStats_5k_Total", _, client));
    }
}