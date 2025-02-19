export class Match
{
    ID = 0;
    GameIsRunning = true;
    Players = [];
    Current_turn = 0;
    ID_spectator_count = 0;
    minute = 4;
    second = 59;
    timerRef;

    constructor(initData)
    {
        this.ID = initData.IDMatch;
        this.Players.push(initData.PID1);
        this.Players.push(initData.PID2);
    }

    LoadGame()
    {
        // # Sorteia os tanks entre os jogadores.
        let sortRand = Math.floor(Math.random() * 5);

        for(let i = 0; i < sortRand; i++)
            this.Players.reverse();

        // # Carrega stats dos jogadores.
        this.Players[0].HP = 5;
        this.Players[0].position = "(79, 86)";
        this.Players[1].HP = 5;
        this.Players[1].position = "(1123, 78)";

        // # Monta pacote base.
        let base_pack = `10|${this.ID}|${this.Players[0].nickname}|${this.Players[1].nickname}|`;
        
        // # Monta pacote para cada jogador.
        let PID1_Packet = `${base_pack}0`;
        let PID2_Packet = `${base_pack}1`;

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
                this.Current_turn = Math.floor(Math.random() * 2);
                let pack = `9|${this.Current_turn}`;
                this.SendPacket(pack);
                // # Inicia a contagem de tempo.
                this.timerRef = setInterval(() => { this.TimerHandler(); }, 1000);
                return;
            }
        }

        // # Espera a confirmação de todos para fechar a partida.
        if(netcode == 16)
        {
            let IDPlayer = Number(chunks[1]);
            this.Players[IDPlayer].IsReady = true;

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
            this.Current_turn = this.Current_turn == 1 ? 0 : 1;

            // # Obtém o estado da partida.
            const STATE_P1 = chunks[2].split('-');
            const STATE_P2 = chunks[3].split('-');

            // # Atualiza o estado do jogador 1.
            this.Players[0].HP = Number(STATE_P1[0]);
            this.Players[0].position = STATE_P1[1];

            // # Atualiza o estado do jogador 2.
            this.Players[1].HP = Number(STATE_P2[0]);
            this.Players[1].position = STATE_P2[1];

            const msgPackage = `5|${this.Current_turn}|${chunks[2]}|${chunks[3]}|${chunks[4]}|${this.minute}|${this.second}|${this.Players[this.Current_turn].nickname}`;
            this.SendPacket(msgPackage);
        }

        if(netcode == 8)
        {
            setTimeout(() => { this.GameIsRunning = false; this.minute = 0; this.second = 0; },1000);
        }

        // # Repassa os pacotes para os jogadores.
        this.SendPacket(msgPackage);
    }

    SendPacket(pack)
    {
        this.Players.forEach(e => { if(e.con) e.con.send(pack); });
    }
    
    TimerHandler()
    {
        this.second--;

        if(this.minute <= 0 && this.second <= 0)
        {
            clearInterval(this.timerRef);
            this.DefineWinner();
            return;
        }

        if(this.second <= 0)
        {
            this.minute--;
            this.second = 59;

            if(this.minute <= 0)
                this.minute = 0;
        }
    }

    DefineWinner()
    {
        const PID1 = this.Players[0];
        const PID2 = this.Players[1];
        let WinnerName = "Empate";
        
        if(PID1 && PID2)
        {   
            const PID1_HP = PID1.HP;
            const PID2_HP = PID2.HP;
            
            if(PID1_HP > PID2_HP)
                WinnerName = PID1.nickname;
            else if(PID1_HP < PID2_HP)
                WinnerName = PID2.nickname;
        }

        let pack = `8|${WinnerName}`;
        
        this.SendPacket(pack)
    }

    isGamaOver()
    {
        return !this.GameIsRunning || (this.minute <= 0 && this.second <= 0);
    }
}