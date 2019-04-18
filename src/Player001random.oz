functor
import
   Input
   Browser
   Projet2019util
   OS
export
   portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   SetMapVal
   SetMapValWithValue
   CreateMove
   CreateMoveAdvanced
   CheckMove
   CkeckBombe
   BombCaseVal
   IsNotBomb
   Name = 'Player001random'

   MySpawn
   MyID

in

    BombCaseVal = 10

    fun{StartPlayer ID}
        Stream Port OutputStream
    in
        MyID = ID % Assign the ID, will never change
        thread %% filter to test validity of message sent to the player
            OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
        end
        {NewPort Stream Port}
        thread
            {TreatStream OutputStream off MySpawn Input.nbLives 0 bonus(bomb:Input.nbBombs shield:0) Input.map nil}
        end
        Port
    end

    proc{TreatStream Stream MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
        case Stream
        of getId(ID)|T then % Ask for the player ID
            ID = MyID % Bind it
            %% Recursion
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
        [] getState(ID State)|T then % Ask for the player state
            ID = MyID % Bind the ID
            State = MyState % Bind the state
            %% Recursion
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
        [] assignSpawn(Pos)|T then
            MySpawn = Pos % Assign the spawn, should never change
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
        [] spawn(ID Pos)|T then % Ask for the position to spawn
            if MyState == on then % Already on the board
                ID = null
                Pos = null
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
            else % Off the board
                if MyLives > 0 then % Still have lives
                    ID = MyID
                    Pos = MySpawn
                    {TreatStream T on MySpawn MyLives MyPoints MyBonuses MyMap Bombes}
                else % No more lives
                    ID = null
                    Pos = null
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
                end
            end
        [] add(Type Option Result)|T then
            case Type of bomb then
                NewBonuses
            in
                case MyBonuses of bonus(bomb:NbBomb shield:NbShield) then
                    NewBonuses = bonus(bomb:NbBomb+Option shield:NbShield)
                    Result = NbBomb+Option
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap Bombes}
                end
            [] point then
                Result = MyPoints + Option
                {TreatStream T MyState MyPosition MyLives MyPoints+Option MyBonuses MyMap Bombes}
            [] life then
                Result = MyLives + Option
                {TreatStream T MyState MyPosition MyLives+Option MyPoints MyBonuses MyMap Bombes}
            [] shield then
                NewBonuses
            in
                case MyBonuses of bonus(bomb:NbBomb shield:NbShield) then
                    NewBonuses = bonus(bomb:NbBomb shield:NbShield+Option)
                    Result = NbShield+Option
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap Bombes}
                end
            %% Else for the future
            end
        [] info(Message)|T then % Player receives a message
            case Message of spawnPlayer(ID Pos) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes} % Do not take care of this information
            [] movePlayer(ID Pos) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes} % Same
            [] deadPlayer(ID) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes} % Same
            [] bombPlanted(Pos) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes} % Same
            [] bombExploded(Pos) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes} % Same
            [] boxRemoved(Pos) then
                case Pos of pt(x:X y:Y) then
                    % Call function to change the value of the map
                    % And binds it to the new map, NewMap
                    % Which must check if it is 2 or 3
                    NewMap
                in
                    NewMap = {SetMapVal MyMap X Y 1}
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses NewMap Bombes}
                end
            end
        [] doaction(ID Action)|T then % Ask the player for the action
            if MyState == off then 
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
            else
                ActionDo
                MapBombExploded
                BombsExploded
            in
                BombsExploded = {CheckBombsExploded MyBombs MyMap MapBombExploded} % Check to delete the exploded bombs from the map
                {CreateMoveAdvanced MapBombExploded MyPosition.x MyPosition.y MyBonuses.bomb ActionDo}
                ID = MyID
                case ActionDo of bomb(Pos) then
                    NewBonuses NewMap NewMap2 NewBombes
                in
                    NewBonuses = bonus(bomb:MyBonuses.bomb-1 shield:MyBonuses.shield)
                    Action = bomb(Pos)
                    NewMap= {SetMapVal MyMap Pos.x Pos.y BombCaseVal}
                    {CkeckBombe Bombes NewMap NewMap2 NewBombes}
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses NewMap2 (Pos#Input.timingBomb)|NewBombes}
                [] move(NewPos) then
                    NewMap NewBombes
                in
                    Action = move(NewPos)
                    {CkeckBombe Bombes MyMap NewMap NewBombes}
                    {TreatStream T MyState NewPos MyLives MyPoints MyBonuses NewMap NewBombes}
                end
            end
        [] gotHit(ID Result)|T then
            if MyLives =< 0 then % Was out
                ID = null
                Result = null
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap Bombes}
            else
                if MyBonuses.shield > 0 then % The player had a shield
                    NewBonuses
                in
                    NewBonuses = bonus(bomb:MyBonuses.bomb shield:MyBonuses.shield-1)
                    ID = null
                    Result = null
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap Bombes}
                else % No shield
                    ID = MyID
                    Result = death(MyLives-1)
                    {TreatStream T off MyPosition MyLives-1 MyPoints MyBonuses MyMap Bombes}
                end
            end
        else
            {Delay 3000}
            {Browser.browse elseStatement}
            {Delay 3000}
        end
    end

    proc{CkeckBombe Bombes Map NewMap NewBombes}
        case Bombes
        of nil then 
            NewMap = Map 
            NewBombes=nil
        [] (Pos#N)|T then
            if N == 0 then
                NewMap2
            in
                %Set the Map : Bombe explosed
                NewMap2 = {SetMapVal Map Pos.x Pos.y 0}
                {CkeckBombe T NewMap2 NewMap NewBombes}
            else
                Next
            in
                NewBombes = (Pos#(N-1))|Next
                {CkeckBombe T Map NewMap Next}
            end
        end
    end

    fun{IsNotBomb Map X Y}
        fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
        end
        Case
    in
        Case = {Nth {Nth Map Y} X}
        if Case == BombCaseVal then false
        else true
        end
    end

    fun{SetMapVal Map X Y Val}
        fun{Modif L N}
            case L of nil then nil
            [] H|T then
                if N == 1 then 
                    if H == 2 then 5|T
                    else 6|T
                    end
                else H|{Modif T N-1}
                end
            end
        end
        fun{Modif2 L N Value}
            case L of nil then nil
            [] H|T then
                if N == 1 then Value|T
                else H|{Modif2 T N-1 Value}
                end
            end
        end
    in
        case Map of nil then nil
        [] H|T then
            if Y == 1 then
                if Val \= 1 then
                    {Modif2 H X Val}|T
                else
                    {Modif H X}|T
                end
            else
                H|{SetMapVal T X Y-1 Val}
            end
        end
    end

    fun{SetMapValBombPlanted Map X Y}
        fun{Modif L N}
            case L of nil then nil
            [] H|T then
                if N == 1 then 
                    (H + 20)|T
                else H|{Modif T N-1}
                end
            end
        end
    in
        case Map of nil then nil
        [] H|T then
            if Y == 1 then
                {Modif H X}|T
            else
                H|{SetMapValBombPlanted T X Y-1}
            end
        end
    end

    fun{SetMapValBombExploded Map X Y}
        fun{Modif L N}
            case L of nil then nil
            [] H|T then
                if N == 1 then 
                    (H - 20)|T
                else H|{Modif T N-1}
                end
            end
        end
    in
        case Map of nil then nil
        [] H|T then
            if Y == 1 then
                {Modif H X}|T
            else
                H|{SetMapValBombExploded T X Y-1}
            end
        end
    end

    fun{GetMapVal Map X Y}
        fun{Nth L N}
            if N == 1 then L.1
            else
                {Nth L.2 N-1}
            end
        end
    in
        {Nth {Nth Map Y} X}
    end

    proc{CreateMove Map X Y NbBombs ?Action}
        Rand
    in
        Rand = ({OS.rand} + 1) mod 9 % Create the random
        if Rand == 5 then % A bomb it is
            if NbBombs > 0 then % Check if it has a bomb in stock
                Action = bomb(pt(x:X y:Y)) % Gives the action
            else
                {CreateMove Map X Y NbBombs Action} % Recursion until it is good
            end
        else
            Rand2
        in
            Rand2 = ({OS.rand} + 1) mod 4
            if Rand2 == 0 then % To the north
                Bool
            in
                Bool = {CheckMove Map X Y-1}
                if Bool then % The player can go this way
                    Action = move(pt(x:X y:Y-1))
                else
                    {CreateMove Map X Y NbBombs Action}
                end
            elseif Rand2 == 1 then % To the south
                Bool
            in
                Bool = {CheckMove Map X Y+1}
                if Bool then % The player can go this way
                    Action = move(pt(x:X y:Y+1))
                else
                    {CreateMove Map X Y NbBombs Action}
                end
            elseif Rand2 == 2 then % To the east
                Bool
            in
                Bool = {CheckMove Map X+1 Y}
                if Bool then % The player can go this way
                    Action = move(pt(x:X+1 y:Y))
                else
                    {CreateMove Map X Y NbBombs Action}
                end
            elseif Rand2 == 3 then % To the west
                Bool
            in
                Bool = {CheckMove Map X-1 Y}
                if Bool then % The player can go this way
                    Action = move(pt(x:X-1 y:Y))
                else
                    {CreateMove Map X Y NbBombs Action}
                end
            end
        end
    end

    proc{CreateMoveAdvanced Map X Y NbBombs ?Action}
        % We suppose that tere is at least one possible displacement for the player 
        % (it is a reasonable assumption)
        fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
        end
        PossibleMove
        Next
        Next2
        Next3
        Next4
    in
        if {CheckMove Map X+1 Y} then % We can move to the east
            PossibleMove = pt(x:X+1 y:Y)|Next
        else
            PossibleMove = Next
        end
        if {CheckMove Map X-1 Y} then % We can move to the west
            Next = pt(x:X-1 y:Y)|Next2
        else
            Next = Next2
        end
        if {CheckMove Map X Y+1} then % We can move to the south
            Next2 = pt(x:X y:Y+1)|Next3
        else
            Next2 = Next3
        end
        if {CheckMove Map X Y-1} then % We can move to the north
            Next3 = pt(x:X y:Y-1)|Next4
        else
            Next3 = Next4
        end
        Next4 = nil

        if NbBombs > 0 andthen {IsNotBomb Map X Y} then 
        % If the player can drop a bomb and they are no own bomb already, we use a random
            Rand1 Rand2
        in
            Rand1 = ({OS.rand} + 1) mod 9 % 10% chance to drop a bomb
            if Rand1 == 5 then % Drop the bomb
                Action = bomb(pt(x:X y:Y))
            else % Move
                Rand2 = ({OS.rand} mod {Length PossibleMove}) + 1
                Action = move({Nth PossibleMove Rand2})
            end
        else
            Rand2
        in
            Rand2 = ({OS.rand} mod {Length PossibleMove}) + 1
            Action = move({Nth PossibleMove Rand2})
        end
    end


    fun{CheckMove Map X Y}
        fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
        end
    in
        if X >= 1 andthen X < Input.nbColumn+1 andthen Y >=1 andthen Y < Input.nbRow+1 then
            Case
        in
            Case = {Nth {Nth Map Y} X}
            if Case == 1 orelse Case == 2 orelse Case == 3 then false
            else true
            end
        else
            false
        end
    end

    fun{CheckBombsExploded TheBombs TheMap MapReturn}
        case TheBombs of nil then MapReturn = TheMap nil
        [] (Position#Timer)|T then
            if Timer == 0 then % Bomb has exploded
                NewMap
            in
                NewMap = {SetMapValBombExploded TheMap Position.x Position.y}
                {CheckBombsExploded T NewMap MapReturn}
            else
                (Position#(Timer-1))|{CheckBombsExploded T TheMap MapReturn}
            end
        end
    end



end