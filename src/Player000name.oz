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
   Name = 'namefordebug'
   Row
   Column
   CheckMove
   Map
   SpawnPos
   ID
   SetMapVal
   MakeAMove
in
   Map = Input.map
   Row = Input.nbRow
   Column = Input.nbColumn


   fun{StartPlayer IDD}
      Stream Port OutputStream
   in
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread Pos in 
      IDD = ID
      {TreatStream OutputStream on null 0 Input.nbBombs Input.nbLives 0 Map}
      end
      Port
   end

   
   proc{TreatStream Stream State Position Points NbBomb NbLife Point Map} %% TODO you may add some arguments if needed
      case Stream 
      of getId(IDD)|T then IDD = ID {TreatStream T State Position Points NbBomb NbLife Point Map}
      [] getState(IDD SState)|T then IDD = ID SState = State {TreatStream T State Position Points NbBomb NbLife Point Map}
      [] assignSpawn(Pos)|T then
         SpawnPos = Pos
         {TreatStream T State Pos Points NbBomb NbLife Point Map}
      [] spawn(IDD Pos)|T then
         IDD = ID
         Pos = SpawnPos
         {TreatStream T on Position Points NbBomb NbLife Point Map}
      [] position(Pos)|T then Pos = Position {TreatStream T State Position Points NbBomb NbLife Point Map}
      [] add(Type Option Result)|T then
         case Type
         of bomb then Result = NbBomb + Option
            {TreatStream T State Position Points Result NbLife Point Map}
         [] point then Result = Points + Option
            {TreatStream T State Position Result NbBomb NbLife Result Map}
         end
      [] info(Message)|T then
         case Message
         of deadPlayer(IDD) then skip
         [] spawnPlayer(ID Pos) then skip
         [] movePlayer(ID Pos) then skip
         [] bombPlanted(Pos) then skip
         [] bombExploded(Pos) then skip
         [] boxRemoved(Pos) then 
            {TreatStream T State Position Points NbBomb NbLife Point {SetMapVal Map Pos.x Pos.y 0}}
         end
         {TreatStream T State Position Points NbBomb NbLife Point Map}
      [] gotHit(IDD Result)|T then
         IDD = ID
         Result = death(NbLife-1)
         if NbLife-1 > 0 then
            {TreatStream T on SpawnPos Points NbBomb NbLife-1 Point Map}
         else
            {TreatStream T off SpawnPos Points NbBomb 0 Point Map}
         end
      [] doaction(IDD Action)|T then
         Prob in
         IDD = ID
         Prob = ({OS.rand} + 1) mod 9
         if Prob == 5 then 
            if NbBomb > 0 then
               Action = bomb(Position)
               {TreatStream T State Position Points NbBomb-1 NbLife Point Map}
            else
               Action = null
               {TreatStream T State Position Points NbBomb NbLife Point Map}
            end
         else
            Action = {MakeAMove Position Map}
            {TreatStream T State Action.1 Points NbBomb NbLife Point Map}
         end
      end
   end

   %% Function to check if the new position is valid
   fun{CheckMove X Y Map}
      fun{CheckMap X Y Map}
         fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
         end
      in
         {Nth {Nth Map Y} X} == 0
      end
   in
      if (X >= 1 andthen X < Column+1 andthen Y >= 1 andthen Y < Row+1 andthen {CheckMap X Y Map})
      then true
      else false
      end
   end
   
   fun{MakeAMove Position Map}
      P2
   in
      P2 = ({OS.rand} + 1) mod 4
      if P2 == 0 then
         if {CheckMove Position.x+1 Position.y Map} then
            move(pt(x:Position.x+1 y:Position.y))
         elseif {CheckMove Position.x-1 Position.y Map} then
            move(pt(x:Position.x-1 y:Position.y))
         elseif {CheckMove Position.x Position.y+1 Map} then
            move(pt(x:Position.x y:Position.y+1))
         elseif {CheckMove Position.x Position.y-1 Map} then
            move(pt(x:Position.x y:Position.y-1))
         else
            move(pt(x:Position.x y:Position.y))
         end
      elseif P2 == 1 then
         if {CheckMove Position.x-1 Position.y Map} then
            move(pt(x:Position.x-1 y:Position.y))
         elseif {CheckMove Position.x+1 Position.y Map} then
            move(pt(x:Position.x+1 y:Position.y))
         elseif {CheckMove Position.x Position.y+1 Map} then
            move(pt(x:Position.x y:Position.y+1))
         elseif {CheckMove Position.x Position.y-1 Map} then
            move(pt(x:Position.x y:Position.y-1))
         else
            move(pt(x:Position.x y:Position.y))
         end
      elseif P2 == 2 then
         if {CheckMove Position.x Position.y+1 Map} then
            move(pt(x:Position.x y:Position.y+1))
         elseif {CheckMove Position.x Position.y-1 Map} then
            move(pt(x:Position.x y:Position.y-1))
         elseif {CheckMove Position.x+1 Position.y Map} then
            move(pt(x:Position.x+1 y:Position.y))
         elseif {CheckMove Position.x-1 Position.y Map} then
            move(pt(x:Position.x-1 y:Position.y))
         else
            move(pt(x:Position.x y:Position.y))
         end
      elseif P2 == 3 then
         if {CheckMove Position.x Position.y-1 Map} then
            move(pt(x:Position.x y:Position.y-1))
         elseif {CheckMove Position.x Position.y+1 Map} then
            move(pt(x:Position.x y:Position.y+1))
         elseif {CheckMove Position.x+1 Position.y Map} then
            move(pt(x:Position.x+1 y:Position.y))
         elseif {CheckMove Position.x-1 Position.y Map} then
            move(pt(x:Position.x-1 y:Position.y))
         else
            move(pt(x:Position.x y:Position.y))
         end
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

end
