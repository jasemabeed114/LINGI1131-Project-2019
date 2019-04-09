functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   WindowPort

   InitPlayers
   TurnByTurn

   NbPlayers
   Positions
   PlayerPorts
   NColumns
   NRows
   Map


in

   NColumns = Input.nbColumn
   NRows    = Input.nbRow
   Map      = Input.map

   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   NbPlayers = Input.nbBombers

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players

   thread PlayerPorts = {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions} end

   if Input.isTurnByTurn then
      thread {TurnByTurn PlayerPorts} end
   else
      skip %similtane
   end

   fun{InitPlayers NbPlayers ColorPlayers NamePlayers PositionPlayers}
	   if NbPlayers == 0 then nil
	   else
         case ColorPlayers#NamePlayers#PositionPlayers 
	      of (ColorH|ColorT)#(NameH|NameT)#(PositionH|PositionT) then 
	         ID PlayerPort in
	         ID = bomber(id:NbPlayers color:ColorH name:NameH)
            PlayerPort = {PlayerManager.playerGenerator NameH ID}
            {Send PlayerPort assignSpawn(PositionH)}
	         {Send WindowPort initPlayer(ID)}
	         {Send WindowPort spawnPlayer(ID PositionH)}
	         PlayerPort|{InitPlayers NbPlayers-1 ColorT NameT PositionT}
	      end
      end
   end
   

   proc{TurnByTurn PlayerPortsList}
      proc{Mover P}
         ID Move
      in
         {Send P doaction(ID Move)}
         case Move
         of move(Pos) then {Send WindowPort movePlayer(ID Pos)} % Simply move the bomber
         [] bomb(Pos) then {Send WindowPort spawnBomb(Pos)}
         else skip
         end
         {Delay 2000}
      end
   in
      case PlayerPortsList of nil then {TurnByTurn PlayerPorts}
      [] H|T then
         {Mover H}
         {TurnByTurn T}
      end
   end



end
