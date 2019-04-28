functor
import
    Input
    PlayerManager
    Browser
define
    SpawnPositions
    PlayersPosition
    InitPlayers
    LookForSpawn
    PlayersPort
    PlayersPosition

    GlobalTest
in

    thread SpawnPositions = {LookForSpawn Input.map}

    {InitPlayers 2 Input.colorsBombers Input.bombers SpawnPositions PlayersPosition PlayersPort}
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

        fun{TestGiveExtensions}
            ResultShieldBefore
            ResultAddLife
            ResultID
            ResultDeath
            ResultShieldAfterDie
            ResultShieldEnd
            
            BoolShieldBefore
            BoolAddLife
            BoolGotHitWithShield
            BoolShieldAfterDie
            BoolShieldEnd
        in
            % Send an additionnal life and a shield
            {Send PlayersPort.1 add(life 1 ResultAddLife)}
            {Send PlayersPort.1 add(shield 1 ResultShieldBefore)}

            % Test if the returned values are correct
            if ResultAddLife == (Input.nbLives - 2 + 1) then % Correct
                BoolAddLife = true
            else
                BoolAddLife = false
            end

            if ResultShieldBefore == 1 then % Correct
                BoolShieldBefore = true
            else
                BoolShieldBefore = false
            end

            % Tell the player he got hit
            % ID and Result should be null because of the shield
            {Send PlayersPort.1 gotHit(ResultID ResultDeath)}
            if ResultID == null andthen ResultDeath == null then % Correct
                BoolGotHitWithShield = true
            else
                BoolGotHitWithShield = false
            end

            % Give back 2 shield to be sure that the player has now 2 shield
            {Send PlayersPort.1 add(shield 2 ResultShieldAfterDie)}
            if ResultShieldAfterDie == 2 then % Correct
                BoolShieldAfterDie = true
            else
                BoolShieldAfterDie = false
            end

            % Take the shields
            {Send PlayersPort.1 add(shield ~2 ResultShieldEnd)}
            if ResultShieldEnd == 0 then
                BoolShieldEnd = true
            else
                BoolShieldEnd = false
            end

            BoolShieldBefore andthen BoolAddLife andthen BoolGotHitWithShield andthen BoolShieldAfterDie andthen BoolShieldEnd
        end

        /* 

        fun{TestDoubleBomb}
            ThePort

            ResultGiveBomb
            ActionBomb
            ActionBomb2

            BoolBombGiven
            BoolAmorceBomb
            BoolNoMoreBomb
        in
            ThePort = PlayersPort.2.1

            % We give the player two bombs
            {Send ThePort add(bomb 2 ResultGiveBomb)}
            if ResultGiveBomb == 2 then % Correct
                BoolBombGiven = true
            else
                BoolBombGiven = false
            end

            % We first ask the player to make a move
            % Since the player has no were to go, he should drop a bomb near the box
            {Send ThePort doaction(_ ActionBomb)}
            {Browser.browse passage1}
            {Delay 4000}
            {Browser.browse ActionBomb}
            case ActionBomb of bomb(Position) then
                if Position.x == PlayersPosition.2.1.x andthen Position.y == PlayersPosition.2.1.y then
                    BoolAmorceBomb = true
                else
                    BoolAmorceBomb = false
                end
            else
                BoolAmorceBomb = false
            end

            % Now the player still can't move so he should drop a bomb
            % But there is already a bomb next to him, so he shouldn't drop another bomb
            % We ask the player to do an action and wait for 
            % 5 seconds. If ActionBomb2 is bounded, it means that the player made a move
            % which is impossible; or he droped a bomb, which is forbidden.
            % So if the player can't stay at his place, the correct situation is to have
            % the player not beeing able to find a solution, and having ActionBomb2 unbounded
            {Send ThePort doaction(_ ActionBomb2)}
            {Delay 500}
            {Browser.browse jesuisla}
            if {IsDet ActionBomb2} then 
                BoolNoMoreBomb = false
            else
                BoolNoMoreBomb = true
            end

            BoolBombGiven andthen BoolAmorceBomb andthen BoolNoMoreBomb
        end
        */

        SpawnBackBool
        OneMoveBool
        DieAndRespawnBool
        DieBorderCaseBool
        GivePointsAndBombsBool

        ExtensionsAddBool

        DoubleBombBool
    in
        % Just to be sure that the player has no bomb
        {Send PlayersPort.1 add(bomb ~Input.nbBombs _)}

        SpawnBackBool = {TestSpawnBack}
        OneMoveBool = {TestOneMove}
        DieAndRespawnBool = {TestDieAndRespawn}
        DieBorderCaseBool = {TestDieBorderCase}
        GivePointsAndBombsBool = {TestGivePointsAndBombs}

        %DoubleBombBool = {TestDoubleBomb}
        
        if Input.useExtention then % Use extensions, test the extensions
            ExtensionsAddBool = {TestGiveExtensions}
        else
            ExtensionsAddBool = none
        end

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

        if ExtensionsAddBool \= none then % Use the extensions
            if ExtensionsAddBool then
                {Browser.browse 'PASSED: The player acts correctly regarding the extention addings'}
            else
                {Browser.browse 'The player does not act correctly regarding the extention addings'}
            end
        end
        /*
        if DoubleBombBool then
            {Browser.browse 'PASSED: The player does not drop more than one not exploded bomb at the same place'}
        else
            {Browser.browse 'The player drops more than one not exploded bomb at the same place'}
        end
        */
    
    end



end