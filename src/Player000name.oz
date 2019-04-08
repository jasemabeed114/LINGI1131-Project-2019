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

in
   Row = Input.nbRow
   Column = Input.nbColumn


   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players

   fun{StartPlayer ID}
      Stream Port OutputStream
   in
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread State Pos in 
	 {TreatStream OutputStream ID State Positions.1}
      end
      Port
   end

   
   proc{TreatStream Stream ID State Position} %% TODO you may add some arguments if needed
      case Stream 
      of getID(IDD)|T then IDD = ID {TreatStream T ID State Position}
      [] getState(IDD SState)|T then IDD = ID SState = State {TreatStream T ID State Position}
      [] spawn(IDD Pos)|T then
         IDD = ID
         Pos = Position
         {TreatStream T ID State Position}
      [] doaction(IDD Action)|T then
         Prob in
         IDD = ID
         Prob = ({OS.rand} + 1) mod 9
         if Prob == 141 then 
            Action = bomb(Position)
            {TreatStream Stream ID State Position}
         else
            P2 in
            P2 = ({OS.rand} + 1) mod 4
            if P2 == 0 then
               if Position.x+1 < Column then
                  Action = move(pt(x:Position.x+1 y:Position.y))
                  {TreatStream T ID State Action.1}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1}
               end
            elseif P2 == 1 then
               if Position.x-1 > 1 then
                  Action = move(pt(x:Position.x-1 y:Position.y))
                  {TreatStream T ID State Action.1}
               else
               Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1}
               end
            elseif P2 == 2 then
               if Position.y+1 < Row then
                  Action = move(pt(x:Position.x y:Position.y+1))
                  {TreatStream T ID State Action.1}
               else
               Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1}
               end
            elseif P2 == 3 then
               if Position.y-1 > 1 then
                  Action = move(pt(x:Position.x y:Position.y-1))
                  {TreatStream T ID State Action.1}
               else
                  Action = move(pt(x:Position.x y:Position.y))
                  {TreatStream T ID State Action.1}
               end
            end
         end
      end
   end
   

end
