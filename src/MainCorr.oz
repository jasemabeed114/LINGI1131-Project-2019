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
   
   
   Map
   NbPlayers
   Positions
   PlayersPosition % Port of all the players
   PlayersPort  % Initial position of all the players
in

   Map = Input.map

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
      skip %simultane
   end
    proc{InitPlayersSpawnInformation PlayerPort PlayersPosition}
        case PlayerPort#PlayersPosition
        of nil#nil then skip
        [](PortH|PortT)#(PositionH|PositionT) then 
            ID 
        in
            {Send PortH getId(ID)}
            {Wait ID}
            thread {InformationPlayers PlayerPort info(spawnPlayer(ID PositionH))} end
            {InitPlayersSpawnInformation PortT PositionT}
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

    proc{TurnByTurn Map PlayersPortTail PlayersPositionCurrent PlayersPositionNext PlayersPositionNextEnd Bombs Fires}
        case PlayersPortTail#PlayersPositionCurrent of nil#_ then
            FutureNext % For the recursion
            NewBombs
            NewFiresPort
            MapAfterExplosions
            NewFires
            ResultEndGame
            WinnerEndGame
        in
            PlayersPositionNextEnd = nil % End of the list NextEnd
            % The PlayersPositionNext is now complete with all the new positions
            
            % Disable the fires of the previous turn which is finished
            {DisableFirePreviousTurn Fires}
            % Create the new port to listen to the Fire
            NewFiresPort = {NewPort NewFires}
            %% Process here the explosion and the rest
            {ProcessBombs Bombs NewBombs PlayersPositionNext NewFiresPort Map ?MapAfterExplosions}
            %% Check if the game is over after the new explosions
            {CheckEndGame ResultEndGame WinnerEndGame}
            if ResultEndGame == true then % End of game
                {DisableFirePreviousTurn NewFires}
                if WinnerEndGame == none then % No one won
                    {Browser.browse 'No one won'}
                else
                    {Send WindowPort displayWinner(WinnerEndGame)} % Give the ID of the Winner
                end
            else
                %% Recursion back to the beginning
                {Delay 500}
                {TurnByTurn MapAfterExplosions PlayersPort PlayersPositionNext FutureNext FutureNext NewBombs NewFires}
            end
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
                    CheckPosition
                in
                    {Send WindowPort movePlayer(ID Pos)} % Move the player on the screen
                    {InformationPlayers PlayersPortTail info(movePlayer(ID Pos))}
                    CheckPosition = {CheckMove Pos.x Pos.y Map}
                    if(CheckPosition == pointfloor) then % The player is on a point floor, he gets the point
                        Result MapWithoutPoint
                    in
                        {Send PortH add(point 1 Result)} % Gives the point and ask the result
                        {Send WindowPort hidePoint(Pos)} % Hides the point from the screen
                        {Wait Result}
                        {Send WindowPort scoreUpdate(IDAction Result)} % Update the score of the player ID
                        MapWithoutPoint = {SetMapVal Map Pos.x Pos.y 0}

                        if Result >= 50 then % The player has 50 points or more, he wins
                            {Send WindowPort displayWinner(ID)} % Display the winner
                        else % The player doesn't win, we continue the recursion
                            %% Recursion
                            PlayersPositionNextEnd = Pos|NextEnd2
                            {TurnByTurn MapWithoutPoint PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                        end
                    elseif (CheckPosition == bonusfloot) then 
                        Rand 
                    in
                        Rand = ({OS.rand} + 1) mod 2
                        if Rand == 0 then % We give 10 points to the player
                            Result MapWithoutBonus
                        in
                            {Send PortH add(point 10 Result)}
                            {Wait Result}
                            {Send WindowPort hideBonus(Pos)}
                            {Send WindowPort scoreUpdate(IDAction Result)}
                            MapWithoutBonus = {SetMapVal Map Pos.x Pos.y 0}

                            if Result >= 50 then % The player has 50 points or more, he wins
                                {Send WindowPort displayWinner(ID)}
                            else % The player doesn't win, we continue the recursion
                                %% Recursion
                                PlayersPositionNextEnd = Pos|NextEnd2
                                {TurnByTurn MapWithoutBonus PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                            end
                        else % We give an additionnal bomb
                            Result MapWithoutBonus
                        in
                            {Send PortH add(bomb 1 Result)}
                            {Send WindowPort hideBonus(Pos)}
                            MapWithoutBonus = {SetMapVal Map Pos.x Pos.y 0}
                            %% Recursion
                            PlayersPositionNextEnd = Pos|NextEnd2
                            {TurnByTurn MapWithoutBonus PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                        end
                    else
                        %% Recursion
                        PlayersPositionNextEnd = Pos|NextEnd2
                        {TurnByTurn Map PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                    end
                [] bomb(Pos) then
                    NextEnd2
                in 
                    {Send WindowPort spawnBomb(Pos)} % Show the bomb on the window
                    {InformationPlayers PlayersPortTail info(bombPlanted(Pos))}
                    %% Recursion
                    PlayersPositionNextEnd = PositionH|NextEnd2
                    {TurnByTurn Map PortT PositionT PlayersPositionNext NextEnd2 (Input.timingBomb#Pos#PortH)|Bombs Fires}
                
                else
                    NextEnd2
                in
                    %% Recursion
                    PlayersPositionNextEnd = PositionH|NextEnd2
                    {TurnByTurn Map PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                end
            else
                NextEnd2
            in  
                %% Recursion
                PlayersPositionNextEnd = PositionH|NextEnd2
                {TurnByTurn Map PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
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

    proc{ProcessBombs Bombs NewBombs PlayersPos NewFiresPort MapAcc ?MapReturn}
        case Bombs of nil then 
            NewBombs = nil
            {Send NewFiresPort nil}
            MapReturn = MapAcc
        [] (N#Pos#PortPlayer)|T then
            if N == 0 then % Explosion of the bomb
                Result MapAcc2
            in
                {Send WindowPort hideBomb(Pos)} % GUI information
                {Send PortPlayer add(bomb 1 Result)} % Giving back the bomb
                {InformationPlayers PlayersPort info(bombExploded(Pos))} % Warn the other players of the bomb exploded
                {PropagationFire Pos MapAcc NewFiresPort PlayersPos MapAcc2} % Propagation of the fire
                {ProcessBombs T NewBombs PlayersPos NewFiresPort MapAcc2 ?MapReturn} % Recursion
            else
                NewBombsTails
            in
                NewBombs = ((N-1)#Pos#PortPlayer)|NewBombsTails % Substract 1 to the delay
                {ProcessBombs T NewBombsTails PlayersPos NewFiresPort MapAcc ?MapReturn} % Recursion
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

    proc{PropagationFire Pos Map NewFiresPort PlayPosition MapReturn}

        proc{ProcessDeath FirePosition Ports PlayerPos}
            case Ports#PlayerPos of nil#_ then skip % Process for each player
            [] (PortH|PortT)#(PosH|PosT) then
                if FirePosition.x == PosH.x andthen FirePosition.y == PosH.y then % The fire is at the location of the player
                    ID Result
                in
                    {Send PortH gotHit(ID Result)}
                    {Wait Result}
                    % Potentially send an information
                    case Result of death(NewLife) then % Was on the board
                        %{Delay 4000}
                        %{Browser.browse iciCACACCDC#NewLife}
                        %{Delay 3000}
                        if NewLife == 0 then % Dead player
                            {InformationPlayers PlayersPort info(deadPlayer(ID))}
                            {Send WindowPort hidePlayer(ID)}
                            {Send WindowPort lifeUpdate(ID NewLife)}
                            {ProcessDeath FirePosition PortT PosT}
                        else % Still has lifes
                            ID2 SpawnPosition
                        in
                            {Send PortH spawn(ID2 SpawnPosition)}
                            {Wait ID2}
                            {Send WindowPort movePlayer(ID2 SpawnPosition)}
                            {Send WindowPort spawnFire(FirePosition)}
                            {Send WindowPort lifeUpdate(ID2 NewLife)}
                            {InformationPlayers PlayersPort info(spawnPlayer(ID2 SpawnPosition))}

                            %% Recursion
                            {ProcessDeath FirePosition PortT PosT}
                        end
                    else % null meaning that the player is off the board
                        {ProcessDeath FirePosition PortT PosT}
                    end
                else % Continue
                    {ProcessDeath FirePosition PortT PosT}
                end
            end
        end

        proc{PropagationOneDirection CurrentPosition PreviousPosition Count Changing}
            %{Delay 1000}
            if Count >= Input.fire then Changing = null
            else
                case CurrentPosition of pt(x:X y:Y) then
                    Check
                in
                    Check = {CheckMove X Y Map}
                    if Check == wall then
                        % It is a wall
                        % Stop propaging and bounds Changing to null because nothing changes
                        Changing = null
                    elseif Check == point then
                        % It is a point box
                        % Destroy the box and stop propaging
                        {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} % Warn other players
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnPoint(CurrentPosition)} % And shows the point
                        Changing = CurrentPosition#5
                    elseif Check == bonus then
                        % It is a bonus box
                        % Destroy the box and stop propaging
                        {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} % Warn other players
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnBonus(CurrentPosition)} % And shows the bonus
                        Changing = CurrentPosition#6
                    else
                        % Either a floor tile, a point or a bonus
                        % For the time being, we let them in place
                        % Continue propaging, and sends the position of the fire
                        {Send NewFiresPort CurrentPosition} % Sends the position of the fire
                        {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                        {ProcessDeath CurrentPosition PlayersPort PlayPosition}
                        case PreviousPosition of pt(x:XP y:YP) then
                            XF YF 
                        in
                            XF = X + (X-XP) % New position X
                            YF = Y + (Y-YP) % New position Y
                            Changing = {PropagationOneDirection pt(x:XF y:YF) CurrentPosition Count+1}
                        end
                    end
                end
            end
        end
        MapChanges Top Bottom Left Right
    in
        {Send WindowPort spawnFire(Pos)}
        {Send NewFiresPort Pos}
        case Pos of pt(x:X y:Y) then
            C1
        in
            thread % Also for the place where the bomb was
                {Send WindowPort spawnFire(Pos)}
                {Send NewFiresPort Pos}
                {ProcessDeath Pos PlayersPort PlayPosition}
                C1 = 1
            end
            thread {PropagationOneDirection pt(x:X+1 y:Y) Pos 0 Right} end % Right
            thread {PropagationOneDirection pt(x:X-1 y:Y) Pos 0 Left} end % Left
            thread {PropagationOneDirection pt(x:X y:Y+1) Pos 0 Bottom} end % Bottom
            thread {PropagationOneDirection pt(x:X y:Y-1) Pos 0 Top} end % Top
            
            {Wait Top} {Wait Bottom} {Wait Left} {Wait Right} % Wait for the instruction bellow
            {Wait C1}
            MapChanges = changes(Top Left Right Bottom)
            % The case where the fire exploded must have been a floor tile

            %MapReturn = {MapChangeAdvanced Map MapChanges 1 1}
            MapReturn = {MapChange Map MapChanges}
            
            % Enregistrement 1:Haut 2:Bas 3:Gauche 4:Droite
            % chaque entree est position#value
            % change toute la map en iterant sur ces valeurs
            % Retourne la nouvelle map avec la propagation du feu
            % Retourne aussi la liste des positions des feu
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
            elseif Point == 6 then bonusfloot
            end
        end
    in
        if (X >= 1 andthen X < Input.nbColumn+1 andthen Y >= 1 andthen Y < Input.nbRow+1) == true then
            {CheckMap X Y}
        else
            false
        end
    end

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

    fun{MapChange Map Changes}
        MapTop
        MapBottom
        MapLeft
        MapRight
    in
        case Changes of changes(Top Bottom Left Right) then
            case Top of null then MapTop = Map
            [] (pt(x:X y:Y)#Value) then
                MapTop = {SetMapVal Map X Y Value}
            end
            case Bottom of null then MapBottom = MapTop
            [] (pt(x:X y:Y)#Value) then
                MapBottom = {SetMapVal MapTop X Y Value}
            end
            case Left of null then MapLeft = MapBottom
            [] (pt(x:X y:Y)#Value) then
                MapLeft = {SetMapVal MapBottom X Y Value}
            end
            case Right of null then MapRight = MapLeft
            [] (pt(x:X y:Y)#Value) then
                MapRight = {SetMapVal MapLeft X Y Value}
            end
            MapRight % To return
        else
            Map
        end
    end

    fun{MapChangeAdvanced Map Changes Y Count}
        fun{LignProcess Lign Count ?FinalCount}
            case Lign of nil then FinalCount = Count nil
            [] X|T then
                if Y == ((Changes.Count).1).y andthen ((Changes.Count).1).x == X then % The change is here
                    (Changes.Count).2|{LignProcess T Count+1 FinalCount}
                else
                    {LignProcess T Count ?FinalCount}
                end
            end
        end
    in
        case Map of H|T then % Process a lign
            NewCount
        in
            {LignProcess H Count NewCount}|{MapChangeAdvanced T Changes Y+1 NewCount}
        [] nil then nil
        end
    end
            


    % Check if the game is over
    % Result bound to true if the game is over
    %   Winner is bound to the winner
    %   none if all dead
    % Else Result == null and we don't care about Winner
    proc{CheckEndGame ?Result ?Winner} % For the points, it is directly done when we give a point to a player
        fun{Loop Ports Count ?PlayersStillAlive}
            case Ports of nil then PlayersStillAlive = nil Count
            [] H|T then
                ID State
            in
                {Send H getState(ID State)}
                if State == on then% On the board
                    NextEnd
                in
                    PlayersStillAlive = ID|NextEnd
                    {Loop T Count+1 NextEnd}
                else % Off the board
                    {Loop T Count PlayersStillAlive}
                end
            end
        end
        PlayersAlive Count
    in
        Count = {Loop PlayersPort 0 PlayersAlive}
        if Count == 0 then 
            Result = true 
            Winner = none 
        elseif Count == 1 then 
            Result = true 
            Winner = PlayersAlive.1 
        else 
            Result = false 
            Winner = none 
        end 
    end 
end