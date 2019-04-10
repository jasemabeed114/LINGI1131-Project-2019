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
   PropagateFire
   CheckMove
   CleanFire

   NbPlayers
   Positions
   PlayerPorts
   NbColumn
   NbRow
   Map


in

   NbColumn = Input.nbColumn
   NbRow    = Input.nbRow
   Map      = Input.map

   %% Implement your controller here
   WindowPort = {GUI.portWindow} % Cree le port pour la window
   {Send WindowPort buildWindow} % Envoie la commande pour creer la window

   NbPlayers = Input.nbBombers

   Positions = [pt(x:2 y:2) pt(x:12 y:6) pt(x:6 y:2) pt(x:3 y:4)] % Up to 4 players

   thread PlayerPorts = {InitPlayers NbPlayers Input.colorsBombers Input.bombers Positions} end
   if Input.isTurnByTurn then
      thread {TurnByTurn PlayerPorts nil nil} end
   else
      skip %simultane
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
   

   proc{TurnByTurn PlayerPortsList Bombs Fires}
      NewBombs
      NewFires
   in
      {Delay 500}
      case PlayerPortsList 
      of nil then {TurnByTurn PlayerPorts Bombs Fires}
      [] H|T then ID Move PortFire ListFire in
         {CleanFire Fires}
         PortFire = {NewPort ListFire}
         NewBombs = {Explode Bombs PortFire}
         {Send PortFire nil}
         {Send H doaction(ID Move)}
         case Move
         of move(Pos) then 
            {Send WindowPort movePlayer(ID Pos)} % Simply move the bomber
            {TurnByTurn T NewBombs ListFire}
         [] bomb(Pos) then 
            {Send WindowPort spawnBomb(Pos)}
            {TurnByTurn T (Input.timingBomb#Pos#H)|NewBombs ListFire}
         [] null then 
            {TurnByTurn T NewBombs ListFire}
         else {Browser.browse Move}
         end
      end
   end

   fun{Explode L PortFire}
      case L of nil then nil
      [] (N#Pos#PortPlayer)|T then
         if N == 0 then Result in
            {Send WindowPort hideBomb(Pos)}
            {Send PortPlayer add(bomb 1 Result)}
            {PropagateFire Pos PortFire}
            {Explode T PortFire}
         else ((N-1)#Pos#PortPlayer)|{Explode T PortFire}
         end
      end
   end

   proc{CleanFire Fire}
      case Fire of nil then skip
      [] nil|_ then skip
      [] Pos|T then
         {Send WindowPort hideFire(Pos)}
         {CleanFire T}
      end
   end

   %% For the time being, we suppose the fire propagates instantly
   %% So the only thing we have to do is to propagate the fire in the four directions
   %% Showing each time to the window the fire
   %% Start: calls the inner function for the 4 direction
   %% Each direction will see if it can show the fire, and call itself
   %% to the next block
   %%
   %% Still have to take care of the fire to stop
   %% Idea: all the calls to PropagagionInOneDirection will send to a special port
   %% To tell which positions must have the fire to stop ?
   proc{PropagateFire Position PortFire}
      proc{PropagationInOneDirection CurrentPosition PreviousPosition}
         case CurrentPosition of pt(x:X y:Y) then
            if {CheckMove X Y} == false then skip
            else
               {Send WindowPort spawnFire(CurrentPosition)}
               %% HERE CHECK FOR DEATH
               case PreviousPosition of pt(x:XP y:YP) then
                  XF YF in
                  XF = X + (X-XP)
                  YF = Y + (Y-YP)
                  {Send PortFire CurrentPosition}
                  {PropagationInOneDirection pt(x:XF y:YF) CurrentPosition}
               end
            end
         end
      end
   in
      {Send WindowPort spawnFire(Position)}
      {Send PortFire Position}
      case Position of pt(x:X y:Y) then C1 C2 C3 C4 CT in
         thread {PropagationInOneDirection pt(x:X+1 y:Y) Position} C1=1 end
         thread {PropagationInOneDirection pt(x:X-1 y:Y) Position} C2=2 end
         thread {PropagationInOneDirection pt(x:X y:Y+1) Position} C3=3 end
         thread {PropagationInOneDirection pt(x:X y:Y-1) Position} C4=4 end
         CT = C1+C2+C3+C4 %% Wait for the threads to terminate
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
      if (X >= 1 andthen X < NbColumn+1 andthen Y >= 1 andthen Y < NbRow+1 andthen {CheckMap X Y})
      then true
      else false
      end
   end
end