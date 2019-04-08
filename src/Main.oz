functor
import
   GUI
   Input
   PlayerManager
define
   WindowPort

   InitPlayers

   NbPlayers
   Positions
   PlayerPorts

in
   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players
   NbPlayers = Input.nbBombers
   thread PlayerPorts = {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions} end

   fun{InitPlayers NbPlayers ColorPlayers NamePlayers PositionPlayers}
      if NbPlayers == 0 then nil
      else
         case ColorPlayers#NamePlayers#PositionPlayers 
         of (ColorH|ColorT)#(NameH|NameT)#(PositionH|PositionT) then 
            ID PlayerPort in
            ID = bomber(id:NbPlayers color:ColorH name:NameH)
            PlayerPort = {PlayerManager.playerGenerator NameH ID}
            {Send WindowPort initPlayer(ID)}
            {Send WindowPort spawnPlayer(ID PositionH)}
            PlayerPort|{InitPlayers NbPlayers-1 ColorT NameT PositionT}
         end
      end
   end




end
