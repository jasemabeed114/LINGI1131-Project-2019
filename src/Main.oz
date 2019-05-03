functor
import
    GUI
    Input
    PlayerManager
    System
    OS
export
    startGame:StartGame
define
    WindowPort
    StartGame

    InitPlayers
    InitPlayersSpawnInformation
    TurnByTurn
    ProcessBombs
    CheckMove
    InformationPlayers
    CheckEndGameAdvanced


    Map
    LookForSpawn
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
    BoxHandler
    BoxPort
    BoxStream
    PointHandler
    PointPort
    PointStream

    ForceEndGame
    PropagationFireSimult

    IDs

in

    Map = Input.map

    %% The fire is displayed on the screen for 1 sec
    TimeFireDisplay = 1000


    %% Implement your controller here
    WindowPort = {GUI.portWindow} % Create the window port
    {Send WindowPort buildWindow} % Init the window

    % The initial procedure called by the button in the GUI to start the game
    proc{StartGame}
        thread
            NbPlayers = Input.nbBombers
            Positions = {LookForSpawn Input.map}
            if {Length Positions} < NbPlayers then % More players than positions
                {System.show 'Eror, the number of players is higher than the number of spawns'}
            else
                {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions PlayersPosition PlayersPort}
                if Input.isTurnByTurn then
                    thread 
                        IDs = {InitPlayersSpawnInformation PlayersPort PlayersPosition}
                        BombPort = {NewPort BombStream}
                        MapPort = {NewPort MapStream}
                        PositionPort = {NewPort PositionStream}
                        EndGamePort = {NewPort EndGameStream}
                        BoxPort = {NewPort BoxStream}
                        PointPort = {NewPort PointStream}

                        thread {BombHandler BombStream} end
                        thread {MapHandler MapStream Map} end
                        thread {PositionsHandler PositionStream PlayersPosition} end
                        thread {CheckEndGameAdvanced EndGameStream IDs nil} end
                        thread {BoxHandler BoxStream} end
                        thread {PointHandler PointStream} end
                        {TurnByTurn PlayersPort nil}
                    end
                else
                    thread
                        IDs = {InitPlayersSpawnInformation PlayersPort PlayersPosition}
                        BombPort = {NewPort BombStream}
                        MapPort = {NewPort MapStream}
                        PositionPort = {NewPort PositionStream}
                        EndGamePort = {NewPort EndGameStream}
                        BoxPort = {NewPort BoxStream}
                        PointPort = {NewPort PointStream}

                        thread {BombHandler BombStream} end
                        thread {MapHandler MapStream Map} end
                        thread {PositionsHandler PositionStream PlayersPosition} end
                        thread {CheckEndGameAdvanced EndGameStream IDs nil} end
                        thread {BoxHandler BoxStream} end
                        thread {PointHandler PointStream} end
                        {SimultaneousInitLoop PlayersPort}
                    end
                end
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% FOR THE INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    /*
     Gives all the spawn positions
     */
    fun{LookForSpawn Map}
        fun{LoopLine Line Y X}
            case Line of nil then nil
            [] H|T then
	            if H == 4 then % Spawn
            	    pt(x:X y:Y)|{LoopLine T Y X+1}
	             else
	                {LoopLine T Y X+1}
	             end
             end
         end
         fun{Loop TheMap Acc Y}
            case TheMap of nil then Acc
            [] Line|Rest then % Treat one line at a time
	             CurrentTreat
	             Acc2
              in
	            CurrentTreat = {LoopLine Line Y 1}
	            Acc2 = {Append Acc CurrentTreat}
	            {Loop Rest Acc2 Y+1}
            end
        end
    in
        {Loop Map nil 1}
    end

    /*
     Tell all the players the spawn of everybody
     */
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

    /*
     Init all the players: gives the ID, spawn
     */
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

    /*
     Procedure that informs all the players of the InformationMessage message
     */
    proc{InformationPlayers Ports InformationMessage}
        case Ports of nil then skip
        [] H|T then
            {Send H InformationMessage}
            {InformationPlayers T InformationMessage}
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FOR THE TURNBYTURN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    /*
     TurnByTurn main controler
     */
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
            ResultEndGame
            TimeWait
        in
            if {Not Input.useExtention} then
                TimeWait = ({OS.rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin
            else
                TimeWait = 500
            end
            NewBombs = {ProcessBombs TheBombs}
            {Wait NewBombs}
            {Send EndGamePort getEndGame(ResultEndGame)}
            if ResultEndGame == false then % Not the end
                {Delay TimeWait}
                {TurnByTurn PlayersPort NewBombs}
            else
                skip % End of the game, we stop
            end
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
                        {Send PointPort add(ID 1)} % Just for the future
                        {TurnByTurn PortT TheBombs}
                    elseif Value == bonusfloor then % Bonus, random
                        Rand
                    in
                        if Input.useExtention then
                            Rand = ({OS.rand} + 1) mod 4
                            if Rand == 0 then % We give 10 points of bonus
                                Result
                            in
                                {Send PortH add(point 10 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort scoreUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {Send PointPort add(ID 10)} % Just for the future
                                {TurnByTurn PortT TheBombs}
                            elseif Rand == 1 then % This is a bomb
                                {Send PortH add(bomb 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {TurnByTurn PortT TheBombs}
                            elseif Rand == 2 then%shield
                                {Send PortH add(shield 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {TurnByTurn PortT TheBombs}
                            else % life
                                Result
                            in
                                {Send PortH add(life 1 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort lifeUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {TurnByTurn PortT TheBombs}
                            end
                        else
                            Rand = ({OS.rand} mod 2) + 1
                            if Rand == 1 then % We give 10 points of bonus
                                Result
                            in
                                {Send PortH add(point 10 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort scoreUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {Send PointPort add(ID 10)} % Just for the future
                                {TurnByTurn PortT TheBombs}
                            else % This is a bomb
                                {Send PortH add(bomb 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {TurnByTurn PortT TheBombs}
                            end
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

    /*
     Function used in the TurnByTurn mode to treat the dropped bombs
     */
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

    /*
     Check if the move to the position pt(x:X y:Y) is valid with the map Map
     */
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

    /*
     Initialisation loop for the simultaneous part
     */
    proc{SimultaneousInitLoop PlayersPort}
        case PlayersPort of H|T then
            thread {APlayer H} end
            {SimultaneousInitLoop T}
        [] nil then skip
        end
    end

    /*
     Main crontroller for a player
     */
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
            ID
            AlivePlayers
            TimeWait
            State
        in
            if {Not Input.useExtention} then
                TimeWait = ({OS.rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin
            else
                TimeWait = 500
            end
            {Send EndGamePort getAlive(AlivePlayers)}
            {Send MyPort getState(ID State)}
            if {AmIAlive AlivePlayers ID} andthen State == on then % Alive player
                Action
                TheMap
                Value
            in
                {Delay TimeWait}
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
                        {Send PointPort add(ID 1)} % Just for the future
                        {Loop}
                    elseif Value == bonusfloor then % Bonus, random
                        Rand
                    in 
                        if Input.useExtention then
                            Rand = ({OS.rand} + 1) mod 4
                            if Rand == 0 then % We give 10 points of bonus
                                Result
                            in
                                {Send MyPort add(point 10 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort scoreUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {Send PointPort add(ID 10)} % Just for the future
                                {Loop}
                            elseif Rand == 1 then % This is a bomb
                                {Send MyPort add(bomb 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {Loop}
                            elseif Rand == 2 then %shied
                                {Send MyPort add(shield 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {Loop}
                            else % life
                                Result
                            in
                                {Send MyPort add(life 1 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort lifeUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {Loop}
                            end
                        else
                            Rand = ({OS.rand} mod 2) + 1
                            if Rand == 1 then % We give 10 points of bonus
                                Result
                            in
                                {Send MyPort add(point 10 Result)}
                                {Send WindowPort hideBonus(Pos)}
                                {Wait Result}
                                {Send WindowPort scoreUpdate(ID Result)}
                                {Send MapPort modif(Pos#0)}
                                {Send PointPort add(ID 10)} % Just for the future
                                {Loop}
                            else % This is a bomb
                                {Send MyPort add(bomb 1 _)}
                                {Send WindowPort hideBonus(Pos)}
                                {Send MapPort modif(Pos#0)}
                                {Loop}
                            end
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%% AGENTS USED FOR BOTH GAME MODES %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    /*
     Agent that handles the positions of the players
     */
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
                {System.show 'Unknown received message in PositionHandler'}
            end
        end
    end

    /*
     Agent that handles the map
     */
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

    /*
     Agent that handles the bombs to eplode now
     */
    proc{BombHandler Stream}
        case Stream of Message|T then
            case Message of bombExplode(Pos) then
                ResultEndGame
                TheMap
                ResultWaitOut
            in
                {Send WindowPort hideBomb(Pos)}
                {InformationPlayers PlayersPort info(bombExploded(Pos))} % inform other
                {Send MapPort get(TheMap)}
                {PropagationFireSimult Pos TheMap ResultWaitOut}
                {Wait ResultWaitOut}
                {Send EndGamePort getEndGame(ResultEndGame)}
                if ResultEndGame == false then % Not the end
                    {BombHandler T}
                else % End of game
                    Winner
                in
                    {ForceEndGame}
                    {Send PointPort endGame(Winner)}
                    {Wait Winner}
                    {Send WindowPort displayWinner(Winner)}
                end
            else
                {System.show 'Unknown received message in BombHandler'}
            end
        end
    end

    /*
     Propagates the fire from position BombPosition to cardinal directions
     */
    proc{PropagationFireSimult BombPosition TheMap ResultWaitOut}

        /*
         Check if the fire at position FirePosition killed some players
         */
        proc{ProcessDeath FirePosition PlayerPorts PlayersPosition}
            case PlayerPorts#PlayersPosition of nil#_ then skip
            [] (PortH|PortT)#(PosH|PosT) then
                if FirePosition.x == PosH.x andthen FirePosition.y == PosH.y then
                    ID Result
                in
                    {Send PortH gotHit(ID Result)}
                    {Wait Result}
                    case Result 
                    of death(NewLife) then % Was on board
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
                            {Wait SpawnPosition}
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

        /*
         Propagates the fire in one direction
         */
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
                        Result
                    in
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
                        {Send BoxPort boxExploded(CurrentPosition 5 Result)}
                        if Result then % End of game by lack of boxes
                            Winner
                        in
                            {ForceEndGame}
                            {Send PointPort endGame(Winner)}
                            {Wait Winner}
                            {Send WindowPort displayWinner(Winner)}
                        end
                    elseif Check == bonus then
                        Result
                    in
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
                        {Send BoxPort boxExploded(CurrentPosition 6 Result)}
                        if Result then % End of game by lack of boxes
                            Winner
                        in
                            {ForceEndGame}
                            {Send PointPort endGame(Winner)}
                            {Wait Winner}
                            {Send WindowPort displayWinner(Winner)}
                        end
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
                ResultWaitOut = 1
            end
        end
    end

    /*
     Procedure to force the end of the game:
     it sends to the EndGame port that all the players are dead
     */
    proc{ForceEndGame}
        proc{Loop Ports}
            case Ports of nil then skip
            [] H|T then
                ID
            in
                {Send H getState(ID _)}
                %{Send H gotHit(_ _)}
                {Send EndGamePort deadPlayer(ID _)}
                {Loop T}
            end
        end
    in
        {Loop PlayersPort}
    end

    /*
     Check if it is the end of the game relatively to the number of players alive on the board
     */
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
                case RestAlive of _|nil then
                    Result = true % He has won
                    {CheckEndGameAdvanced T RestAlive ID|DeadPlayers}
                [] nil then
                    Result = true
                    {CheckEndGameAdvanced T RestAlive ID|DeadPlayers}
                else
                    Result = false
                    {CheckEndGameAdvanced T RestAlive ID|DeadPlayers}
                end
            [] get(Deads) then
                Deads = DeadPlayers
                {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
            [] getEndGame(Result) then 
                case AlivePlayers of nil then % only one player
                    Result = true
                    {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
                [] _|nil then
                    Result = true
                    {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
                else
                    Result = false
                    {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
                end
            [] getAlive(Alives) then
                Alives = AlivePlayers
                {CheckEndGameAdvanced T AlivePlayers DeadPlayers}
            end
        end
    end

    /*
     Agent that handles the number of boxes on the board
     Can tell if it is the end of the game because there isn't any box left on the board
     */
    proc{BoxHandler Stream}
        fun{Nth L N}
            if N == 1 then L.1
            else
                {Nth L.2 N-1}
            end
        end

        fun{InitLine Line Count}
            case Line of nil then Count
            [] H|T then
                if H == 2 orelse H == 3 then 
                    {InitLine T Count+1}
                else
                    {InitLine T Count}
                end
            end
        end

        fun{InitCount TheMap Count}
            case TheMap of nil then Count
            [] H|T then
                CountLine
            in
                CountLine = {InitLine H 0}
                {InitCount T Count + CountLine}
            end
        end

        proc{Loop Stream Count}
            case Stream of Message|T then
                case Message of getEndGame(Result) then
                    if Count == 0 then Result = true % End of game
                    else
                        Result = false
                    end
                [] boxExploded(Pos ValueToPut ?Result) then
                    TheMap
                    Value
                in
                    {Send MapPort get(TheMap)}
                    Value = {Nth {Nth TheMap Pos.y} Pos.x}
                    if Value == 2 orelse Value == 3 then
                        {Send MapPort modif(Pos#ValueToPut)} % Change the value
                        if Count-1 == 0 then % End of game
                            Result = true
                            {Loop T Count-1}
                        else
                            Result = false
                            {Loop T Count-1}
                        end
                    else
                        % Border case error
                        {Loop T Count}
                        Result = false
                    end
                end
            else
                % Error here
                {Loop Stream Count}
            end
        end
        TotalCount
        TheMap
    in
        {Send MapPort get(TheMap)}
        TotalCount = {InitCount TheMap 0}
        {Loop Stream TotalCount}
    end

    /*
     Agent that handles the points of the players
     Can tell which player is the winner
     Only give one winner
     */
    proc{PointHandler Stream}
        fun{ChangePoints ThePoints ID Points}
            fun{Loop L Count}
                case L of nil then 
                    nil
                [] (HisPoints#HisID)|T then
                    if Count == ID.id then % the player
                        NewVal
                    in
                        NewVal = HisPoints + Points
                        (NewVal#HisID)|T
                    else
                        (HisPoints#HisID)|{Loop T Count-1}
                    end
                end
            end
        in
            {Loop ThePoints Input.nbBombers}
        end

        fun{CheckWinner L}
            fun{Loop L Acc}
                case L of nil then Acc.2 % Only gives the ID of the winner
                [] (Points#ID)|T then
                    if Points > Acc.1 then % Current player has more points
                        {Loop T Points#ID}
                    else
                        {Loop T Acc}
                    end
                end
            end
        in
            {Loop L (~1)#0}
        end

        proc{Loop Stream ThePoints}
            case Stream of Message|T then
                case Message of add(ID Point) then
                    NewPoints
                in
                    NewPoints = {ChangePoints ThePoints ID Point}
                    {Loop T NewPoints}
                [] endGame(Result) then
                    % It is the end of the game, chose the winner
                    Result = {CheckWinner ThePoints} % Result has the ID of the winner
                end
            end
        end

        fun{InitPoints IDs}
            case IDs of nil then nil
            [] H|T then
                (0#H)|{InitPoints T}
            end
        end
        PointsInit
    in
        PointsInit = {InitPoints IDs}
        {Loop Stream PointsInit}
    end



end