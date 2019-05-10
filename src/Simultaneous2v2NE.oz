functor
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
in 

/*
 THIS FILE IS USED FOR THE DEMONSTRATION
 SIMULTANEOUS, 2 PLAYERS: RANDOM AND ADVANCED FROM THE MANDATORY
 */


%%%% Style of game %%%%
   
   IsTurnByTurn = false
   UseExtention = false %set to false for interop
   PrintOK = false


%%%% Description of the map %%%%
   
   NbRow = 7
   NbColumn = 13

   Map = Map1

   %NbRow = 4
   %NbColumn = 5

   %Map = MapTests

   Map1 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 3 2 2 2 2 2 3 0 4 1]
	  [1 0 1 3 1 2 1 2 1 2 1 0 1]
	  [1 3 2 2 3 2 2 2 2 3 2 3 1]
	  [1 0 1 2 1 2 1 3 1 2 1 0 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

   Map2 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 1 0 0 0 0 0 1 0 4 1]
	  [1 0 1 0 0 0 0 0 0 1 2 2 1]
	  [1 0 1 0 0 0 0 0 0 1 1 3 1]
	  [1 0 1 0 0 0 0 0 0 1 1 0 1]
	  [1 4 0 1 0 0 0 0 0 1 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

   Map3 = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 0 0 0 0 0 0 0 0 4 1]
	  [1 0 0 0 0 0 0 0 0 0 1 0 1]
	  [1 0 0 0 0 0 0 0 0 0 0 0 1]
	  [1 0 0 0 0 0 0 0 2 0 0 0 1]
	  [1 4 0 2 0 0 0 0 0 0 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]
   
   MapTests = [[1 1 1 1 1]
               [1 4 1 1 1]
               [1 0 1 1 1]
               [1 1 1 1 1]]

   MapOZ = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 2 3 0 1 3 2 3 2 4 1]
	  [1 0 2 0 0 2 0 0 0 0 2 0 1]
	  [1 0 2 0 0 3 1 0 0 2 0 0 1]
	  [1 0 3 0 0 2 0 0 3 0 0 0 1]
	  [1 4 0 2 3 0 1 2 2 3 2 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

%%%% Players description %%%%

   NbBombers = 2
   Bombers = [player100advanced player100random]
   ColorBombers = [yellow red]

%%%% Parameters %%%%

   NbLives = 5
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 1500 % in millisecond
   
   Fire = 2
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

end
