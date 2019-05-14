functor
import
   System
export
   isTurnByTurn:IsTurnByTurn
   useExtention:UseExtention
   printOK:PrintOK
   nbRow:NbRow
   nbColumn:NbColumn
   map:Map
   nbBombers:NbBombers
   bombers:Bombers
   colorsBombers:ColorBombers
   nbLives:NbLives
   nbBombs:NbBombs
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   fire:Fire
   timingBomb:TimingBomb
   timingBombMin:TimingBombMin
   timingBombMax:TimingBombMax
define
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map
   NbBombers Bombers ColorBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire

   Map1 Map2 Map3 MapTests MapOZ
   Map01 Map23
   Demo
in 

/*
 Values for Demo:
  - 0: Turn by turn, 2 players: random and advanced. No extensions
  - 1: Simultaneous, 2 players: random and advanced. No extensions
  - 2: Turn by turn, 5 players: random, advanced and jon Snow. No extensions
  - 3: Simultaneous, 5 players: random, advanced and jon Snow. No extensions
  - 4: Turn by turn, 4 players: jonSnow and 3 other players from other groups
 */

   Demo = 5

   PrintOK = false

   % All the maps

   Map01 = [[1 1 1 1 1 1 1]
            [1 2 0 2 0 4 1]
            [1 0 2 3 2 0 1]
            [1 2 3 1 3 2 1]
            [1 0 2 3 2 0 1]
            [1 4 0 2 0 2 1]
            [1 1 1 1 1 1 1]]
            
   Map23 = [[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
            [1 1 1 4 0 0 0 2 0 2 0 0 0 4 1]
            [1 4 1 1 0 0 0 2 0 2 0 0 2 0 1]
            [1 0 0 2 2 0 0 2 0 2 0 0 0 0 1]
            [1 0 0 0 2 2 3 2 3 2 2 2 2 2 1]
            [1 0 0 0 3 2 2 2 2 3 0 3 3 0 1]
            [1 2 2 2 2 2 3 1 3 2 2 2 2 2 1]
            [1 0 3 3 0 2 1 1 1 2 0 3 3 0 1]
            [1 2 2 2 2 2 3 1 3 2 2 2 1 1 1]
            [1 0 3 3 0 3 2 2 2 2 2 2 3 3 1]
            [1 2 2 2 2 2 0 2 0 0 2 1 3 3 1]
            [1 0 0 0 0 2 0 2 0 0 0 1 3 3 1]
            [1 0 2 0 0 2 0 2 0 0 2 0 1 3 1]
            [1 4 0 0 0 2 0 2 0 0 0 0 4 1 1]
            [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   %%%%%%
   %%%%%%

   Map1 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 3 2 2 2 2 2 3 0 4 1]
	  [1 0 1 3 1 2 1 2 1 2 1 0 1]
	  [1 3 2 2 3 2 2 2 2 3 2 3 1]
	  [1 0 1 2 1 2 1 3 1 2 1 0 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   Map2 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]%%
	  [1 4 0 1 0 0 0 0 0 1 0 4 1]      %%
	  [1 0 1 0 0 0 0 0 0 1 2 2 1]      %%
	  [1 0 1 0 0 0 0 0 0 1 1 3 1]      %%
	  [1 0 1 0 0 0 0 0 0 1 1 0 1]      %%
	  [1 4 0 1 0 0 0 0 0 1 0 4 1]      %%
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]     %%
                                      %%
   Map3 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]%%
	  [1 4 0 0 0 0 0 0 0 0 0 4 1]      %%
	  [1 0 0 0 0 0 0 0 0 0 1 0 1]      %%
	  [1 0 0 0 0 0 0 0 0 0 0 0 1]      %%
	  [1 0 0 0 0 0 0 0 2 0 0 0 1]      %%
	  [1 4 0 2 0 0 0 0 0 0 0 4 1]      %%
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]     %%
                                      %%
   MapTests = [[1 1 1 1 1]            %%
               [1 4 1 1 1]            %%
               [1 0 1 1 1]            %%
               [1 1 1 1 1]]           %%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   MapOZ = [[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
     [1 4 0 2 2 2 2 2 2 2 2 2 2 2 0 4 1]
	  [1 0 2 2 0 3 3 0 1 3 3 3 3 2 2 0 1]
	  [1 0 2 2 3 0 0 3 0 0 0 0 3 2 2 0 1]
	  [1 2 3 2 3 0 0 3 1 0 0 3 0 2 3 2 1]
	  [1 0 2 2 3 0 0 3 0 0 3 0 0 2 2 0 1]
	  [1 0 2 2 0 3 3 0 1 3 3 3 3 2 2 0 1]
     [1 4 0 2 2 2 2 2 2 2 2 2 2 2 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]

%%%% Players description %%%%

   /*
   NbBombers = 3
   Bombers = [player100advanced player100jonSnow player100random]
   ColorBombers = [yellow red green]
   */

%%%% Parameters %%%%

   % These parameters stay the same all along

   NbLives = 5
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 1500 % in millisecond
   
   Fire = 2
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

   case Demo
   of 0 then % Turn by turn, 2 players: random and advanced. No extensions
      IsTurnByTurn = true
      UseExtention = false

      NbBombers = 2
      Bombers = [player100advanced player100random]
      ColorBombers = [yellow red]

      Map = Map01
      NbRow = 7
      NbColumn = 7
   [] 1 then % Simultaneous, 2 players: random and advanced. No extensions
      IsTurnByTurn = false
      UseExtention = false

      NbBombers = 2
      Bombers = [player100advanced player100random]
      ColorBombers = [yellow red]

      Map = Map01
      NbRow = 7
      NbColumn = 7
   [] 2 then % Turn by turn, 5 players: random, advanced and jon Snow. No extensions
      IsTurnByTurn = true
      UseExtention = false

      NbBombers = 5
      Bombers = [player100jonSnow player100advanced player100random player100jonSnow player100advanced]
      ColorBombers = [yellow red blue black green]

      Map = Map23
      NbRow = 15
      NbColumn = 15
   [] 3 then % Simultaneous, 5 players: random, advanced and jon Snow. No extensions
      IsTurnByTurn = false
      UseExtention = false

      NbBombers = 5
      Bombers = [player100jonSnow player100advanced player100random player100jonSnow player100advanced]
      ColorBombers = [yellow red blue black green]

      Map = Map23
      NbRow = 15
      NbColumn = 15
   [] 4 then % Turn by turn, 4 players: jonSnow and 3 other players from other groups
      IsTurnByTurn = true
      UseExtention = false

      NbBombers = 4
      Bombers = [player100jonSnow brieuc cyril corentin]
      ColorBombers = [black red green blue]

      Map = Map1
      NbRow = 7
      NbColumn = 13
   [] 5 then % Last
      IsTurnByTurn = true
      UseExtention = true

      NbBombers = 3
      Bombers = [player100advanced player100random player100jonSnow]
      ColorBombers = [yellow red blue]

      Map = MapOZ
      NbRow = 9
	   NbColumn = 17
   else
      {System.show 'Enter a valid value.'}
   end

end
