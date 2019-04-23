# ----------------------------
# group nb XXX
# noma1 : Louis Navarre
# 20181600 : Edgar Gevorgyan
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here
COMPILE = /Applications/Mozart2.app/Contents/Resources/bin/ozc -c
EXECUTE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine

all: compile input run

input: Input.oz
		${COMPILE} Input.oz
compile: PlayerManager.oz compilePlayers GUI.oz Main.oz
		${COMPILE} PlayerManager.oz GUI.oz Main.oz

%.ozf: %.oz
		${COMPILE} $<

compilePlayers: Player000name.oz Player001random.oz Player333advenced.oz
		${COMPILE} Player000name.oz Player001random.oz Player333advenced.oz

run: Main.ozf
		${EXECUTE} Main.ozf

clean:
		rm -rf Player000name.ozf
		rm -rf Player001random.ozf
		rm -rf Input.ozf
		rm -rf PlayerManager.ozf
		rm -rf GUI.ozf
		rm -rf Main.ozf