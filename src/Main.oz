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
   Explode 

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
      thread {TurnByTurn PlayerPorts nil} end
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
   

   proc{TurnByTurn PlayerPortsList Bombs}
      NewBombs
   in
      case PlayerPortsList 
      of nil then {Delay 1000} {TurnByTurn PlayerPorts Bombs}
      [] H|T then ID Move in
         NewBombs = {Explode Bombs}
         {Send H doaction(ID Move)}
         case Move
         of move(Pos) then 
            {Send WindowPort movePlayer(ID Pos)} % Simply move the bomber
         [] bomb(Pos) then 
            {Send WindowPort spawnBomb(Pos)}
            {Delay 1000}
            {TurnByTurn T (Input.timingBomb#Pos)|NewBombs}
         else skip
         end
         {Delay 1000}
         {TurnByTurn T NewBombs}
      end
   end

   fun{Explode L}
      case L of nil then nil
      [] (N#Pos)|T then
         if N == 0 then 
            {Send WindowPort spawnFire(Pos)}
            {Send WindowPort hideBomb(Pos)}
            {Delay 3000}
            {Send WindowPort hideFire(Pos)}
            {Explode T}
         else ((N-1)#Pos)|{Explode T}
         end
      end
   end

end
