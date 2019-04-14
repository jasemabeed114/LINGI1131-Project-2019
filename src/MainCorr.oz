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
   MapChange
   CheckMove
   InformationPlayers
   PropagationFire
   
   
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
   {Delay 10000}

   NbPlayers = Input.nbBombers

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players
   {Browser.browse PlayersPort}
   {Browser.browse PlayersPosition}
   thread {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions PlayersPosition PlayersPort} end
   if Input.isTurnByTurn then
        Next
    in
      thread {TurnByTurn Map PlayersPort PlayersPosition Next Next nil nil} end
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

    proc{TurnByTurn Map PlayersPortTail PlayersPositionCurrent PlayersPositionNext PlayersPositionNextEnd Bombs Fires}
        case PlayersPortTail#PlayersPositionCurrent of nil#_ then
            FutureNext % For the recursion
            NewBombs
            NewFiresPort
            MapAfterExplosions
            NewFires
        in
            PlayersPositionNextEnd = nil % End of the list NextEnd
            % The PlayersPositionNext is now complete with all the new positions
            
            % Disable the fires of the previous turn which is finished
            thread {DisableFirePreviousTurn Fires} end
            % Create the new port to listen to the Fire
            NewFiresPort = {NewPort NewFires}
            %% Process here the explosion and the rest
            {ProcessBombs Bombs NewBombs PlayersPositionNext NewFiresPort Map ?MapAfterExplosions}

            %% Recursion back to the beginning
            {Delay 200}
            {TurnByTurn MapAfterExplosions PlayersPort PlayersPositionNext FutureNext FutureNext NewBombs NewFires}
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
                    {TurnByTurn Map PortT PositionT PlayersPositionNext NextEnd2 Bombs Fires}
                
                [] bomb(Pos) then
                    NextEnd2
                in 
                    {Send WindowPort spawnBomb(Pos)} % Show the bomb on the window

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

    proc{ProcessBombs Bombs NewBombs PlayersPosition NewFiresPort MapAcc ?MapReturn}
        case Bombs of nil then 
            NewBombs = nil
            MapReturn = MapAcc
        [] (N#Pos#PortPlayer)|T then
            if N == 0 then % Explosion of the bomb
                Result MapAcc2
            in
                {Send WindowPort hideBomb(Pos)} % GUI information
                {Send PortPlayer add(bomb 1 Result)} % Giving back the bomb
                {InformationPlayers PlayersPort info(bombExploded(Pos))} % Warn the other players of the bomb exploded
                {PropagationFire Pos MapAcc NewFiresPort MapAcc2} % Propagation of the fire
                {ProcessBombs T NewBombs PlayersPosition NewFiresPort MapAcc2 ?MapReturn} % Recursion
            else
                NewBombsTails
            in
                NewBombs = ((N-1)#Pos#PortPlayer)|NewBombsTails % Substract 1 to the delay
                {ProcessBombs T NewBombsTails PlayersPosition NewFiresPort MapAcc ?MapReturn} % Recursion
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

    proc{PropagationFire Pos Map NewFiresPort MapReturn}
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
        case Pos of pt(x:X y:Y) then
            thread {PropagationOneDirection pt(x:X+1 y:Y) Pos 0 Right} end % Right
            thread {PropagationOneDirection pt(x:X-1 y:Y) Pos 0 Left} end % Left
            thread {PropagationOneDirection pt(x:X y:Y+1) Pos 0 Bottom} end % Bottom
            thread {PropagationOneDirection pt(x:X y:Y-1) Pos 0 Top} end % Top
            
            {Wait Top} {Wait Bottom} {Wait Left} {Wait Right} % Wait for the instruction bellow
            MapChanges = changes(Top Bottom Left Right)
            {Send NewFiresPort nil} % To indicate that it is done
            % The case where the fire exploded must have been a floor tile

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

    fun{MapChange Map Changes}
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
            




end