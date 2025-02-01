#include "Match.hpp"

Match::Match(int IDMatch, NetClient* P1, NetClient* P2)
{
    this->IDMatch = IDMatch;
    this->players.push_back(P1);
    this->players.push_back(P2);
}

Match::~Match()
{
    for(auto player : this->players)
        delete player;

    this->players.clear();
}

void Match::LoadGame()
{
    // # Gera um seed.
    srand(time(nullptr));
    int start_turn = rand() % 2;

    // # Gera um seed.
    srand(time(nullptr));
    int my_tank_p1 = rand() % 2;
    int my_tank_p2 = my_tank_p1 == 1 ? 0 : 1;
    
    // # Monta pacote.
    auto base_pack = "10|" + std::to_string(IDMatch) + "|" + players[0]->Nickname + "|" + players[0]->Nickname + "|";

    // # Monta pacote para cada jogador.
    auto PID1_Packet = base_pack + std::to_string(my_tank_p1);
    auto PID2_Packet = base_pack + std::to_string(my_tank_p2);

    // # Envia o pacote de carregamento para cada jogador.
    socket.send(PID1_Packet.c_str(), PID1_Packet.size() + 1, players[0]->IP, players[0]->Port);
    socket.send(PID2_Packet.c_str(), PID2_Packet.size() + 1, players[1]->IP, players[1]->Port);
}

void Match::PushMessage(std::string strPackage)
{
    auto packet = Tools::Split(strPackage, '|');
    int netcode = stoi(packet[0]);

    // # Troca o turno dos jogadores.
    if(netcode == 4)
    {
        int playerID = stoi(packet[1]);
        playerID = playerID == 0 ? 1 : 0;
        strPackage = packet[0] + "|" + std::to_string(playerID);
    }

    // # Espera a confirmação de todos para iniciar a partida.
    if(netcode == 12)
    {
        int playerID = stoi(packet[1]);
        this->players[playerID]->isReady = true;

        if(this->players[0]->isReady && this->players[1]->isReady)
        {
            srand(time(nullptr));
            auto pack = "9|" + std::to_string(rand() % 2);
            this->SendPacket(pack);
            return;
        }
    }

    this->SendPacket(strPackage);

    // # Acabou a partida.
    if(netcode == 8)
        this->GameIsRunning = false;
}

void Match::SendPacket(std::string packet)
{
    for(auto player : this->players)
        socket.send(packet.c_str(), packet.size() + 1, player->IP, player->Port);
}

