functor
import
   Input
   Projet2019util
   OS
export
   portPlayer:StartPlayer
define   
    StartPlayer
    TreatStream
    Name = 'Player001random'

    SetMapVal
    SetMapValRemoveBonus
    SetMapValBombPlanted
    SetMapValBombExploded
    GetMapVal

    CheckMove
    CheckBombsExploded
    CheckMyBombExploded

    Delete

    Reachable
    SafeZone
    SafePossibleMove
    AreBonusToTake
    BonusPositions
    IsBoxToBreak

    CreateMoveAdvanced

    MySpawn
    MyID
in

    fun{StartPlayer ID}
        Stream Port OutputStream
    in
        MyID = ID % Assign the ID, will never change
        thread %% filter to test validity of message sent to the player
            OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
        end
        {NewPort Stream Port}
        thread
            {TreatStream OutputStream off MySpawn Input.nbLives 0 bonus(bomb:Input.nbBombs shield:0) Input.map nil nil nil}
        end
        Port
    end

    proc{TreatStream Stream MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
        case Stream
        of getId(ID)|T then % Ask for the player ID
            ID = MyID % Bind it
            %% Recursion
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
        [] getState(ID State)|T then % Ask for the player state
            ID = MyID % Bind the ID
            State = MyState % Bind the state
            %% Recursion
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
        [] assignSpawn(Pos)|T then
            MySpawn = Pos % Assign the spawn, should never change
            {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
        [] spawn(ID Pos)|T then % Ask for the position to spawn
            if MyState == on then % Already on the board
                ID = null
                Pos = null
                %% Recursion
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
            else % Off the board
                if MyLives > 0 then % Still have lives
                    % ID and Pos are the same as the assigned as spawn
                    ID = MyID
                    Pos = MySpawn
                    %% Recursion
                    {TreatStream T on MySpawn MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
                else % No more lives
                    ID = null
                    Pos = null
                    %% Recursion
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
                end
            end
        [] add(Type Option Result)|T then % Notify the bomber of recieving an additionnal ”item”
            case Type 
            of bomb then % New Bombe
                NewBonuses
            in
                case MyBonuses of bonus(bomb:NbBomb shield:NbShield) then
                    Result = NbBomb+Option % return the new value of NbBomb
                    NewBonuses = bonus(bomb:Result shield:NbShield)
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes PlayersPosition}
                end
            [] point then % New Point
                Result = MyPoints + Option
                {TreatStream T MyState MyPosition MyLives MyPoints+Option MyBonuses MyMap MyBombs AllBombes PlayersPosition}
            % Optional Part
            [] life then % New Life 
                Result = MyLives + Option % return the new value of MyLives
                {TreatStream T MyState MyPosition Result MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
            [] shield then % New Shield
                NewBonuses
            in
                case MyBonuses of bonus(bomb:NbBomb shield:NbShield) then
                    Result = NbShield+Option % return the new value of NbShield
                    NewBonuses = bonus(bomb:NbBomb shield:Result)
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes PlayersPosition}
                end
            %% Else for the future
            end
        [] info(Message)|T then % Inform the player about some events
            case Message 
            of spawnPlayer(_ _) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition} % Do not take care of this information
            [] movePlayer(_ Pos) then Val in
                Val = {GetMapVal MyMap Pos.x Pos.y}
                % If a player is on a bonus/point case, we change this bonus/point case with a simple floor case
                if Val == 2 orelse Val == 3 then 
                    case Pos of pt(x:X y:Y) then NewMap in
                    NewMap = {SetMapValRemoveBonus MyMap X Y}
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses NewMap MyBombs AllBombes PlayersPosition}
                    end
                else
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition} % Same
                end
            [] deadPlayer(_) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition} % Do not take care of this information
            [] bombPlanted(Pos) then
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs Pos|AllBombes PlayersPosition} % add Pos of the bombe to AllBombes
            [] bombExploded(Pos) then
                MapWithoutTheBomb
                NewBombs
                WasMyBomb
            in
                NewBombs = {CheckMyBombExploded MyBombs Pos WasMyBomb}
                if WasMyBomb then 
                    MapWithoutTheBomb = {SetMapValBombExploded MyMap Pos.x Pos.y}
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MapWithoutTheBomb NewBombs {Delete AllBombes Pos} PlayersPosition} % Same
                else
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap NewBombs {Delete AllBombes Pos} PlayersPosition}
                end
            [] boxRemoved(Pos) then
                case Pos of pt(x:X y:Y) then
                    % Call function to change the value of the map
                    % And binds it to the new map, NewMap
                    % Which must check if it is 2 or 3
                    NewMap
                in
                    NewMap = {SetMapVal MyMap X Y}
                    {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses NewMap MyBombs AllBombes PlayersPosition}
                end
            end
        [] doaction(ID Action)|T then % Ask the player for the action
            if MyState == off then
                ID = null
                Action = null
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
            else
                ActionDo
            in
                {CreateMoveAdvanced MyMap MyPosition.x MyPosition.y MyBonuses.bomb AllBombes ActionDo}
                ID = MyID
                case ActionDo of bomb(Pos) then
                    NewBonuses
                    NewBombs
                    MapWithTheBomb
                in
                    Action = bomb(Pos)
                    NewBonuses = bonus(bomb:MyBonuses.bomb-1 shield:MyBonuses.shield)
                    NewBombs = Pos|MyBombs
                    MapWithTheBomb = {SetMapValBombPlanted MyMap Pos.x Pos.y}
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MapWithTheBomb NewBombs AllBombes PlayersPosition}
                [] move(NewPos) then
                    Action = move(NewPos)
                    {TreatStream T MyState NewPos MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
                end
            end
        [] gotHit(ID Result)|T then
            if MyLives =< 0 then % Was out
                ID = null
                Result = null
                {TreatStream T MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
            else
                if MyBonuses.shield > 0 then % The player had a shield
                    NewBonuses
                in
                    NewBonuses = bonus(bomb:MyBonuses.bomb shield:MyBonuses.shield-1)
                    ID = null
                    Result = null
                    {TreatStream T MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes PlayersPosition}
                else % No shield
                    ID = MyID
                    Result = death(MyLives-1)
                    {TreatStream T off MyPosition MyLives-1 MyPoints MyBonuses MyMap MyBombs AllBombes PlayersPosition}
                end
            end
        end
    end

    fun{SetMapVal Map X Y}
        fun{Modif L N}
            case L of nil then nil
            [] H|T then
                if N == 1 then 
                    if H == 2 then 5|T %Point
                    else 6|T % Bonus
                    end
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
                H|{SetMapVal T X Y-1}
            end
        end
    end
    fun{SetMapValRemoveBonus Map X Y}
        fun{Modif L N}
            case L of nil then nil
            [] H|T then
                if N == 1 then 
                    0|T % RemoveBonus
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
                H|{SetMapVal T X Y-1}
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
    fun{CheckMyBombExploded MyBombs Position ?WasMyBomb}
        case MyBombs of H|T then
            if H.x == Position.x andthen H.y == Position.y then
                WasMyBomb = true
                T
            else
                H|{CheckMyBombExploded T Position WasMyBomb}
            end
        [] nil then WasMyBomb = false nil
        end
    end

    fun{Delete List Item}
        case List of nil then nil
        [] H|T then
            if H == Item then T
            else H|{Delete T Item}
            end
        end
    end

    %Reachable test if at PlayerPos a Bomba at BombePos can hit him
    fun{Reachable PlayerPos BombePos}
        if PlayerPos.y == BombePos.y then Val in
            Val = PlayerPos.x - BombePos.x
            if {Abs Val} =< 1 then true
            else false
            end
        elseif PlayerPos.x == BombePos.x then Val in
            Val = PlayerPos.y - BombePos.y
            if {Abs Val} =< 1 then true
            else false
            end
        else false
        end
    end
    %SafeZone test if at PlayerPos none bombe can hit him
    fun{SafeZone PlayerPos AllBombes}
        case AllBombes
        of nil then true
        [] H|T then
            if {Reachable PlayerPos H} then false
            else {SafeZone PlayerPos T}
            end
        end
    end
    %Filter all SafeZone move
    fun{SafePossibleMove PossibleMove AllBombes}
        case PossibleMove
        of nil then nil
        [] H|T then
            if {SafeZone H AllBombes} then H|{SafePossibleMove T AllBombes}
            else {SafePossibleMove T AllBombes}
            end
        end
    end
    %AreBonusToTake test if at PlayerPos they are a bonus or a point to take
    fun{AreBonusToTake PlayerPos Map}
        Val
    in
        Val = {GetMapVal Map PlayerPos.x PlayerPos.y}
        Val == 5 orelse Val == 6
    end
    %Filter all AreBonusToTake move
    fun{BonusPositions PossibleMove Map}
        case PossibleMove
        of nil then nil
        [] H|T then
            if {AreBonusToTake H Map} then H|{BonusPositions T Map}
            else {BonusPositions T Map}
            end
        end
    end
    %Test if they are a Box to Break with a distance of one
    fun{IsBoxToBreak PlayerPos Map}
        fun{Check CurrentPosition}
            Val
        in
            Val = {GetMapVal Map CurrentPosition.x CurrentPosition.y}
            Val == 2 orelse Val == 3
        end
        A B C D
    in
        thread A = {Check pt(x:PlayerPos.x+1 y:PlayerPos.y)} end
        thread B = {Check pt(x:PlayerPos.x-1 y:PlayerPos.y)} end
        thread C = {Check pt(x:PlayerPos.x y:PlayerPos.y+1)} end
        thread D = {Check pt(x:PlayerPos.x y:PlayerPos.y-1)} end
        {Wait A}
        {Wait B}
        {Wait C}
        {Wait D}
        A orelse B orelse C orelse D
    end

    proc{CreateMoveAdvanced Map X Y NbBombs AllBombes ?Action}
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
        %% Here we have all possible move that we can do

        
        if NbBombs > 0 andthen {GetMapVal Map X Y} < 10 andthen {IsBoxToBreak pt(x:X y:Y) Map} then % If the player can drop a bomb and the bombe will break a box
            Action = bomb(pt(x:X y:Y))
        else %Move
            Rand2 Tmp SafeMove
        in
            SafeMove = {SafePossibleMove PossibleMove AllBombes}
            Tmp = {Length SafeMove}
            if Tmp == 0 then %No SafeMove
                if {SafeZone pt(x:X y:Y) AllBombes} then % Stay at same place to not take any risk
                    Action = bomb(pt(x:X y:Y))
                else
                    Rand2 = ({OS.rand} mod {Length PossibleMove}) + 1
                    Action = move({Nth PossibleMove Rand2})
                end
            else % They are SafeMove
                BonusMove Tmp2
            in
                BonusMove = {BonusPositions SafeMove Map}
                Tmp2 = {Length BonusMove}
                if Tmp2 == 0 then % No BonusMove
                    Rand2 = ({OS.rand} mod Tmp) + 1
                    Action = move({Nth SafeMove Rand2})
                else
                    Rand2 = ({OS.rand} mod Tmp2) + 1
                    Action = move({Nth BonusMove Rand2})
                end
            end
        end
    end
end