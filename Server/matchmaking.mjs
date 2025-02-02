export class MatchMaking
{
    playerList = [];
    match_id_counter = 0;

    AddPlayerToQueue(player)
    {
        this.playerList.push(player);
    }

    IsMatchFound()
    {
        return this.playerList.length > 1;
    }

    CreateMatch()
    {
        let PID1 = this.playerList[0];
        let PID2 = this.playerList[1];

        // # Remove os dois jogadores da lista de espera.
        this.playerList.splice(0, 2);

        let IDMatch = ++this.match_id_counter;

        return {"IDMatch": IDMatch, "PID1": PID1, "PID2": PID2};
    }
}

