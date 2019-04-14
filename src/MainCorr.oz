functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   WindowPort

   InitPlayers
   TurnByTurn
   ProcessBombs
   DisableFirePreviousTurn
   
   
   Map
   NbPlayers
   Positions
   PlayersPosition % Port of all the players
   PlayersPort  % Initial position of all the players
in

   Map      = Input.map

   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   NbPlayers = Input.nbBombers

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players
   {Browser.browse PlayersPort}
   {Browser.browse PlayersPosition}
   thread {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions PlayersPosition PlayersPort}
   {Send PlayersPort.1 info(boxRemoved(pt(x:4 y:2)))}
   end
   if Input.isTurnByTurn then
        Next
    in
      thread {TurnByTurn PlayersPort PlayersPosition Next Next nil nil} end
   else
      skip %simultane
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

    proc{TurnByTurn PlayersPortTail PlayersPositionCurrent PlayersPositionNext PlayersPositionNextEnd Bombs Fires}
        case PlayersPortTail#PlayersPositionCurrent of nil#_ then
            FutureNext % For the recursion
            NewBombs
        in
            PlayersPositionNextEnd = nil % End of the list NextEnd
            % The PlayersPositionNext is now complete with all the new positions

            %% Process here the explosion and the rest
            {ProcessBombs Bombs NewBombs PlayersPositionNext}
            thread {DisableFirePreviousTurn Fires} end

            %% Recursion back to the beginning
            {Delay 500}
            {TurnByTurn PlayersPort PlayersPositionNext FutureNext FutureNext NewBombs Fires}
        [] (PortH|PortT)#(PositionH|PositionT) then
            ID State
        in
            {Send PortH getState(ID State)}

            if State == on then % Still on the map
                IDAction Action
            in
                {Send PortH doaction(IDAction Action)}
                case Action of move(Pos) then
                    NextEnd2
                in
                    {Send WindowPort movePlayer(ID Pos)}

                    %% Recursion
                    PlayersPositionNextEnd = Pos|NextEnd2
                    {TurnByTurn PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                
                [] bomb(Pos) then
                    NextEnd2
                in 
                    {Send WindowPort spawnBomb(Pos)} % Show the bomb on the window

                    %% Recursion
                    PlayersPositionNextEnd = PositionH|NextEnd2
                    {TurnByTurn PortT PositionT PlayersPositionNext NextEnd2 (Input.timingBomb#Pos#PortH)|Bombs Fires}
                
                else
                    NextEnd2
                in
                    %% Recursion
                    PlayersPositionNextEnd = PositionH|NextEnd2
                    {TurnByTurn PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                end
            else
                NextEnd2
            in  
                %% Recursion
                PlayersPositionNextEnd = PositionH|NextEnd2
                {TurnByTurn PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
            end
        end
    end

    proc{ProcessBombs Bombs NewBombs PlayersPosition}
        proc{SendBombExplodedPlayers PlayersPort Pos}
            case PlayersPort of nil then skip
            [] H|T then
                {Send H info(bombExploded(Pos))}
                {SendBombExplodedPlayers T Pos}
            end
        end
    in
        case Bombs of nil then NewBombs = nil
        [] (N#Pos#PortPlayer)|T then
            if N == 0 then % Explosion of the bomb
                Result
            in
                {Send WindowPort hideBomb(Pos)} % GUI information
                {Send PortPlayer add(bomb 1 Result)} % Giving back the bomb
                {SendBombExplodedPlayers PlayersPort Pos} % Warn the other players of the bomb exploded
                %{PropagationFire Pos PlayersPosition} % Propagation of the fire
                {ProcessBombs T NewBombs PlayersPosition} % Recursion
            else
                NewBombsTails
            in
                NewBombs = ((N-1)#Pos#PortPlayer)|NewBombsTails % Substract 1 to the delay
                {ProcessBombs T NewBombsTails PlayersPosition} % Recursion
            end
        end
    end

    proc{DisableFirePreviousTurn Fires}
        case Fires of nil then skip
        [] nil|_ then skip
        []H|T then
            {Send WindowPort hideFire(H)} % GUI ask to hide the fire
            {DisableFirePreviousTurn T} % Recursion
        end
    end

    %proc{PropagationFire Pos}
    %end


end