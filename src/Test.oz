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

    SpawnPositions = {LookForSpawn}

    % Function to look for the spawn positions
    fun{LookForSpawn}
        fun{LoopLine Line}
            case Line of nil then nil
            [] H|T then
                if H == 4 then % Spawn
                    H|{LoopLine T}
                else
                   {LoopLine T}
                end
            end
        end 
        fun{Loop TheMap Acc}
            case TheMap of nil then Acc
            [] Line|Rest then % Treat one line at a time
                CurrentTreat
                Acc2
            in
                CurrentTreat = {LoopLine Line}
                Acc2 = {Append Acc CurrentTreat}
                {Loop Rest Acc2}
            end
        end
    in
        {Loop Input.map nil}
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