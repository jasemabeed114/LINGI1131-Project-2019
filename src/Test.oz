functor
import
    GUI
    Input
    PlayerManager
    Browser
    OS
define
    SpawnPositions
    PlayersPosition
    InitPlayers
    InitPlayersSpawnInformation
    LookForSpawn
    PlayersPort
    PlayersPosition

    GlobalTest
in

    thread SpawnPositions = {LookForSpawn Input.map}

    {InitPlayers 1 Input.colorsBombers Input.bombers SpawnPositions PlayersPosition PlayersPort}

    {InitPlayersSpawnInformation PlayersPort PlayersPosition _}
    {GlobalTest}
    end
    

    % Function to look for the spawn positions
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
                PlayersPosition = Position|PlayersPositionTail
                PlayersPort     = PlayerPort|PlayersPortTail
                {InitPlayers NbPlayers-1 ColorT NameT PositionT PlayersPositionTail PlayersPortTail}
            end
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
            ID|{InitPlayersSpawnInformation PortT PositionT}
        end
    end

    /*
     First test: checking if the player is at the good spawn position
     by checking the first movement he makes. It should be at a distance
     1 from cardinal positions from the initial spawn position we gave him

     TO EXECUTE THIS TEST, IT IS REQUIRED TO PUT THE NUMBER OF INITIAL BOMS
     TO 0 
     */
    proc{GlobalTest}
        fun{TestSpawnBack}
            BoolSpawnBack
            ID Spawn
        in
            {Send PlayersPort.1 spawn(ID Spawn)}
            if ID == null andthen Spawn == null then
                BoolSpawnBack = true
            else
                BoolSpawnBack = false
            end
        end

        fun{TestOneMove}
            Action
            InitialPositionPlayerOne
        in
            {Send PlayersPort.1 doaction(_ Action)}
            % As the player has no bomb, it has to make a displacement
            case Action of move(pt(x:X y:Y)) then % The move
                DeltaX DeltaY Delta
            in
                InitialPositionPlayerOne = SpawnPositions.1
                DeltaX = X - InitialPositionPlayerOne.x
                DeltaY = Y- InitialPositionPlayerOne.y
                Delta = DeltaX*DeltaX + DeltaY*DeltaY
                if Delta == 1 then true % The player has moved from one position
                else false % Error
                end 
            else % It is an error
                {Browser.browse 'Be sure that the initial number of bombs is null'}
            end
        end

        fun{TestDieAndRespawn}
            Result
            BoolLife

            StateBefore
            BoolStateBefore
            StateAfter
            BoolStateAfter
            BoolPosition
            SpawnPositionBack
        in
            {Send PlayersPort.1 gotHit(_ Result)}
            if Result.1 == Input.nbLives - 1 then
                BoolLife = true % The player has correctly decremented his lives by one
            else
                BoolLife = false
            end

            {Send PlayersPort.1 getState(_ StateBefore)}
            if StateBefore == off then % Correct
                BoolStateBefore = true
            else
                BoolStateBefore = false
            end

            {Send PlayersPort.1 spawn(_ SpawnPositionBack)}
            if SpawnPositionBack.x == SpawnPositions.1.x andthen SpawnPositionBack.y == SpawnPositions.1.y then
                BoolPosition = true
            else
                BoolPosition = false
            end

            % Now check that the state is on
            {Send PlayersPort.1 getState(_ StateAfter)}
            if StateAfter == on then % Correct
                BoolStateAfter = true
            else
                BoolStateAfter = false
            end

            BoolLife andthen BoolPosition andthen BoolStateBefore andthen BoolStateAfter
        end

        /*
            This function tests if the player sends the correct informations when
            He is already dead and we tell him that he is dead again
            ID and Result should be bounded to null in this case
         */
        fun{TestDieBorderCase}
            ID Result
            StateBefore BoolStateBefore
            BoolHitBack
            StateAfter BoolStateAfter
        in
            {Send PlayersPort.1 gotHit(_ _)} % Tell the player he is dead
            % Should be off now : already verified before but we still do it now
            {Send PlayersPort.1 getState(_ StateBefore)}
            if StateBefore == off then % Correct
                BoolStateBefore = true
            else
                BoolStateBefore = false
            end

            % We send again the death message
            {Send PlayersPort.1 gotHit(ID Result)}
            if ID == null andthen Result == null then % Correct
                BoolHitBack = true
            else
                BoolHitBack = false
            end

            {Send PlayersPort.1 spawn(_ _)}
            {Send PlayersPort.1 getState(_ StateAfter)}
            if StateAfter == on then % Correct
                BoolStateAfter = true
            else
                BoolStateAfter = false
            end

            BoolStateBefore andthen BoolStateAfter andthen BoolHitBack
        end

        fun{TestGivePointsAndBombs}
            ResultBomb1
            ResultPoint5

            ResultBomb3
            ResultPoint7

            BoolBomb
            BoolPoint
        in
            % Initially, the player has 0 bomb and has no points
            {Send PlayersPort.1 add(bomb 1 ResultBomb1)}
            {Send PlayersPort.1 add(point 5 ResultPoint5)}

            {Send PlayersPort.1 add(bomb 2 ResultBomb3)}
            {Send PlayersPort.1 add(point 2 ResultPoint7)}

            if ResultBomb1 == 1 andthen ResultBomb3 == 3 then % Correct
                BoolBomb = true
            else
                BoolBomb = false
            end

            if ResultPoint5 == 5 andthen ResultPoint7 == 7 then % Correct
                BoolPoint = true
            else
                BoolPoint = false
            end

            BoolBomb andthen BoolPoint
        end

        SpawnBackBool
        OneMoveBool
        DieAndRespawnBool
        DieBorderCaseBool
        GivePointsAndBombsBool
    in
        SpawnBackBool = {TestSpawnBack}
        OneMoveBool = {TestOneMove}
        DieAndRespawnBool = {TestDieAndRespawn}
        DieBorderCaseBool = {TestDieBorderCase}
        GivePointsAndBombsBool = {TestGivePointsAndBombs}

        if SpawnBackBool then
            {Browser.browse 'PASSED: The player respect the case when it is on the board and we ask him to spawn again'}
        else
            {Browser.browse 'The player does not respect the case when it is on the board and we ask him to spawn again'}
        end

        if OneMoveBool == false then
            % Wrong test
            {Browser.browse 'The player does not respect the initial spawn of the condition to move'}
        else
            % Good
            {Browser.browse 'PASSED: The player respect the condition of moving from one position'}
        end

        if DieAndRespawnBool then
            {Browser.browse 'PASSED: The player correctly dies and respawn'}
        else
            {Browser.browse 'The player does not correctly die and respawn'}
        end

        if DieBorderCaseBool then
            {Browser.browse 'PASSED: The player correctly reacts when he is dead and we ask him to die again'}
        else
            {Browser.browse 'The player does not correctly react when he is dead and we ask him to die again'}
        end

        if GivePointsAndBombsBool then
            {Browser.browse 'PASSED: The player reacts correctly when we give him points and bombs'}
        else
            {Browser.browse 'The player does not react correctly when we give him points and bombs'}
        end





    
    end















end