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
   CheckMoveFire
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
      thread {TurnByTurn PlayerPorts nil nil Map Positions nil} end
   else
      skip %simultane
   end

   fun{InitPlayers NbPlayers ColorPlayers NamePlayers PositionPlayers}
	   if NbPlayers == 0 then nil
	   else
         case ColorPlayers#NamePlayers#PositionPlayers 
	      of (ColorH|ColorT)#(NameH|NameT)#(PositionH|PositionT) then 
	         ID PlayerPort Position IDS in
	         ID = bomber(id:NbPlayers color:ColorH name:NameH)
            PlayerPort = {PlayerManager.playerGenerator NameH ID}
            {Send PlayerPort assignSpawn(PositionH)}
            {Send PlayerPort spawn(IDS Position)}
	         {Send WindowPort initPlayer(ID)}
	         {Send WindowPort spawnPlayer(ID PositionH)}
	         PlayerPort|{InitPlayers NbPlayers-1 ColorT NameT PositionT}
	      end
      end
   end
   

   proc{TurnByTurn PlayerPortsList Bombs Fires Map PlayerPositionsRest PlayerPositionsHead}
      NewBombs
      NewFires
   in
      {Delay 250}
      case PlayerPortsList 
      of nil then 
         % Start again the loop
         {TurnByTurn PlayerPorts Bombs Fires Map PlayerPositionsHead nil}

      % Process the next player
      [] H|T then
         ID State in
         % Get the Id and state
         {Send H getState(ID State)}
         % If the player is still on the board
         if State == on then
            Move PortFire ListFire MapExploded in
            % Clean fire from previous turn
            thread {CleanFire Fires} end

            % Create the new local port to collect the fire blocks
            PortFire = {NewPort ListFire}
            % Check if bombs have to explode
            % If yes, then the fire will propagate
            NewBombs = {Explode Bombs PortFire Map MapExploded }
            % To finish the sequence
            {Send PortFire nil}

            % Ask the player to do its next action
            {Send H doaction(ID Move)}
            case Move
            of move(Pos) then 
               {Send WindowPort movePlayer(ID Pos)} % Simply move the bomber
               {TurnByTurn T NewBombs ListFire MapExploded PlayerPositionsRest.2 Pos|PlayerPositionsHead}
            [] bomb(Pos) then 
               {Send WindowPort spawnBomb(Pos)}
               {TurnByTurn T (Input.timingBomb#Pos#H)|NewBombs ListFire MapExploded PlayerPositionsRest.2 PlayerPositionsRest.1|PlayerPositionsHead}
            [] null then 
               {TurnByTurn T NewBombs ListFire MapExploded PlayerPositionsRest.2 PlayerPositionsRest.1|PlayerPositionsHead}
            else {Browser.browse Move}
            end
         else {TurnByTurn T Bombs Fires Map PlayerPositionsRest.2 PlayerPositionsRest.1|PlayerPositionsHead}
         end
      end
   end

   fun{Explode L PortFire MapIn ?MapReturn}
      proc{InformOtherPlayer PlayerPortsList Pos}
         case PlayerPortsList of nil then skip
         [] H|T then ID State in
            {Send H info(bombExploded(Pos))}
            {InformOtherPlayer T Pos}
         end
      end
   in
      case L of nil then MapReturn = MapIn nil
      [] (N#Pos#PortPlayer)|T then
         if N == 0 then Result MapInPropa in
            {Send WindowPort hideBomb(Pos)}
            {Send PortPlayer add(bomb 1 Result)}
            MapInPropa = {PropagateFire Pos PortFire}
            {InformOtherPlayer PlayerPorts Pos}
            {Explode T PortFire MapInPropa MapReturn}
         else MapInPropa in ((N-1)#Pos#PortPlayer)|{Explode T PortFire MapInPropa MapReturn}
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
   fun{PropagateFire Position PortFire PlayersPosition}
      proc{ProcessDeath PlayerPort Position PlayersPosition}
         case PlayerPort#PlayersPosition of nil then skip
         [] (H|T)#(Pos|PosT) then ID Result in
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
                  {ProcessDeath T Position PosT}
               end
            else
               {ProcessDeath T Position PosT}
            end
         end
      end
                  
      fun{PropagationInOneDirection CurrentPosition PreviousPosition Count Map}
         if Count >= Input.fire then Map
         else
            case CurrentPosition of pt(x:X y:Y) then MapReturn Bool in
               Bool = {CheckMoveFire X Y}
               if Bool == false then Map % Wall
               elseif Bool == box then % Box
                  {Send WindowPort hideBox(CurrentPosition)} % Delete Box from screen
                  {Send WindowPort spawnBonus(CurrentPosition)} % Show bonus on screen
                  MapReturn = {SetMapVal Map X Y 12} % Change map value
                  MapReturn % Stop propaging
               elseif Bool == point then % Point
                  {Send WindowPort hideBox(CurrentPosition)} % Delete Box from screen
                  {Send WindowPort spawnPoint(CurrentPosition)} % Show bonus on screen
                  MapReturn = {SetMapVal Map X Y 12} % Change map value
                  MapReturn % Stop propaging
               else % Free place
                  {Send WindowPort spawnFire(CurrentPosition)}
                  {ProcessDeath PlayerPorts CurrentPosition}
                  case PreviousPosition of pt(x:XP y:YP) then
                     XF YF in
                     XF = X + (X-XP)
                     YF = Y + (Y-YP)
                     {Send PortFire CurrentPosition}
                     {PropagationInOneDirection pt(x:XF y:YF) CurrentPosition Count+1 Map}
                  end
               end
            end
         end
      end
   in
      {Send WindowPort spawnFire(Position)}
      {Send PortFire Position}
      {ProcessDeath PlayerPorts Position}
      case Position of pt(x:X y:Y) then Map1 Map2 Map3 Map4 in
         thread 
            Map1 = {PropagationInOneDirection pt(x:X+1 y:Y) Position 0 Map}
            Map2 = {PropagationInOneDirection pt(x:X-1 y:Y) Position 0 Map1}
            Map3 = {PropagationInOneDirection pt(x:X y:Y+1) Position 0 Map2}
            Map4 = {PropagationInOneDirection pt(x:X y:Y-1) Position 0 Map3}
         end
         {Wait Map4}
         Map4
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
      Point
      in
         Point = {Nth {Nth Map Y} X}
         Point \= 1 andthen Point \= 2 andthen Point \= 3
      end
   in
      if (X >= 1 andthen X < NbColumn+1 andthen Y >= 1 andthen Y < NbRow+1 andthen {CheckMap X Y})
      then true
      else false
      end
   end

   fun{CheckMoveFire X Y}
      fun{CheckMap X Y}
         fun{Nth L N}
            if N == 1 then L.1
            else {Nth L.2 N-1}
            end
         end
      Point
      in
         Point = {Nth {Nth Map Y} X}
         if Point == 1 then false
         elseif Point == 2 then point
         elseif Point == 3 then bonus
         else true
         end
      end
   in
      if (X >= 1 andthen X < NbColumn+1 andthen Y >= 1 andthen Y < NbRow+1 andthen {CheckMap X Y}) == true
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
      if X > Input.nbColumn orelse X < 1 then dimError
      elseif Y > Input.nbRow orelse Y < 1 then dimError
      else
         List = {Nth Map Y}
         {Nth List X}
      end
   end

   fun{SetMapVal Map X Y A}
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