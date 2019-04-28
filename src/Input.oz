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

   Map1 Map2 MapTests
in 


%%%% Style of game %%%%
   
   IsTurnByTurn = false
   UseExtention = true %set to false for interop
   PrintOK = true


%%%% Description of the map %%%%
   
   NbRow = 7
   NbColumn = 13

   Map = Map1

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
   
   MapTests = [[1 1 1 1 1]
               [1 4 1 2 1]
               [1 0 1 4 1]
               [1 1 1 1 1]]

%%%% Players description %%%%

   NbBombers = 2
   Bombers = [player100advanced player100advanced]
   ColorBombers = [yellow red]

%%%% Parameters %%%%

   NbLives = 5
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 2000 % in millisecond
   
   Fire = 2
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

end
