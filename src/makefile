# ----------------------------
# group nb 100
# 1235-16-00 : Louis Navarre
# 2018-16-00 : Edgar Gevorgyan
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here
#COMPILE = /Applications/Mozart2.app/Contents/Resources/bin/ozc -c
#EXECUTE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine

COMPILE = ozc -c
EXECUTE = ozengine

all: compile input run

test: compileTest input run_test

input: Input.oz
		${COMPILE} Input.oz
compile: PlayerManager.oz compilePlayers GUI.oz Main.oz
		${COMPILE} PlayerManager.oz GUI.oz Main.oz

%.ozf: %.oz
		${COMPILE} $<

compilePlayers: Player100random.oz Player100advanced.oz Player100JonSnow.oz
		${COMPILE} Player100random.oz Player100advanced.oz Player100JonSnow.oz

run: Main.ozf
		${EXECUTE} Main.ozf

compileTest: PlayerManager.oz compilePlayers GUI.oz Test.oz
		${COMPILE} PlayerManager.oz GUI.oz Test.oz

run_test: Test.ozf
		${EXECUTE} Test.ozf

clean:
		rm -rf Player100random.ozf
		rm -rf Player100advanced.ozf
		rm -rf Player100JonSnow.ozf
		rm -rf Input.ozf
		rm -rf PlayerManager.ozf
		rm -rf GUI.ozf
		rm -rf Main.ozf
		rm -rf Test.ozf