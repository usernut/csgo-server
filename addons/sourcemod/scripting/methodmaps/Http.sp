methodmap Http < StringMap {
    public Http(char[] url) {
        Http self = view_as<Http>(new StringMap());
        
        self.SetString("url", url);

        return self;
    }

    public bool url(char[] buffer, int max_size) {
        this.GetString("url", buffer, max_size);
    }

    public void post(char[] json, SteamWorksHTTPRequestCompleted callback) {
        char url[64];
        this.url(url, sizeof(url));

        Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);
        SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 10);
        SteamWorks_SetHTTPRequestRawPostBody(request, "application/json; charset=utf-8", json, strlen(json));
        SteamWorks_SetHTTPRequestHeaderValue(request, "jwt", "jwt");
        SteamWorks_SetHTTPCallbacks(request, callback);

        SteamWorks_SendHTTPRequest(request);
    }
}

void defaultCallback(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode eStatusCode, any data) {
    if (eStatusCode != k_EHTTPStatusCode200OK) {
        PrintToServer("Http Error");

        KickAllPlayers(0.0, "");
        forceEndGame();

        delete request;
        return;
    }
    PrintToServer("Http Success");

    delete request;
}

void getDataCallback(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode eStatusCode, any data) {
    if (eStatusCode != k_EHTTPStatusCode200OK) {
        PrintToServer("Can't get data");

        forceEndGame();

        delete request;
        return;
    }

    SteamWorks_GetHTTPResponseBodyCallback(request, setGameDataFromHTTP, data);
    delete request;
}