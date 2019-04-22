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
    CheckMove
    InformationPlayers
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
        IDs 
    in
        thread 
            IDs = {InitPlayersSpawnInformation PlayersPort PlayersPosition}
            BombPort = {NewPort BombStream}
            MapPort = {NewPort MapStream}
            PositionPort = {NewPort PositionStream}
            EndGamePort = {NewPort EndGameStream}

            thread {BombHandler BombStream} end
            thread {MapHandler MapStream Map} end
            thread {PositionsHandler PositionStream PlayersPosition} end
            thread {CheckEndGameAdvanced EndGameStream IDs nil} end
            {TurnByTurn PlayersPort nil}
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
                ID PlayerPort Position PlayersPositionTail PlayersPortTail
            in
                ID = bomber(id:NbPlayers color:ColorH name:NameH)
                PlayerPort = {PlayerManager.playerGenerator NameH ID}
                {Send PlayerPort assignSpawn(PositionH)}
                {Send PlayerPort spawn(_ Position)}
                {Send WindowPort initPlayer(ID)}
                {Send WindowPort spawnPlayer(ID PositionH)}
                PlayersPosition = Position|PlayersPositionTail
                PlayersPort     = PlayerPort|PlayersPortTail
                {InitPlayers NbPlayers-1 ColorT NameT PositionT PlayersPositionTail PlayersPortTail}
            end
        end
    end

    fun{ProcessBombs TheBombs}
        case TheBombs of nil then nil % we processed all the bombs
        [] N#Pos#BomberPort|T then
            if N == 0 then % Bomb has to explode
            {Send WindowPort hideBomb(Pos)} % GUI information
            {Send BomberPort add(bomb 1 _)} % Giving back the bomb
            % Informing other players
            thread {InformationPlayers PlayersPort info(bombExploded(Pos))} end
            {Send BombPort bombExplode(Pos)}
            {ProcessBombs T}
            else
                ((N-1)#Pos#BomberPort)|{ProcessBombs T}
            end
        end
    end

    proc{TurnByTurn ThePlayersPort TheBombs}
        fun{AmIAlive L ID}
            case L of nil then false
            [] H|T then
            if H.id == ID.id then true
            else {AmIAlive T ID}
            end
            end
        end
    in 
        case ThePlayersPort of nil then % All the players have played
            NewBombs
        in
            {Delay 500}
            NewBombs = {ProcessBombs TheBombs}
            {TurnByTurn PlayersPort NewBombs}
        [] PortH|PortT then % A player to move
            ID
            AlivePlayers
        in
            {Send PortH getState(ID _)}
            {Send EndGamePort getAlive(AlivePlayers)}
            if {AmIAlive AlivePlayers ID} then % Alive player
                Action
                TheMap
                Value
            in
                {Send PortH doaction(_ Action)}
                case Action of move(Pos) then % Move
                    {Send WindowPort movePlayer(ID Pos)}
                    {Send PositionPort modif(ID#Pos)}
                    thread {InformationPlayers PlayersPort info(movePlayer(ID Pos))} end

                    % Now check if it has a bonus
                    {Send MapPort get(TheMap)}
                    Value = {CheckMove Pos.x Pos.y TheMap}
                    if Value == pointfloor then % Point bonus
                        Result
                    in
                        {Send PortH add(point 1 Result)} % Give the point
                        {Send WindowPort hidePoint(Pos)}
                        {Wait Result}
                        {Send WindowPort scoreUpdate(ID Result)}
                        {Send MapPort modif(Pos#0)}

                        if Result >= 50 then % The player has won
                            {Send WindowPort displayWinner(ID)}
                        else
                            {TurnByTurn PortT TheBombs}
                        end
                    elseif Value == bonusfloor then % Bonus, random
                        Rand
                    in
                        Rand = ({OS.rand} mod 2) + 1
                        if Rand == 1 then % We give 10 points of bonus
                            Result
                        in
                            {Send PortH add(point 10 Result)}
                            {Send WindowPort hideBonus(Pos)}
                            {Wait Result}
                            {Send WindowPort scoreUpdate(ID Result)}
                            {Send MapPort modif(Pos#0)}
                            if Result >= 50 then % The player has won
                                {Send WindowPort displayWinner(ID Result)}
                            else
                                {TurnByTurn PortT TheBombs}
                            end
                        else % This is a bomb
                            {Send PortH add(bomb 1 _)}
                            {Send WindowPort hideBonus(Pos)}
                            {Send MapPort modif(Pos#0)}
                            {TurnByTurn PortT TheBombs}
                        end 
                    else
                        {TurnByTurn PortT TheBombs}
                    end
                [] bomb(Pos) then
                    {Send WindowPort spawnBomb(Pos)}
                    thread {InformationPlayers PlayersPort info(bombPlanted(Pos))} end
                    {TurnByTurn PortT (Input.timingBomb#Pos#PortH)|TheBombs}
                else
                    {TurnByTurn PortT TheBombs}
                end
            else
                {TurnByTurn PortT TheBombs}
            end
        end
    end

    proc{InformationPlayers Ports InformationMessage}
        case Ports of nil then skip
        [] H|T then
            {Send H InformationMessage}
            {InformationPlayers T InformationMessage}
        end
    end

   fun{CheckMove X Y Map}
        fun{CheckMap X Y}
            fun{Nth L N}
                if N == 1 then L.1
                else {Nth L.2 N-1}
                end
            end
        Point
        in
            Point = {Nth {Nth Map Y} X}
            if     Point == 0 then floor
            elseif Point == 1 then wall
            elseif Point == 2 then point
            elseif Point == 3 then bonus
            elseif Point == 4 then spawn
            elseif Point == 5 then pointfloor
            elseif Point == 6 then bonusfloor
            end
        end
    in
        if (X >= 1 andthen X < Input.nbColumn+1 andthen Y >= 1 andthen Y < Input.nbRow+1) == true then
            {CheckMap X Y}
        else
            false
        end
    end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% FOR THE SIMULTANEOUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc{SimultaneousInitLoop PlayersPort}
        case PlayersPort of H|T then
            thread {APlayer H} end
            {SimultaneousInitLoop T}
        [] nil then skip
        end
    end

    proc{APlayer MyPort}
        fun{AmIAlive L ID}
            case L of nil then false
            [] H|T then
                if H.id == ID.id then true
                else {AmIAlive T ID}
                end
            end
        end
        proc{Loop}
            TimeWait
            ID
            AlivePlayers
        in
            %TimeWait = ({OS.rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin
            TimeWait = 500
            {Delay TimeWait}
            {Send EndGamePort getAlive(AlivePlayers)}
            {Send MyPort getState(ID _)}
            if {AmIAlive AlivePlayers ID} then % Alive player
                Action
                TheMap
                Value
            in
                {Send MyPort doaction(_ Action)}
                case Action of move(Pos) then
                    {Send WindowPort movePlayer(ID Pos)}
                    {Send PositionPort modif(ID#Pos)}
                    thread {InformationPlayers PlayersPort info(movePlayer(ID Pos))} end

                    % Now check if it has a bonus
                    {Send MapPort get(TheMap)}
                    Value = {CheckMove Pos.x Pos.y TheMap}
                    if Value == pointfloor then % Point bonus
                        Result
                    in
                        {Send MyPort add(point 1 Result)} % Give the point to the player
                        {Send WindowPort hidePoint(Pos)}
                        {Wait Result}
                        {Send WindowPort scoreUpdate(ID Result)}
                        {Send MapPort modif(Pos#0)}

                        if Result >= 50 then % The player has won
                            {Send WindowPort displayWinner(ID)}
                            {ForceEndGame}
                        else
                            {Loop}
                        end
                    elseif Value == bonusfloor then % Bonus, random
                        Rand
                    in
                        Rand = ({OS.rand} mod 2) + 1
                        if Rand == 1 then % We give 10 points of bonus
                            Result
                        in
                            {Send MyPort add(point 10 Result)}
                            {Send WindowPort hideBonus(Pos)}
                            {Wait Result}
                            {Send WindowPort scoreUpdate(ID Result)}
                            {Send MapPort modif(Pos#0)}
                            if Result >= 50 then % The player has won
                                {Send WindowPort displayWinner(ID Result)}
                                {ForceEndGame}
                            else
                                {Loop}
                            end
                        else % This is a bomb
                            {Send MyPort add(bomb 1 _)}
                            {Send WindowPort hideBonus(Pos)}
                            {Send MapPort modif(Pos#0)}
                            {Loop}
                        end
                    else
                        {Loop}
                    end
                [] bomb(Pos) then % Drops a bomb
                    {Send WindowPort spawnBomb(Pos)}
                    thread {InformationPlayers PlayersPort info(bombPlanted(Pos))} end
                    thread 
                        TimingBomb
                    in
                        TimingBomb = ({OS.rand} mod (Input.timingBombMax - Input.timingBombMin)) + Input.timingBombMin
                        {Delay TimingBomb}
                        {Send BombPort bombExplode(Pos)}
                        {Send MyPort add(bomb 1 _)}
                    end
                    {Loop}
                else
                    % null because it was off
                    {Loop}
                end
            else
                % Dead player
                skip % Stop
            end
        end
    in
        {Loop}
    end



    proc{PositionsHandler Stream Positions}
        fun{ChangePositions ThePositions ID Pos}
            fun{Loop L Count}
                case L of nil then nil
                [] H|T then
                    if Count == ID.id then % the player
                        Pos|T
                    else
                        H|{Loop T Count-1}
                    end
                end
            end
        in
            {Loop ThePositions Input.nbBombers}
        end
    %%%%%%%%%%%%%%%%%%%
    in
        case Stream of Message|T then
            case Message of modif(ID#Pos) then 
                % The ID of the player starts at Input.nbBombers
                NewPositions
            in
                NewPositions = {ChangePositions Positions ID Pos}
                {PositionsHandler T NewPositions}
            [] get(PositionsGetter) then % Wants to get the positions
                PositionsGetter = Positions % We bind it to the positions
                {PositionsHandler T Positions}
            else
                {Browser.browse errorPositionsHandler}
            end
        end
    end

    proc{MapHandler Stream Map}
        fun{SetMapVal Map X Y Value}
            fun{Modif L N Value}
                case L of nil then nil
                [] H|T then
                    if N == 1 then Value|T
                    else H|{Modif T N-1 Value}
                    end
                end
            end
        in
            case Map of nil then nil
            [] H|T then
                if Y == 1 then
                    {Modif H X Value}|T
                else
                    H|{SetMapVal T X Y-1 Value}
                end
            end
        end
    %%%%%%%%%%%%%%%%%%%%
    in
        case Stream of Message|T then
            case Message of modif(Pos#Value) then % Modif the map
                NewMap
            in
                NewMap = {SetMapVal Map Pos.x Pos.y Value}
                {MapHandler T NewMap}
            [] get(MapGetter) then % Want to get the map
                MapGetter = Map
                {MapHandler T Map}
            end
        end
    end

    proc{BombHandler Stream}
        case Stream of Message|T then
            case Message of bombExplode(Pos) then
                ResultEndGame
                TheMap
            in
                {Send WindowPort hideBomb(Pos)}
                {InformationPlayers PlayersPort info(bombExploded(Pos))} % inform other
                {Send MapPort get(TheMap)}
                {PropagationFireSimult Pos TheMap}
                {Send EndGamePort getEndGame(ResultEndGame)}
                if ResultEndGame == none then % Not the end
                    {BombHandler T}
                else % End of game
                    {ForceEndGame}
                    {Send WindowPort displayWinner(ResultEndGame)}
                end
            else
                {Browser.browse errorBombHandler}
            end
        end
    end

    proc{PropagationFireSimult BombPosition TheMap}

        proc{ProcessDeath FirePosition PlayerPorts PlayersPosition}
            case PlayerPorts#PlayersPosition of nil#_ then skip
            [] (PortH|PortT)#(PosH|PosT) then
                if FirePosition.x == PosH.x andthen FirePosition.y == PosH.y then
                    ID Result
                in
                    {Send PortH gotHit(ID Result)}
                    {Wait Result}
                    case Result of death(NewLife) then % Was on board
                        if NewLife == 0 then % Dead player
                            thread {InformationPlayers PlayersPort info(deadPlayer(ID))} end
                            {Send WindowPort hidePlayer(ID)}
                            {Send WindowPort lifeUpdate(ID NewLife)}
                            {Send EndGamePort deadPlayer(ID _)}
                            {ProcessDeath FirePosition PortT PosT}
                        else % Stil has lives
                            SpawnPosition
                        in
                            {Send PortH spawn(_ SpawnPosition)}
                            {Send PositionPort modif(ID#SpawnPosition)}
                            {Send WindowPort movePlayer(ID SpawnPosition)}
                            {Send WindowPort lifeUpdate(ID NewLife)}
                            thread {InformationPlayers PlayersPort info(spawnPlayer(ID SpawnPosition))} end

                            % Recursion
                            {ProcessDeath FirePosition PortT PosT}
                        end
                    else
                        {ProcessDeath FirePosition PortT PosT}
                    end
                else
                    {ProcessDeath FirePosition PortT PosT}
                end
            end
        end

        proc{PropagationOneDirection CurrentPosition PreviousPosition Count}
            %{Delay 1000}
            if Count >= Input.fire then skip
            else
                case CurrentPosition of pt(x:X y:Y) then
                    Check
                in
                    Check = {CheckMove X Y TheMap}
                    if Check == wall then skip
                        % It is a wall
                        % Stop propaging and bounds Changing to null because nothing changes
                    elseif Check == point then
                        % It is a point box
                        % Destroy the box and stop propaging
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        thread {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} end % Warn other players 
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnPoint(CurrentPosition)} % And shows the point
                        {Send MapPort modif(CurrentPosition#5)}
                    elseif Check == bonus then
                        % It is a bonus box
                        % Destroy the box and stop propaging
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        thread {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} end % Warn other players
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnBonus(CurrentPosition)} % And shows the bonus
                        {Send MapPort modif(CurrentPosition#6)}
                    else
                        % Either a floor tile, a point or a bonus
                        % For the time being, we let them in place
                        % Continue propaging, and sends the position of the fire
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        {ProcessDeath CurrentPosition PlayersPort PlayerActualPositions}
                        case PreviousPosition of pt(x:XP y:YP) then
                            XF YF 
                        in
                            XF = X + (X-XP) % New position X
                            YF = Y + (Y-YP) % New position Y
                            {PropagationOneDirection pt(x:XF y:YF) CurrentPosition Count+1}
                        end
                    end
                end
            end
        end
        PlayerActualPositions
    in
        {Send PositionPort get(PlayerActualPositions)}
        case BombPosition of pt(x:X y:Y) then
            thread
                thread
                    {Send WindowPort spawnFire(BombPosition)}
                    {Delay TimeFireDisplay}
                    {Send WindowPort hideFire(BombPosition)}
                end
                {ProcessDeath BombPosition PlayersPort PlayerActualPositions}
                {PropagationOneDirection pt(x:X+1 y:Y) BombPosition 0}
                {PropagationOneDirection pt(x:X-1 y:Y) BombPosition 0}
                {PropagationOneDirection pt(x:X y:Y+1) BombPosition 0}
                {PropagationOneDirection pt(x:X y:Y-1) BombPosition 0}
            end
        end

    end

    proc{ForceEndGame}
        proc{Loop Ports}
            case Ports of nil then skip
            [] H|T then
                ID
            in
                {Send H getState(ID _)}
                {Send EndGamePort deadPlayer(ID)}
                {Loop T}
            end
        end
    in
        {Loop PlayersPort}
    end

    proc{CheckEndGameAdvanced Stream AlivePlayers DeadPlayers}
        fun{DeleteDeadPlayer AlivePlayers Dead}
            case AlivePlayers of H|T then
                if H.id == Dead.id then T
                else
                    H|{DeleteDeadPlayer T Dead}
                end
            [] nil then nil
            end
        end
    in
        case Stream of H|T then
            case H of deadPlayer(ID Result) then
                RestAlive
            in
                RestAlive = {DeleteDeadPlayer AlivePlayers ID}
                case RestAlive of TheWinner|nil then
                    Result = TheWinner % He has won
                else
                    Result = none
                    {CheckEndGameAdvanced T RestAlive ID|DeadPlayers}
                end
            [] get(Deads) then
                Deads = DeadPlayers
                {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
            [] getEndGame(Result) then 
                case AlivePlayers of TheWinner|nil then % only one player
                    Result = TheWinner
                else
                    Result = none
                    {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
                end
            [] getAlive(Alives) then
                Alives = AlivePlayers
                {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
            end
        end
    end

end