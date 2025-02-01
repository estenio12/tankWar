#pragma once

#include <vector>
#include <ctime>
#include <SFML/Network.hpp>
#include "NetClient.hpp"
#include "Tools.hpp"

class Match
{
    private:
        std::vector<NetClient*> players;
        sf::UdpSocket socket;

    public:
        int IDMatch = 0;
        bool GameIsRunning = true;

    public:
        Match(int IDMatch, NetClient* P1, NetClient* P2);
        ~Match();

    public:
        void LoadGame();
        void PushMessage(std::string strPackage);

    private:
        void SendPacket(std::string packet);
};