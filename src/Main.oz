functor
import
   GUI
   Input
   PlayerManager
define
   WindowPort

   PlayerOnePort
   ID1
   Pos1

in
   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   %% A terme, faudra faire une fonction qui le fait pour chaque Input.nbBombers
   ID1 = bomber(id:1 color:yellow name:player000name) % Creation du bomber
   Pos1 = pt(x:2 y:2) % Position initiale du bomber
   PlayerOnePort = {PlayerManager.playerGenerator player000bomber ID1} % Creation du port du joueur pour les informations
   {Send WindowPort initPlayer(ID1)} % Indique au GUI l'apparation du nouveau joueur
   {Send WindowPort spawnPlayer(ID1 Pos1)} % Affiche le nouveau joueur

end
