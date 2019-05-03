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
    Name = 'Player100advanced'

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

    Distance
    Closest
    OnBomb

    CreateMoveAdvanced

in

    fun{StartPlayer ID}
        Stream Port OutputStream MySpawn
    in
        thread %% filter to test validity of message sent to the player
            OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
        end
        {NewPort Stream Port}
        thread
            {TreatStream OutputStream ID off MySpawn Input.nbLives 0 bonus(bomb:Input.nbBombs shield:0) Input.map nil nil MySpawn}
        end
        Port
    end

    proc{TreatStream Stream MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
        case Stream
        of getId(ID)|T then % Ask for the player ID
            ID = MyID % Bind it
            %% Recursion
            {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
        [] getState(ID State)|T then % Ask for the player state
            ID = MyID % Bind the ID
            State = MyState % Bind the state
            %% Recursion
            {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
        [] assignSpawn(Pos)|T then
            MySpawn = Pos % Assign the spawn, should never change
            {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
        [] spawn(ID Pos)|T then % Ask for the position to spawn
            if MyState == on then % Already on the board
                ID = null
                Pos = null
                %% Recursion
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
            else % Off the board
                if MyLives > 0 then % Still have lives
                    % ID and Pos are the same as the assigned as spawn
                    ID = MyID
                    Pos = MySpawn
                    %% Recursion
                    {TreatStream T MyID on MySpawn MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
                else % No more lives
                    ID = null
                    Pos = null
                    %% Recursion
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
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
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes MySpawn}
                end
            [] point then % New Point
                Result = MyPoints + Option
                {TreatStream T MyID MyState MyPosition MyLives MyPoints+Option MyBonuses MyMap MyBombs AllBombes MySpawn}
            % Optional Part
            [] life then % New Life 
                Result = MyLives + Option % return the new value of MyLives
                {TreatStream T MyID MyState MyPosition Result MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
            [] shield then % New Shield
                NewBonuses
            in
                case MyBonuses of bonus(bomb:NbBomb shield:NbShield) then
                    Result = NbShield+Option % return the new value of NbShield
                    NewBonuses = bonus(bomb:NbBomb shield:Result)
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes MySpawn}
                end
            %% Else for the future
            end
        [] info(Message)|T then % Inform the player about some events
            case Message 
            of spawnPlayer(_ _) then
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn} % Do not take care of this information
            [] movePlayer(_ Pos) then Val in
                Val = {GetMapVal MyMap Pos.x Pos.y}
                % If a player is on a bonus/point case, we change this bonus/point case with a simple floor case
                if Val == 2 orelse Val == 3 orelse Val == 5 orelse Val == 6 then 
                    case Pos of pt(x:X y:Y) then NewMap in
                    NewMap = {SetMapValRemoveBonus MyMap X Y}
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses NewMap MyBombs AllBombes MySpawn}
                    end
                else
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn} % Same
                end
            [] deadPlayer(_) then
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn} % Do not take care of this information
            [] bombPlanted(Pos) then
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs Pos|AllBombes MySpawn} % add Pos of the bombe to AllBombes
            [] bombExploded(Pos) then
                MapWithoutTheBomb
                NewBombs
                WasMyBomb
            in
                NewBombs = {CheckMyBombExploded MyBombs Pos WasMyBomb}
                if WasMyBomb then 
                    MapWithoutTheBomb = {SetMapValBombExploded MyMap Pos.x Pos.y}
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MapWithoutTheBomb NewBombs {Delete AllBombes Pos} MySpawn} % Same
                else
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap NewBombs {Delete AllBombes Pos} MySpawn}
                end
            [] boxRemoved(Pos) then
                case Pos of pt(x:X y:Y) then
                    % Call function to change the value of the map
                    % And binds it to the new map, NewMap
                    % Which must check if it is 2 or 3
                    NewMap
                in
                    NewMap = {SetMapVal MyMap X Y}
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses NewMap MyBombs AllBombes MySpawn}
                end
            end
        [] doaction(ID Action)|T then % Ask the player for the action
            if MyState == off then
                %no delay here because the player is off
                ID = null
                Action = null
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
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
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints NewBonuses MapWithTheBomb NewBombs AllBombes MySpawn}
                [] move(NewPos) then Val in
                    Action = move(NewPos)
                    Val = {GetMapVal MyMap NewPos.x NewPos.y}
                    if Val == 2 orelse Val == 3 orelse Val == 5 orelse Val == 6 then 
                        NewMap
                    in
                        NewMap = {SetMapValRemoveBonus MyMap NewPos.x NewPos.y}
                        {TreatStream T MyID MyState NewPos MyLives MyPoints MyBonuses NewMap MyBombs AllBombes MySpawn}
                    else
                        {TreatStream T MyID MyState NewPos MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
                    end
                end
            end
        [] gotHit(ID Result)|T then
            if MyLives =< 0 orelse MyState == off then % Was out
                ID = null
                Result = null
                {TreatStream T MyID MyState MyPosition MyLives MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
            else
                if MyBonuses.shield > 0 then % The player had a shield
                    NewBonuses
                in
                    NewBonuses = bonus(bomb:MyBonuses.bomb shield:MyBonuses.shield-1)
                    ID = null
                    Result = null
                    {TreatStream T MyID MyState MyPosition MyLives MyPoints NewBonuses MyMap MyBombs AllBombes MySpawn}
                else % No shield
                    ID = MyID
                    Result = death(MyLives-1)
                    {TreatStream T MyID off MyPosition MyLives-1 MyPoints MyBonuses MyMap MyBombs AllBombes MySpawn}
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
                    elseif H == 3 then 6|T % Bonus
                    else 0|T
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
    fun{Reachable PlayerPos BombePos Map}
        fun{OneDirection CurrentPosition Direction Count}
            Val
        in
            Val = {GetMapVal Map CurrentPosition.x CurrentPosition.y}
            if Count >= Input.fire then false
            elseif Val == 1 orelse Val == 2 orelse Val == 3 then false
            elseif CurrentPosition == PlayerPos then true
            else
                case Direction
                of north then
                    {OneDirection pt(x:CurrentPosition.x+1 y:CurrentPosition.y) Direction Count+1}
                [] south then
                    {OneDirection pt(x:CurrentPosition.x-1 y:CurrentPosition.y) Direction Count+1}
                [] east then
                    {OneDirection pt(x:CurrentPosition.x y:CurrentPosition.y+1) Direction Count+1}
                [] weast then
                    {OneDirection pt(x:CurrentPosition.x y:CurrentPosition.y-1) Direction Count+1}
                end
            end
        end
    in
        if PlayerPos == BombePos then true
        else A B C D in
            thread A = {OneDirection pt(x:BombePos.x+1 y:BombePos.y) north 0}end
            thread B = {OneDirection pt(x:BombePos.x-1 y:BombePos.y) south 0}end
            thread C = {OneDirection pt(x:BombePos.x y:BombePos.y+1) east 0}end
            thread D = {OneDirection pt(x:BombePos.x y:BombePos.y-1) weast 0}end
            
            A orelse B orelse C orelse D
        end
    end
    %SafeZone test if at PlayerPos none bombe can hit him
    fun{SafeZone PlayerPos AllBombes Map}
        case AllBombes
        of nil then true
        [] H|T then
            if {Reachable PlayerPos H Map} then false
            else {SafeZone PlayerPos T Map}
            end
        end
    end
    %Filter all SafeZone move
    fun{SafePossibleMove PossibleMove AllBombes Map}
        case PossibleMove
        of nil then nil
        [] H|T then
            if {SafeZone H AllBombes Map} then H|{SafePossibleMove T AllBombes Map}
            else {SafePossibleMove T AllBombes Map}
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
    fun{Distance X1 Y1 X2 Y2}
        {Sqrt ({IntToFloat (X1-X2)*(X1-X2)}+{IntToFloat (Y1-Y2)*(Y1-Y2)})}
    end
    fun{Closest PosPlayer PosBombs}
        fun{Help PosPlayer PosBombs Pos}
            case PosBombs
            of nil then Pos
            [] H|T then Val in
	            Val = {Distance PosPlayer.x PosPlayer.y H.x H.y}
	            if Val < {Distance PosPlayer.x PosPlayer.y Pos.x Pos.y}
	            then {Help PosPlayer T H}
	            else {Help PosPlayer T Pos}
	            end
            end
        end
    in
        {Help PosPlayer PosBombs pt(x:(Input.nbColumn)*2 y:(Input.nbRow)*2)}
    end
    fun{OnBomb PosPlayers PosBombs ClosestBomb}
        fun{Help PosPlayers PosBombs Pos}
            case PosPlayers of nil then Pos
            [] H|T then
                if(ClosestBomb == {Closest H PosBombs})
                then {Help T PosBombs H}
                else {Help T PosBombs Pos}
                end
            end
        end
    in
        {Help PosPlayers PosBombs PosPlayers.1}
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
        SafeMove
        Tmp
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

        SafeMove = {SafePossibleMove PossibleMove AllBombes Map}
        Tmp = {Length SafeMove}
        
        if Tmp > 0 andthen NbBombs > 0 andthen {GetMapVal Map X Y} < 10 andthen {IsBoxToBreak pt(x:X y:Y) Map} then % If the player can drop a bomb and the bombe will break a box
            Action = bomb(pt(x:X y:Y))
        else %Move
            Rand2
        in
            if Tmp == 0 then %No SafeMove
                if Input.useExtention andthen {SafeZone pt(x:X y:Y) AllBombes Map} then % Stay at same place to not take any risk
                    Action = move(pt(x:X y:Y))
                else
                    ClosestBomb
                in
                    if {Length PossibleMove} == 1 then Action = move(PossibleMove.1)
                    else
                    ClosestBomb = {Closest pt(x:X y:Y) AllBombes}
                    if ClosestBomb == pt(x:X y:Y) then
                        Action = move({OnBomb PossibleMove AllBombes ClosestBomb})
                    elseif ClosestBomb.x == X then
                        if ClosestBomb.y < Y then
                            if {CheckMove Map X Y+1} then
                                Action = move(pt(x:X y:Y+1))
                            elseif {CheckMove Map X+1 Y} andthen {Not {CheckMove Map X-1 Y}} then
                                Action = move(pt(x:X+1 y:Y))
                            elseif {CheckMove Map X-1 Y} andthen {Not {CheckMove Map X+1 Y}} then
                                Action = move(pt(x:X-1 y:Y))
                            elseif {Not {CheckMove Map X-1 Y}} andthen {Not {CheckMove Map X+1 Y}} then
                                Action = move(pt(x:X y:Y-1))
                            else
                                if({Closest pt(x:X+1 y:Y) AllBombes} == ClosestBomb)
                                then Action = move(pt(x:X+1 y:Y))
                                else Action = move(pt(x:X-1 y:Y))
                                end
                            end
                        else
                            if {CheckMove Map X Y-1} then
                                Action = move(pt(x:X y:Y-1))
                            elseif {CheckMove Map X+1 Y} andthen {Not {CheckMove Map X-1 Y}} then
                                Action = move(pt(x:X+1 y:Y))
                            elseif {CheckMove Map X-1 Y} andthen {Not {CheckMove Map X+1 Y}} then
                                Action = move(pt(x:X-1 y:Y))
                            elseif {Not {CheckMove Map X-1 Y}} andthen {Not {CheckMove Map X+1 Y}} then
                                Action = move(pt(x:X y:Y+1))
                            else
                                if({Closest pt(x:X+1 y:Y) AllBombes} == ClosestBomb)
                                then Action = move(pt(x:X+1 y:Y))
                                else Action = move(pt(x:X-1 y:Y))
                                end
                            end
                        end
                    elseif ClosestBomb.y == Y then
                        if ClosestBomb.x < X then
                            if {CheckMove Map X+1 Y} then
                                Action = move(pt(x:X+1 y:Y))
                            elseif {CheckMove Map X Y+1} andthen {Not {CheckMove Map X Y-1}} then
                                Action = move(pt(x:X y:Y+1))
                            elseif {CheckMove Map X Y-1} andthen {Not {CheckMove Map X Y+1}} then
                                Action = move(pt(x:X y:Y-1))
                            elseif {Not {CheckMove Map X Y-1}} andthen {Not {CheckMove Map X Y+1}} then
                                Action = move(pt(x:X-1 y:Y))
                            else
                                if({Closest pt(x:X y:Y+1) AllBombes} == ClosestBomb)
                                then Action = move(pt(x:X y:Y+1))
                                else Action = move(pt(x:X y:Y-1))
                                end
                            end
                        else
                            if {CheckMove Map X-1 Y} then
                                Action = move(pt(x:X-1 y:Y))
                            elseif {CheckMove Map X Y+1} andthen {Not {CheckMove Map X Y-1}} then
                                Action = move(pt(x:X y:Y+1))
                            elseif {CheckMove Map X Y-1} andthen {Not {CheckMove Map X Y+1}} then
                                Action = move(pt(x:X y:Y-1))
                            elseif {Not {CheckMove Map X Y-1}} andthen {Not {CheckMove Map X Y+1}} then
                                Action = move(pt(x:X+1 y:Y))
                            else
                                if({Closest pt(x:X y:Y+1) AllBombes} == ClosestBomb)
                                then Action = move(pt(x:X y:Y+1))
                                else Action = move(pt(x:X y:Y-1))
                                end
                            end
                        end
                    else
                        Rand2
                    in
                        if {Length PossibleMove} == 0 then
                            {System.show 'Impossible to make a move! ERROR'}
                        else
                            Rand2 = ({OS.rand} mod {Length PossibleMove}) + 1
                            Action = move({Nth PossibleMove Rand2})
                        end
                    end
                    end
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