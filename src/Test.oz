functor
import
    GUI
    Input
    PlayerManager
    Browser
    OS
define
    WindowPort
    SpawnPositions
    PlayersPosition
    PlayersPort
in
    WindowPort = {GUI.portWindow} % Create the window port
    {Send WindowPort buildWindow} % Init the window
    {Delay 10000}

    {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions PlayersPosition PlayersPort}

    thread SpawnPositions = {LookForSpawn Input.map} end

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
                {Send WindowPort initPlayer(ID)}
                {Send WindowPort spawnPlayer(ID PositionH)}
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
     TO 0 AND TO USE THE SPECIAL MAP FOR THE TESTS (SEE Input.oz)
     */
    fun{GlobalTest}
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

        fun{TestGoodRespawn}
            Result
            BoolLife
        in
            {Send PlayersPort.1 gotHit(_ Result)}
            if Result == Input.nbLives - 1 then
                BoolLife = true % The player has correctly decremented his lives by one
            else
                BoolLife = false
            end
            

        OneMoveBool
    in
        OneMoveBool = {TestOneMove}
        if OneMoveBool == false then
            % Wrong test
            {Browser.browse 'The player does not respect the initial spawn of the condition to move'}
        else
            % Good
            {Browser.browse 'The player respect the condition of moving from one position'}
        end



    
    end















end