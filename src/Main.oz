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
   GetMapVal
   SetMapVal
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
      {Delay 250}
      case PlayerPortsList 
      of nil then 
         % Start again the loop
         {TurnByTurn PlayerPorts Bombs Fires}

      % Process the next player
      [] H|T then
         ID State in
         % Get the Id and state
         {Send H getState(ID State)}
         % If the player is still on the board
         if State == on then
            Move PortFire ListFire in
            % Clean fire from previous turn
            thread {CleanFire Fires} end

            % Create the new local port to collect the fire blocks
            PortFire = {NewPort ListFire}
            % Check if bombs have to explode
            % If yes, then the fire will propagate
            NewBombs = {Explode Bombs PortFire}
            % To finish the sequence
            {Send PortFire nil}

            % Ask the player to do its next action
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
         else {TurnByTurn T Bombs Fires}
         end
      end
   end

   fun{Explode L PortFire}
      proc{InformOtherPlayer PlayerPortsList Pos}
         case PlayerPortsList of nil then skip
         [] H|T then ID State in
            {Send H info(bombExploded(Pos))}
            {Send H getState(ID State)}
            if State == off then IDD Result in
               {Send WindowPort hidePlayer(ID)}
               {Send H gotHit(IDD Result)}
               {Send WindowPort lifeUpdate(IDD Result.1)}
            end
            {InformOtherPlayer T Pos}
         end
      end
   in
      case L of nil then nil
      [] (N#Pos#PortPlayer)|T then
         if N == 0 then Result in
            {Send WindowPort hideBomb(Pos)}
            {Send PortPlayer add(bomb 1 Result)}
            {PropagateFire Pos PortFire}
            %{InformOtherPlayer PlayerPorts Pos}
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
      proc{ProcessDeath PlayerPort Position}
         case PlayerPort of nil then skip
         [] H|T then ID Result Pos in
            {Send H position(Pos)}
            if Pos == Position then % Got hit
               {Send H gotHit(ID Result)}
               case Result of death(NewLife) then % Was on the map and no shield
                  if NewLife > 0 then
                     ID2 Spawn in
                     {Send H spawn(ID2 Spawn)}
                     {Send WindowPort movePlayer(ID2 Spawn)}
                     {Send WindowPort lifeUpdate(ID2 NewLife)}
                  else % No more life
                     {Send WindowPort hidePlayer(ID)}
                  end
               else % Was off or had a shield
                  {ProcessDeath T Position}
               end
            else
               {ProcessDeath T Position}
            end
         end
      end
                  
      proc{PropagationInOneDirection CurrentPosition PreviousPosition Count}
         if Count >= Input.fire then skip
         else
            case CurrentPosition of pt(x:X y:Y) then
               if {CheckMove X Y} == false then skip
               else
                  {Send WindowPort spawnFire(CurrentPosition)}
                  {ProcessDeath PlayerPorts CurrentPosition}
                  case PreviousPosition of pt(x:XP y:YP) then
                     XF YF in
                     XF = X + (X-XP)
                     YF = Y + (Y-YP)
                     {Send PortFire CurrentPosition}
                     {PropagationInOneDirection pt(x:XF y:YF) CurrentPosition Count+1}
                  end
               end
            end
         end
      end
   in
      {Send WindowPort spawnFire(Position)}
      {Send PortFire Position}
      {ProcessDeath PlayerPorts Position}
      case Position of pt(x:X y:Y) then C1 C2 C3 C4 CT in
         thread {PropagationInOneDirection pt(x:X+1 y:Y) Position 0} C1=1 end
         thread {PropagationInOneDirection pt(x:X-1 y:Y) Position 0} C2=2 end
         thread {PropagationInOneDirection pt(x:X y:Y+1) Position 0} C3=3 end
         thread {PropagationInOneDirection pt(x:X y:Y-1) Position 0} C4=4 end
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

   fun{GetMapVal X Y}
      fun{Nth L N}
         if N == 1 then L.1
         else {Nth L.2 N-1}
         end
      end
      List
   in
      if X > Input.nbColumn or X < 1 then 'dimension error'
      elseif Y > Input.nbRow or Y < 1 then 'dimension error'
      else
         List = {Nth Map Y}
         {Nth List X}
      end
   end

   fun{SetMapVal X Y A}
      fun{Modif L N A}
         case L of nil then error
         [] H|T then
	         if N==1 then A|T
	         else H|{Modif T N-1 A}
	         end
         end
      end
   in
      case Map of nil then nil
      [] H|T then
         if Y == 1 then
	         {Modif H X A}|T
         else
	         H|{SetMapVal T X Y-1 A}
         end
      end
   end
end