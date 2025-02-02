export class Match
{
    ID = 0;
    GameIsRunning = true;
    Players = [];

    constructor(initData)
    {
        this.ID = initData.IDMatch;
        this.Players.push(initData.PID1);
        this.Players.push(initData.PID2);
    }

    LoadGame()
    {
        // # Define os IDs para cada jogador.
        let my_tank_p1  = Math.floor(Math.random() * 2);
        let my_tank_p2  = my_tank_p1 == 1 ? 0 : 1;

        // # Monta pacote base.
        let base_pack = `10|${this.ID}|${this.Players[0].nickname}|${this.Players[1].nickname}|`;
        
        // # Monta pacote para cada jogador.
        let PID1_Packet = base_pack + my_tank_p1.toString();
        let PID2_Packet = base_pack + my_tank_p2.toString();

        // # Envia o pacote de carregamento para cada jogador.
        this.Players[0].con.send(PID1_Packet);
        this.Players[1].con.send(PID2_Packet);
    }

    PushMessage(msgPackage)
    {
        const chunks = msgPackage.toString().split("|");
        const netcode = Number(chunks[0]);

        // # Troca o turno dos jogadores.
        if(netcode == 4)
        {
            let IDPlayer = Number(chunks[1]);
            IDPlayer = IDPlayer == 1 ? 0 : 1;
            msgPackage = chunks[0] + "|" + IDPlayer.toString();
        }

        // # Espera a confirmação de todos para iniciar a partida.
        if(netcode == 12)
        {
            let IDPlayer = Number(chunks[1]);
            this.Players[IDPlayer].IsReady = true;

            if(this.Players[0].IsReady && this.Players[1].IsReady)
            {
                let turn_select = Math.floor(Math.random() * 2);
                let pack = `9|${turn_select}`;
                this.SendPacket(pack);
                return;
            }
        }

        // # Repassa os pacotes para os jogadores.
        this.SendPacket(msgPackage);

        // # Acabou a partida.
        if(netcode == 8)
        {
            this.Players.forEach(e => { e.con.close(); e.con = null; });
            this.GameIsRunning = false;
        }
    }

    SendPacket(pack)
    {
        this.Players.forEach(e => { e.con.send(pack); });
    }
}