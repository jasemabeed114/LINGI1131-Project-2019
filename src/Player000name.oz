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
   Positions
   Row
   Column
   CheckMove
   Map

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
      thread State Pos in 
      {TreatStream OutputStream ID State null 0 Input.nbBombs}
      end
      Port
   end

   
   proc{TreatStream Stream ID State Position Points NbBomb} %% TODO you may add some arguments if needed
      case Stream 
      of getID(IDD)|T then IDD = ID {TreatStream T ID State Position Points NbBomb}
      [] getState(IDD SState)|T then IDD = ID SState = State {TreatStream T ID State Position Points NbBomb}
      [] assignSpawn(Pos)|T then
         {TreatStream T ID State Pos Points NbBomb}
      [] spawn(IDD Pos)|T then
         IDD = ID
         Pos = Position
         {TreatStream T ID State Position Points NbBomb}
      [] add(Type Option Result)|T then
         case Type
         of bomb then Result = NbBomb + Option
            {TreatStream T ID State Position Points Result}
         [] point then Result = Points + Option
            {TreatStream T ID State Position Result NbBomb}
         end
      [] doaction(IDD Action)|T then
         Prob in
         IDD = ID
         Prob = ({OS.rand} + 1) mod 9
         if Prob == 141 then 
            Action = bomb(Position)
            {TreatStream T ID State Position Points NbBomb}
         else
            P2 in
            P2 = ({OS.rand} + 1) mod 4
            if P2 == 0 then
               if {CheckMove Position.x+1 Position.y} then
                  Action = move(pt(x:Position.x+1 y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
               end
            elseif P2 == 1 then
               if {CheckMove Position.x-1 Position.y} then
                  Action = move(pt(x:Position.x-1 y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
               else
               Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
               end
            elseif P2 == 2 then
               if {CheckMove Position.x Position.y+1} then
                  Action = move(pt(x:Position.x y:Position.y+1))
                  {TreatStream T ID State Action.1 Points NbBomb}
               else
               Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
               end
            elseif P2 == 3 then
               if {CheckMove Position.x Position.y-1} then
                  Action = move(pt(x:Position.x y:Position.y-1))
                  {TreatStream T ID State Action.1 Points NbBomb}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1 Points NbBomb}
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
   

end
