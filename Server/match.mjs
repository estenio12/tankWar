export class Match
{
    ID = 0;
    GameIsRunning = true;
    Players = [];
    Current_turn = 0;
    ID_spectator_count = 0;
    minute = 4;
    second = 57;
    timerRef;

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

        // # Carrega stats dos jogadores.
        this.Players[0].HP = 5;
        this.Players[0].position = "(79, 86)";
        this.Players[1].HP = 5;
        this.Players[1].position = "(1123, 78)";

        // # Monta pacote base.
        let base_pack = `10|${this.ID}|${this.Players[0].nickname}|${this.Players[1].nickname}|`;
        
        // # Monta pacote para cada jogador.
        let PID1_Packet = base_pack + my_tank_p1.toString();
        let PID2_Packet = base_pack + my_tank_p2.toString();

        // # Envia o pacote de carregamento para cada jogador.
        this.Players[0].con.send(PID1_Packet);
        this.Players[1].con.send(PID2_Packet);
    }

    AssignSpectator(con)
    {
        const idSpectator = ++this.ID_spectator_count;
        const timer = `${this.minute}-${this.second}`;
        this.Players.push({"idSpectator": idSpectator, "con": con});
        let current_game_state = `18|${idSpectator}|${this.Current_turn}|${timer}`;
        this.Players.forEach( e => { if(e["idSpectator"] == null) current_game_state += `|${e.nickname}-${e.HP}-${e.position}`; } );
        con.send(current_game_state);
    }

    RemoveSpectator(idSpectator)
    {
        this.Players = this.Players.filter(e => e.idSpectator != idSpectator);
    }

    PushMessage(msgPackage)
    {
        const chunks = msgPackage.toString().split("|");
        const netcode = Number(chunks[0]);

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
                // # Inicia a contagem de tempo.
                this.timerRef = setInterval(() => { this.timerHandler(); }, 1000);
                return;
            }
        }

        // # Espera a confirmação de todos para fechar a partida.
        if(netcode == 16)
        {
            let IDPlayer = Number(chunks[1]);
            this.Players[IDPlayer].IsReady = true;

            console.log("Debug fechar: ", IDPlayer);

            if(this.Players[0].isCloseGame && this.Players[1].isCloseGame)
            {
                this.Players.forEach(e => { e.con.close(); e.con = null; });
                this.GameIsRunning = false;
            }
        }

        // # Muda o turno e sincroniza os dados.
        if(netcode == 5)
        {
            // # Armazena o turno do jogador atual.
            this.Current_turn = chunks[1];

            // # Obtém o estado da partida.
            const STATE_P1 = chunks[2].split('-');
            const STATE_P2 = chunks[3].split('-');

            // # Atualiza o estado do jogador 1.
            this.Players[0].HP = Number(STATE_P1[0]);
            this.Players[0].position = STATE_P1[1];

            // # Atualiza o estado do jogador 2.
            this.Players[1].HP = Number(STATE_P2[0]);
            this.Players[1].position = STATE_P2[1];
        }

        if(netcode == 8)
        {
            setTimeout(() => { this.GameIsRunning = false; },1000);
        }

        // # Repassa os pacotes para os jogadores.
        this.SendPacket(msgPackage);
    }

    SendPacket(pack)
    {
        this.Players.forEach(e => { if(e.con) e.con.send(pack); });
    }
    
    timerHandler()
    {
        if(this.minute <= 0 && this.second <= 0)
        {
            clearInterval(this.timerRef);
            return;
        }

        this.second--;

        if(this.second <= 0)
        {
            this.minute--;
            this.second = 59;

            if(this.minute <= 0)
                this.minute = 0;
        }
    }
}