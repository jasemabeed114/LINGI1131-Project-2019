# ----------------------------
# group nb XXX
# noma1 : Louis Navarre
# 20181600 : Edgar Gevorgyan
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here

all: compile input run

input: Input.oz
		/Applications/Mozart2.app/Contents/Resources/bin/ozc -c Input.oz
compile: PlayerManager.oz compilePlayers GUI.oz Main.oz
		/Applications/Mozart2.app/Contents/Resources/bin/ozc -c PlayerManager.oz GUI.oz Main.oz

compilePlayers: Player000name.oz
		/Applications/Mozart2.app/Contents/Resources/bin/ozc -c Player000name.oz

run: Main.ozf
		/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

clean:
		rm -rf Player000name.ozf
		rm -rf Input.ozf
		rm -rf PlayerManager.ozf
		rm -rf GUI.ozf
		rm -rf Main.ozf