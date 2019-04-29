functor
import
   Player000name
   Player000bomber
   Player001random
   Player002advenced
   Player100advanced
   Player021IA2
   Player005Umberto
   Player105Alice
   Player106noob
   Player010IA
   
   %% Add here the name of the functor of a player
   %% Player000name
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind ID}
      case Kind
      of player000bomber then {Player000bomber.portPlayer ID}
      [] player001random then {Player001random.portPlayer ID}
      [] player002advenced then {Player002advenced.portPlayer ID}
      [] player100advanced then {Player100advanced.portPlayer ID}
      [] corentin then {Player021IA2.portPlayer ID}
      [] brieuc then {Player005Umberto.portPlayer ID}
      [] cyril then {Player105Alice.portPlayer ID}
      [] matthieu then {Player106noob.portPlayer ID}
      [] xavier then {Player010IA.portPlayer ID}
      %% Add here the pattern to recognize the name used in the 
      %% input file and launch the portPlayer function from the functor
      [] player000name then {Player000name.portPlayer ID}
      else
         raise 
            unknownedPlayer('Player not recognized by the PlayerManager '#Kind)
         end
      end
   end
end
