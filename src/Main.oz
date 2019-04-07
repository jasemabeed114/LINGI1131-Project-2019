functor
import
   GUI
   Input
   PlayerManager
define
   WindowPort
in
   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window



end
