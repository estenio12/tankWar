#pragma once

#include <SFML/Network.hpp>

class NetClient
{
    public:
        std::string Nickname;
        sf::IpAddress IP;
        unsigned short Port;
        bool isReady = false;

    public:
        NetClient(std::string Nickname, unsigned short Port, sf::IpAddress IP):Nickname(Nickname), Port(Port), IP(IP){}
        ~NetClient(){};
};