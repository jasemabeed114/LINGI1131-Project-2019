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
   IdDead
   Map
   SpawnPos

in
   Map = Input.map
   Row = Input.nbRow
   Column = Input.nbColumn


   fun{StartPlayer ID}
      Stream Port OutputStream
   in
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread Pos in 
      {TreatStream OutputStream ID on null 0 Input.nbBombs Input.nbLives}
      end
      Port
   end

   
   proc{TreatStream Stream ID State Position Points NbBomb NbLife} %% TODO you may add some arguments if needed
      case Stream 
      of getID(IDD)|T then IDD = ID {TreatStream T ID State Position Points NbBomb NbLife}
      [] getState(IDD SState)|T then IDD = ID SState = State {TreatStream T ID State Position Points NbBomb NbLife}
      [] assignSpawn(Pos)|T then
         SpawnPos = Pos
         {TreatStream T ID State Pos Points NbBomb NbLife}
      [] spawn(IDD Pos)|T then
         IDD = ID
         Pos = SpawnPos
         {TreatStream T ID on Position Points NbBomb NbLife}
      [] position(Pos)|T then Pos = Position {TreatStream T ID State Position Points NbBomb NbLife}
      [] add(Type Option Result)|T then
         case Type
         of bomb then Result = NbBomb + Option
            {TreatStream T ID State Position Points Result NbLife}
         [] point then Result = Points + Option
            {TreatStream T ID State Position Result NbBomb NbLife}
         end
      [] info(Message)|T then
         case Message
         of deadPlayer(IDD) then
            if (IDD == ID) then {TreatStream T ID off Position Points NbBomb NbLife} end
         [] spawnPlayer(ID Pos) then skip
         [] movePlayer(ID Pos) then skip
         [] deadPlayer(ID) then skip
         [] bombPlanted(Pos) then skip
         [] bombExploded(Pos) then
            if({IdDead Position Pos}) 
            then {TreatStream T ID off Position Points NbBomb NbLife}
            end
         [] boxRemoved(Pos) then skip
         end
         {TreatStream T ID State Position Points NbBomb NbLife}
      [] gotHit(IDD Result)|T then
         IDD = ID
         Result = death(NbLife-1)
         if NbLife-1 > 0 then
            {TreatStream T ID on SpawnPos Points NbBomb NbLife-1}
         else
            {TreatStream T ID off SpawnPos Points NbBomb 0}
         end
      [] doaction(IDD Action)|T then
         Prob in
         IDD = ID
         Prob = ({OS.rand} + 1) mod 9
         if Prob == 5 then 
            if NbBomb > 0 then
               Action = bomb(Position)
               {TreatStream T ID State Position Points NbBomb-1 NbLife}
            else
               Action = null
               {TreatStream T ID State Position Points NbBomb NbLife}
            end
         else
            P2 in
            P2 = ({OS.rand} + 1) mod 4
            if P2 == 0 then
               if {CheckMove Position.x+1 Position.y} then
                  Action = move(pt(x:Position.x+1 y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               end
            elseif P2 == 1 then
               if {CheckMove Position.x-1 Position.y} then
                  Action = move(pt(x:Position.x-1 y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               end
            elseif P2 == 2 then
               if {CheckMove Position.x Position.y+1} then
                  Action = move(pt(x:Position.x y:Position.y+1))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               end
            elseif P2 == 3 then
               if {CheckMove Position.x Position.y-1} then
                  Action = move(pt(x:Position.x y:Position.y-1))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb NbLife}
               end
            end
         end
      end
   end

   %% Function to check if the new position is valid
   fun{CheckMove X Y}
      fun{CheckMap X Y}
         fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
         end
      in
         {Nth {Nth Map Y} X} \= 1
      end
   in
      if (X >= 1 andthen X < Column+1 andthen Y >= 1 andthen Y < Row+1 andthen {CheckMap X Y})
      then true
      else false
      end
   end
   

   fun{IdDead PosPlayer PosBomb}
      case PosPlayer#PosBomb
      of pt(x:XP y:YP)#pt(x:XB y:YB) then
         if (XP - XB =< Input.fire) then true
         elseif (XB - XP =< Input.fire) then true
         elseif (YP - YB =< Input.fire) then true
         elseif (YB - YP =< Input.fire) then true
         else false
         end
      end
   end
end
