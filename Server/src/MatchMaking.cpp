#include "MatchMaking.hpp"

MatchMaking::MatchMaking() {}

MatchMaking::~MatchMaking() {}

Match* MatchMaking::CreateMatch(int IDMatch)
{
    // # Armazena o ponteiro para os dois jogadores que serão pareados.
    auto PID1 = PlayerList[0];
    auto PID2 = PlayerList[1];

    // # Remove os dois jogadores da lista de espera.
    PlayerList.erase(PlayerList.begin(), PlayerList.begin() + 2);

    return new Match(IDMatch, PID1, PID2);
}
