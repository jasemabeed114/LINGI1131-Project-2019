functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   WindowPort

   InitPlayers
   InitMove

   NbPlayers
   Positions
   PlayerPorts


in
   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   NbPlayers = Input.nbBombers
   thread PlayerPorts = {InitPlayers NbPlayers Input.colorsBombers Input.bombers} end

   thread {InitMove PlayerPorts} end

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

   proc{InitMove PlayerPorts}
      proc{Mover P}
         ID Move
      in
         {Send P doaction(ID Move)}
         {Send WindowPort movePlayer(ID Move.1)} % Simply move the bomber
         {Delay 2000}
         {Mover P}
      end
   in
      case PlayerPorts of nil then skip
      [] H|T then
         thread {Mover H} end
         {InitMove T}
      end
   end






end
