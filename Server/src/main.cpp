#include <iostream>
#include <cstring>
#include <vector>
#include <thread>
#include <SFML/Network.hpp>

#include "MatchMaking.hpp"
#include "Match.hpp"
#include "NetClient.hpp"

#define NET_UDP_PORT 7080

void ServerListener(MatchMaking*, std::vector<Match*>&);

int main(int argc, char** argv)
{
    int global_match_id = 0;

    // # Modules
    auto matchmaking = new MatchMaking();
    std::vector<Match*> matches;

    std::thread threadServerlistener(&ServerListener, matchmaking, std::ref(matches));
    threadServerlistener.detach();

    std::cout << "Server running in IP: " << sf::IpAddress::getLocalAddress().toString() << " | PORT: " << NET_UDP_PORT << std::endl;

    while(true)
    {
        // # Verifica se foi possível formar partida.
        if(matchmaking->IsMatchFound())
        {
            auto match = matchmaking->CreateMatch(++global_match_id);
            matches.push_back(match);
            match->LoadGame();
        }

         // # Limpa as partidas terminadas
        for (auto it = matches.begin(); it != matches.end();)
        {
            if (!(*it)->GameIsRunning)
            {
                delete *it; // Libera a memória da partida
                it = matches.erase(it); // Remove o ponteiro do vetor e retorna para o próximo elemento
            }
            else
            {
                ++it; // Continua iterando se a partida ainda está em andamento
            }
        }
    }

    return EXIT_SUCCESS;
}

void ServerListener(MatchMaking* matchmaking, std::vector<Match*>& matches)
{
    // # Cria socket.
    sf::UdpSocket socket;
    socket.bind(NET_UDP_PORT);

    // # Recebe os dados do cliente.
    char buffer[1024];
    std::size_t received = 0;
    sf::IpAddress IPClient;
    unsigned short PORTClient;

    while(true)
    {
        if(socket.receive(buffer, sizeof(buffer), received, IPClient, PORTClient) == sf::Socket::Done)
        {
            if(buffer == nullptr || strlen(buffer) <= 0) continue;
            
            std::string sbuffer = buffer;
            auto chunks = Tools::Split(sbuffer, '|');
            auto netcode = stoi(chunks[0]);

            // # NETCODE 11 => REGISTER
            if(netcode == 11)
            {
                auto netclient = new NetClient(chunks[1], PORTClient, IPClient);
                matchmaking->AddPlayerToQueue(netclient);
                std::cout << "Novo jogador entrou na fila de espera: " << chunks[1] << std::endl;
            }
            else
            {
                auto IDMatch = stoi(chunks[chunks.size() - 1]);

                for(auto match : matches)
                {
                    if(match->IDMatch == IDMatch)
                        match->PushMessage(sbuffer);
                }
            }
        }
    }
}


