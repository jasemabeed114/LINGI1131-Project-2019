functor
import
   GUI
   Input
   PlayerManager
   Browser
   OS
define
   WindowPort

   InitPlayers
   InitPlayersSpawnInformation
   TurnByTurn
   ProcessBombs
   DisableFirePreviousTurn
   SetMapVal
   MapChange
   MapChangeAdvanced
   CheckMove
   InformationPlayers
   PropagationFire
   CheckEndGame
   CheckEndGameAdvanced
   
   
   Map
   NbPlayers
   Positions
   PlayersPosition % Port of all the players
   PlayersPort  % Initial position of all the players

   
   TimeFireDisplay
   SimultaneousInitLoop
   APlayer
   MapHandler
   MapPort
   MapStream
   BombHandler
   BombPort
   BombStream
   PositionsHandler
   PositionPort
   PositionStream
   EndGamePort
   EndGameStream

   ForceEndGame
   PropagationFireSimult
   GetMapVal

in

   Map = Input.map

   %%%%%% Simultaneous %%%%%%%
   TimeFireDisplay = 1000


   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window
   {Delay 10000}

   NbPlayers = Input.nbBombers

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players
   {Browser.browse PlayersPort}
   {Browser.browse PlayersPosition}
   thread {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions PlayersPosition PlayersPort} end
   if Input.isTurnByTurn then
        Next
    in
      thread 
        {InitPlayersSpawnInformation PlayersPort PlayersPosition}
        {TurnByTurn Map PlayersPort PlayersPosition Next Next nil nil|_} 
      end
   else
        thread
            IDs
        in
            IDs = {InitPlayersSpawnInformation PlayersPort PlayersPosition}
            BombPort = {NewPort BombStream}
            MapPort = {NewPort MapStream}
            PositionPort = {NewPort PositionStream}
            EndGamePort = {NewPort EndGameStream}

            thread {BombHandler BombStream} end
            thread {MapHandler MapStream Map} end
            thread {PositionsHandler PositionStream PlayersPosition} end
            thread {CheckEndGameAdvanced EndGameStream IDs nil} end
            {SimultaneousInitLoop PlayersPort}
        end
   end
    fun{InitPlayersSpawnInformation PlayerPort PlayersPosition}
        case PlayerPort#PlayersPosition
        of nil#nil then nil
        [](PortH|PortT)#(PositionH|PositionT) then 
            ID 
        in
            {Send PortH getId(ID)}
            {Wait ID}
            thread {InformationPlayers PlayerPort info(spawnPlayer(ID PositionH))} end
            ID|{InitPlayersSpawnInformation PortT PositionT}
        end
    end
    proc{InitPlayers NbPlayers ColorPlayers NamePlayers Positions PlayersPosition PlayersPort}
        if NbPlayers == 0 then 
            PlayersPosition = nil PlayersPort = nil
        else
            case ColorPlayers#NamePlayers#Positions
            of (ColorH|ColorT)#(NameH|NameT)#(PositionH|PositionT) then 
                ID PlayerPort Position IDS PlayersPositionTail PlayersPortTail
            in
                ID = bomber(id:NbPlayers color:ColorH name:NameH)
                PlayerPort = {PlayerManager.playerGenerator NameH ID}
                {Send PlayerPort assignSpawn(PositionH)}
                {Send PlayerPort spawn(IDS Position)}
                {Send WindowPort initPlayer(ID)}
                {Send WindowPort spawnPlayer(ID PositionH)}
                PlayersPosition = Position|PlayersPositionTail
                PlayersPort     = PlayerPort|PlayersPortTail
                {InitPlayers NbPlayers-1 ColorT NameT PositionT PlayersPositionTail PlayersPortTail}
            end
        end
    end