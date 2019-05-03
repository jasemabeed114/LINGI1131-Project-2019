functor
import
   Player000name
   Player000bomber
   Player100random
   Player100advanced
   Player100JonSnow
   /* 
   USED FOR INTEROP
   Player021IA2
   
   Player005Umberto
   Player105Alice
   Player106noob
   Player010IA
   Player007Zorro
   Player022Immortal
   */
   
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
      [] player100random then {Player100random.portPlayer ID}
      [] player100advanced then {Player100advanced.portPlayer ID}
      [] player100jonSnow then {Player100JonSnow.portPlayer ID}
      
      /* 
      USED FOR INTEROP
      [] corentin then {Player021IA2.portPlayer ID}
      [] brieuc then {Player005Umberto.portPlayer ID}
      [] cyril then {Player105Alice.portPlayer ID}
      [] matthieu then {Player106noob.portPlayer ID}
      [] xavier then {Player010IA.portPlayer ID}
      [] zorro then {Player007Zorro.portPlayer ID}
      [] player022Immortal then {Player022Immortal.portPlayer ID}
      */
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
