import { MatchMaking } from './matchmaking.mjs'
import { WebSocketServer } from 'ws';
import { Match } from './match.mjs'
import express from 'express';
import https from 'https';
import fs from 'fs';
import os from 'os';

// Definições de caminhos
const PORT = 8080;
const IP = getLocalIP();

const app = express();

app.use((req, res, next) => {
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
    next();
});

const options = {
    key: fs.readFileSync('cert/key.pem'),
    cert: fs.readFileSync('cert/cert.pem')
};

app.use(express.static('client')); // Servir os arquivos do jogo

const wssServer = https.createServer(options, app);
const wss = new WebSocketServer({ server: wssServer });

wssServer.listen(PORT, () => {
    console.log(`Servidor rodando em https://${IP}:${PORT}`);
});

var matchmaking = new MatchMaking();
var matches = [];

wss.on('connection', (ws) => 
{
    ws.on('message', (message) => 
    {
        const chunks = message.toString().split('|');
        const netcode = Number(chunks[0]);

        // # Netcode: 11 => Registrar.
        if(netcode == 11)
        {
            matchmaking.AddPlayerToQueue({"nickname": chunks[1], "con": ws, "IsReady": false, "isCloseGame": false});
            console.log(`Jogodor '${chunks[1]}' entrou na fila de espera.`);
            ws.send("15");
        }
        // # Netcode: 14 => Teste de conexão.
        else if(netcode == 14)
        {
            ws.send("OK");
        }
        // # Netcode: 17 => Espectador quer a lista de partidas.
        else if(netcode == 17)
        {
            let match_list = `17|${matches.filter(e => !e.isGamaOver()).map(e => `${e.ID}-${e.Players[0].nickname}-${e.Players[1].nickname}`).join('#')}`;
            ws.send(match_list);
            // console.log("List: ", match_list);
            // console.log("List: ", matches);
        }
        // # Netcode: 18 => Espectador quer assistir a partida.
        else if(netcode == 18)
        {
            let match = matches.find(e => e.ID == chunks[1]);
            
            if(match)
                match.AssignSpectator(ws);
            else
                console.log(`Partida não encontrada para o ID, requisitado pelo telespectador: ${IDMatch}`);
        }
        // # Netcode: 19 => Espectador não mais quer assistir a partida.
        else if(netcode == 19)
        {
            let match = matches.find(e => e.ID == chunks[1]);
            
            if(match)
            {
                ws.send("19");
                match.RemoveSpectator(chunks[1]);
            }
            else
                console.log(`Partida não encontrada para o ID, requisitado pelo telespectador: ${IDMatch}`);
        }
        else
        {
            let IDMatch = chunks[chunks.length - 1];
            
            let match = matches.find(e => e.ID == IDMatch);
            
            if(match)
                match.PushMessage(message);
            else
                console.log(`Partida não encontrada para o ID: ${IDMatch}`);
        }
    });

    ws.on('close', () => {
        console.log('Jogador desconectado!');

        // # Remove o jogador da fila.
        matchmaking.playerList = matchmaking.playerList.filter(player => player.con !== ws);
        
        // # Remover da partida em andamento.
        matches.forEach(match => {
            match.Players = match.Players.filter(player => player.con !== ws);
            if (match.Players.length < 2) {
                match.GameIsRunning = false; // Encerrar partida
            }
        });
    });
});

// Função de loop para verificar novas partidas a cada 100ms
setInterval(() => 
{
    // # Verifica se foi possível formar partida.
    if(matchmaking.IsMatchFound()) 
    {
        let prematch = matchmaking.CreateMatch();
        let match = new Match(prematch);
        matches.push(match);
        match.LoadGame();
        console.log("Nova partida iniciada com o ID: ", match.ID);
    }

    // # Limpa as partidas terminadas.
    matches = matches.filter(e => !e.isGamaOver());

}, 100); // Intervalo de 100ms para verificar novas partidas

function getLocalIP() 
{
    const networkInterfaces = os.networkInterfaces();
    
    // Itera sobre as interfaces de rede
    for (const interfaceName in networkInterfaces) {
        for (const iface of networkInterfaces[interfaceName]) {
            // Verifica se a interface é do tipo IPv4 e não é a loopback
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;  // Retorna o IP encontrado
            }
        }
    }
    return 'Não foi possível encontrar o IP';
}




