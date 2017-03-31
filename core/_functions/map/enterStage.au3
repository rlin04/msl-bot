#cs ----------------------------------------------------------------------------

 Function: enterStage

 Algorithm for entering a stage in the maps.

 Parameters:

	strImage - Image name of the map.

	strMode - Modes include: normal, hard, extreme

	boolAuto - Boolean for autobattle mode.

 Returns:

	On success - Returns 1

	On fail - Returns 0

#ce ----------------------------------------------------------------------------

Func enterStage($strImage, $strMode = "normal", $boolAuto = False, $boolLog = True)
	If waitLocation("map") = 1 Then
		Local $errorCounter = 0
		Local $strMap = StringReplace(_StringProper(StringReplace($strImage, "-", " ")), "Map ", "")
		If setLogReplace("Entering " & $strMap & "..Searching", 1) Then Return 0

		Dim $imgPoint = findImageWait($strImage, 1, 50)
		While Not isArray($imgPoint)
			If checkLocations("astroleague", "map-stage", "association") = 1 Then ControlSend($hWindow, "", "", "{ESC}")

			If $errorCounter > 50 Then
				Return 0
			EndIf

			ControlSend($hWindow, "", "", "{LEFT}")
			$errorCounter+=1

			If _Sleep(500) Then Return

			_CaptureRegion()
			$imgPoint = findImageFiles($strImage, 100)
		WEnd

		;clicking map list and selecting difficulty
		clickPoint($imgPoint, 1, 2000, False)

		If checkLocations("map-stage") = 0 Then Return 0
		Switch $strMode
			Case "normal" ;Normal
				If setLogReplace("Entering " & $strMap & "..Mode: Normal", 1) Then Return 0
				clickPoint($map_coorMode, 1, 500, False)
				clickPoint($map_coorNormal, 1, 500, False)
			Case "hard" ;Hard
				If setLogReplace("Entering " & $strMap & "..Mode: Hard", 1) Then Return 0
				clickPoint($map_coorMode, 1, 500, False)
				clickPoint($map_coorHard, 1, 500, False)
			Case "extreme" ;Extreme
				If setLogReplace("Entering " & $strMap & "..Mode: Expert", 1) Then Return 0
				clickPoint($map_coorMode, 1, 500, False)
				clickPoint($map_coorExtreme, 1, 500, False)
			Case Else
				If $boolLog Then setLog("Input error: " & $strMode & " not within 1-3 modes.", 1)
				Return 0
		EndSwitch

		;selecting a stage (not yet complete)
		Dim $arrayEnergy = findImageWait("misc-stage-energy", 5, 100)
		If Not isArray($arrayEnergy) Then Return 0

		clickPoint($arrayEnergy)

		;applying autobattle mode
		If $boolAuto = True Then
			clickPointUntil($map_pixelAutoBattle20xUnchecked, "autobattle-prompt", 5)
			clickPointWait($map_coorConfirmAutoBattle, "autobattle-prompt", 5)
		EndIf

		;launching stage
		clickPointUntil($map_coorBattle, "battle", 5)
		If checkLocations("map-gem-full", "battle-gem-full") = 1 Then Return 0

		Return waitLocation("battle", 10)
	Else
		Return 0
	EndIf
EndFunc