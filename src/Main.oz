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
   thread PlayerPorts = {InitPlayers NbPlayers Input.colorsBombers Input.bombers} end

   thread {TurnByTurn PlayerPorts} end

   fun{InitPlayers NbPlayers ColorPlayers NamePlayers}
      if NbPlayers == 0 then nil
      else
         case ColorPlayers#NamePlayers 
         of (ColorH|ColorT)#(NameH|NameT) then 
            ID PlayerPort InitPosition IDD in
            ID = bomber(id:NbPlayers color:ColorH name:NameH)
            PlayerPort = {PlayerManager.playerGenerator NameH ID}
            {Send PlayerPort spawn(IDD InitPosition)}
            {Send WindowPort initPlayer(ID)}
            {Send WindowPort spawnPlayer(ID InitPosition)}
            PlayerPort|{InitPlayers NbPlayers-1 ColorT NameT}
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
         else skip
         end
         {Delay 500}
      end
   in
      case PlayerPortsList of nil then {TurnByTurn PlayerPorts}
      [] H|T then
         {Mover H}
         {TurnByTurn T}
      end
   end



end
