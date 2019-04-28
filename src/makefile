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

test: compileTest input run_test

input: Input.oz
		${COMPILE} Input.oz
compile: PlayerManager.oz compilePlayers GUI.oz Main.oz
		${COMPILE} PlayerManager.oz GUI.oz Main.oz

%.ozf: %.oz
		${COMPILE} $<

compilePlayers: Player001random.oz Player100advanced.oz
		${COMPILE} Player001random.oz Player100advanced.oz

run: Main.ozf
		${EXECUTE} Main.ozf

compileTest: PlayerManager.oz compilePlayers GUI.oz Test.oz
		${COMPILE} PlayerManager.oz GUI.oz Test.oz

run_test: Test.ozf
		${EXECUTE} Test.ozf

clean:
		rm -rf Player001random.ozf
		rm -rf Player100advanced.ozf
		rm -rf Input.ozf
		rm -rf PlayerManager.ozf
		rm -rf GUI.ozf
		rm -rf Main.ozf
		rm -rf Test.ozf