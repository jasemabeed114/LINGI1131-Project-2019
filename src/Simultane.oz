proc{SimultaneousInitLoop PlayersPort}
        case PlayersPort of H|T then
            thread {Simultaneous H} end
            {SimultaneousInitLoop T}
        [] nil then skip
        end
    end

    proc{Simultaneous H}
        State ID
        Action
        TimeWait
    in
        TimeWait = ({OS.rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin
        {Delay 300} % Delay to see what happens
        {Send H getState(ID State)}
        {Wait ID}
        if State == on then % Should not be necessary but we use it 
            {Send H doaction(_ Action)}
            case Action of bomb(Pos) then
                {Send WindowPort spawnBomb(Pos)}
                {InformationPlayers PlayersPort info(bombPlanted(Pos))}
                thread
                    TimingBomb
                in
                    TimingBomb = ({OS.rand} mod (Input.timingBombMax - Input.timingBombMin)) + Input.timingBombMin
                    {Delay TimingBomb} % Simulate the bomb waiting
                    % Now the bomb has to explode but it will be done in the EventHandler
                    {Send EventPort ID#H#bombExplode(Pos)}
                end
                % dans thread
                % afficher la bombe
                % envoyer information
                % delais
                % envoyer a l'evenementiel que la bombe doit exploser
                % recursion
            [] move(Pos) then
                {Send WindowPort movePlayer(ID Pos)} % Move the player on the window
                thread {InformationPlayers PlayersPort info(movePlayer(ID Pos))} end % inform other players
                {Send EventPort ID#H#move(Pos)} % Send to the EventHandler the move
                % bouge a l'ecran
                % envoie information joueurs
                % envoie a l'evenementiel le deplacement
            else
                skip
            end
            {Simultaneous H}
        else
            skip
        end
    end

    proc{EventHandler TheStream TheMap ThePositions TheBombs}
        case TheStream of Event|T then
            case Event of ID#H#move(Pos) then % The player has changed his position
                NewPositions
                CheckPosition
            in
                NewPositions = {ChangePositions ThePositions ID Pos} % Update of the position
                CheckPosition = {CheckMove Pos.x Pos.y TheMap}
                if CheckPosition == pointfloor then % The player is on a point tile
                    Result MapWithoutPoint
                in
                    {Send H add(point 1 Result)} % Gives the point and ask the result
                    {Send WindowPort hidePoint(Pos)} % Hides the point from the screen
                    {Wait Result}
                    {Send WindowPort scoreUpdate(ID Result)} % Update the score of the player ID
                    thread MapWithoutPoint = {SetMapVal TheMap Pos.x Pos.y 0} end

                    if Result >= 50 then % The player has 50 points or more, he wins
                        {Send WindowPort displayWinner(ID)} % Display the winner
                    else % The player doesn't win, we continue
                        %% Recursion
                        {EventHandler T MapWithoutPoint NewPositions TheBombs}
                    end
                elseif CheckPosition == bonusfloot then % Bonus, random + give + check end
                    Rand
                in
                    Rand = ({OS.rand} + 1) mod 2
                    if Rand == 0 then % We give 10 points to the player
                        Result MapWithoutBonus
                    in
                        {Send H add(point 10 Result)}
                        {Send WindowPort hideBonus(Pos)}
                        {Wait Result}
                        {Send WindowPort scoreUpdate(ID Result)}
                        thread MapWithoutBonus = {SetMapVal Map Pos.x Pos.y 0} end
                        if Result >= 50 then % The player has 50 points or more, he wins
                            {Send WindowPort displayWinner(ID)}
                        else % The player doesn't win, we continue the recursion
                            %% Recursion
                            {EventHandler T MapWithoutBonus NewPositions TheBombs}
                        end
                    else % We give an additionnal bomb
                        Result MapWithoutBonus
                    in
                        {Send H add(bomb 1 Result)}
                        {Send WindowPort hideBonus(Pos)}
                        thread MapWithoutBonus = {SetMapVal Map Pos.x Pos.y 0} end
                        %% Recursion
                        {EventHandler T MapWithoutBonus NewPositions TheBombs}
                    end
                else
                    {EventHandler T TheMap NewPositions TheBombs}
                end
                % Change the position in ThePositions
                % Check for bonuses/points
                % Check Endgame
                % Recursive call
            [] ID#H#bombExplode(Pos) then % The bomb has to explode now
                MapAfterExplosions
                PositionsAfterExplosions
                ResultEndGame WinnerEndGame
            in
                {Send WindowPort hideBomb(Pos)}
                {Send H add(bomb 1 _)}
                {InformationPlayers PlayersPort info(bombExploded(Pos))} % Warn the other players of the bomb exploded
                thread 
                    {PropagationFireSimult Pos TheMap ThePositions PositionsAfterExplosions MapAfterExplosions}
                    {CheckEndGame ResultEndGame WinnerEndGame} 
                end
                if ResultEndGame == true then % End of game
                    if WinnerEndGame == none then % No one won
                        {Browser.browse 'No one won'}
                    else
                        {Send WindowPort displayWinner(WinnerEndGame)} % Give the ID of the Winner
                    end
                else
                    %% Recursion back to the beginning
                    %{Delay 500}
                    {EventHandler T MapAfterExplosions PositionsAfterExplosions TheBombs}
                end

                % Hide the bomb
                % Give back the bomb
                % Call PropagationFire
                % Check EndGame
            end
        end
    end

    TimeFireDisplay = 500

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

    proc{PropagationFireSimult Pos Map PlayPosition ?PositionsReturn ?MapReturn}

        fun{ProcessDeath FirePosition Ports PlayerPos NewPos}
            case Ports#PlayerPos of nil#_ then NewPos % Process for each player
            [] (PortH|PortT)#(PosH|PosT) then
                if FirePosition.x == PosH.x andthen FirePosition.y == PosH.y then % The fire is at the location of the player
                    ID Result
                in
                    {Send PortH gotHit(ID Result)}
                    {Wait Result}
                    % Potentially send an information
                    {Wait ID}
                    case Result of death(NewLife) then % Was on the board
                        %{Delay 4000}
                        %{Browser.browse iciCACACCDC#NewLife}
                        %{Delay 3000}
                        if NewLife == 0 then % Dead player
                            {InformationPlayers PlayersPort info(deadPlayer(ID))}
                            {Send WindowPort hidePlayer(ID)}
                            {Send WindowPort lifeUpdate(ID NewLife)}
                            {ProcessDeath FirePosition PortT PosT NewPos}
                        else % Still has lifes
                            SpawnPosition SState NewPosAfter
                        in
                            {Send PortH spawn(_ SpawnPosition)}
                            NewPosAfter = {ChangePositions NewPos ID SpawnPosition}
                            {Send EventPort ID#PortH#move(SpawnPosition)} % Warn the event handler of the move
                            {Send WindowPort movePlayer(ID SpawnPosition)}
                            {Send WindowPort spawnFire(FirePosition)}
                            {Send WindowPort lifeUpdate(ID NewLife)}
                            {Send PortH getState(_ SState)}
                            {Wait SState}
                            {InformationPlayers PlayersPort info(spawnPlayer(ID SpawnPosition))}

                            %% Recursion
                            {ProcessDeath FirePosition PortT PosT NewPosAfter}
                        end
                    else % null meaning that the player is off the board
                        {ProcessDeath FirePosition PortT PosT NewPos}
                    end
                else % Continue
                    {ProcessDeath FirePosition PortT PosT NewPos}
                end
            end
        end

        proc{PropagationOneDirection CurrentPosition PreviousPosition Count NewPosAcc ?NewPosRet ?Changing}
            %{Delay 1000}
            if Count >= Input.fire then Changing = null NewPosRet = NewPosAcc
            else
                case CurrentPosition of pt(x:X y:Y) then
                    Check
                in
                    Check = {CheckMove X Y Map}
                    if Check == wall then
                        % It is a wall
                        % Stop propaging and bounds Changing to null because nothing changes
                        Changing = null
                        NewPosRet = NewPosAcc
                    elseif Check == point then
                        % It is a point box
                        % Destroy the box and stop propaging
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} % Warn other players
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnPoint(CurrentPosition)} % And shows the point
                        Changing = CurrentPosition#5
                        NewPosRet = NewPosAcc
                    elseif Check == bonus then
                        % It is a bonus box
                        % Destroy the box and stop propaging
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        {InformationPlayers PlayersPort info(boxRemoved(CurrentPosition))} % Warn other players
                        {Send WindowPort hideBox(CurrentPosition)} % Hides the box
                        {Send WindowPort spawnBonus(CurrentPosition)} % And shows the bonus
                        Changing = CurrentPosition#6
                        NewPosRet = NewPosAcc
                    else
                        NewPosAfter
                    in
                        % Either a floor tile, a point or a bonus
                        % For the time being, we let them in place
                        % Continue propaging, and sends the position of the fire
                        thread 
                            {Send WindowPort spawnFire(CurrentPosition)} % Display the fire on the screen
                            {Delay TimeFireDisplay}
                            {Send WindowPort hideFire(CurrentPosition)} % Hide the fire after a time
                        end
                        NewPosAfter = {ProcessDeath CurrentPosition PlayersPort PlayPosition NewPosAcc}
                        case PreviousPosition of pt(x:XP y:YP) then
                            XF YF 
                        in
                            XF = X + (X-XP) % New position X
                            YF = Y + (Y-YP) % New position Y
                            Changing = {PropagationOneDirection pt(x:XF y:YF) CurrentPosition Count+1 NewPosAfter NewPosRet}
                        end
                    end
                end
            end
        end
        MapChanges Top Bottom Left Right
    in
        case Pos of pt(x:X y:Y) then
            C1
            PlayerRight
            PlayerLeft
            PlayerTop
            PlayerBottom
            PlayerCentral
        in
            thread % Also for the place where the bomb was
                thread 
                    {Send WindowPort spawnFire(Pos)}
                    {Delay TimeFireDisplay}
                    {Send WindowPort hideFire(Pos)}
                end
                PlayerCentral = {ProcessDeath Pos PlayersPort PlayPosition PlayPosition}
                C1 = 1
                {PropagationOneDirection pt(x:X+1 y:Y) Pos 0 PlayerCentral PlayerRight Right} % Right
                {PropagationOneDirection pt(x:X-1 y:Y) Pos 0 PlayerRight PlayerLeft Left} % Left
                {PropagationOneDirection pt(x:X y:Y+1) Pos 0 PlayerLeft PlayerBottom Bottom} % Bottom
                {PropagationOneDirection pt(x:X y:Y-1) Pos 0 PlayerBottom PlayerTop Top} % Top
            end
            MapChanges = changes(Top Left Right Bottom)
            % The case where the fire exploded must have been a floor tile

            %MapReturn = {MapChangeAdvanced Map MapChanges 1 1}
            MapReturn = {MapChange Map MapChanges}
            PositionsReturn = PlayerTop
            
            % Enregistrement 1:Haut 2:Bas 3:Gauche 4:Droite
            % chaque entree est position#value
            % change toute la map en iterant sur ces valeurs
            % Retourne la nouvelle map avec la propagation du feu
            % Retourne aussi la liste des positions des feu
        end
    end