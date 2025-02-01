#pragma once

#include <vector>
#include "NetClient.hpp"
#include "Match.hpp"

class MatchMaking
{
    private:
        std::vector<NetClient*> PlayerList;

    public:
        MatchMaking();
        ~MatchMaking();

    public:
        void AddPlayerToQueue(NetClient* client) { PlayerList.push_back(client); };
        bool IsMatchFound() { return PlayerList.size() > 1; };
        Match* CreateMatch(int IDMatch);
};