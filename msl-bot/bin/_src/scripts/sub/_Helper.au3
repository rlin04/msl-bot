#include-once
#include "../../imports.au3"

#cs
	Function: Returns a 2D array of the location of a specified map
	Parameters:
		- $map: String of the map, case sensitive.
	Return:
		- A 2D array: [x, y]
		*On error or not found, returns -1
	Pre-condition:
		- Global variable, $g_aCoorMaps, should be defined. [[MAP, MARK, X-DISPLACE, Y-DISPLACE], [...], [...]]
#ce
Func getMapCoor($map)
	Local $arrMarks = _getMapMarks() ;[["A", 0, 0], [...], [...]]
	Local $pointDisplacement ;Creates final coordination of map with sum of the mark

	;Returns early if there are no marks found
	If UBound($arrMarks) = 0 Then Return -1

	;Checking if $map exists in $coorMaps
	For $i = 0 To UBound($g_aCoorMaps, $UBOUND_ROWS)-1
		If $g_aCoorMaps[$i][0] = $map Then
			;Checking if the mark exists on $arrMarks.
			For $x = 0 To UBound($arrMarks, $UBOUND_ROWS)-1
				Local $myMark = $arrMarks[$x]

				If $g_aCoorMaps[$i][1] = $myMark[0] Then
                    Local $pointDisplacement = [$g_aCoorMaps[$i][2], $g_aCoorMaps[$i][3]]

					ExitLoop(2)
				Else
					ContinueLoop
				EndIf
			Next
		EndIf
	Next

	;Returns early if $map does not exist or $mark does not exist
	If isArray($pointDisplacement) = False Then Return -2

	Local $finalX = $myMark[1] + $pointDisplacement[0]
	Local $finalY = $myMark[2] + $pointDisplacement[1]

	;Returns early if final coordinations are out of bounds.
	If ($finalX < 0) Or ($finalX > $g_aControlSize[0]) Or ($finalY < 0) Or ($finalY > $g_aControlSize[1]) Then
		Return -3
	EndIf

	;Output
	Local $returnPoint = [$finalX, $finalY]
	Return $returnPoint
EndFunc

#cs
	Function: Helper function for getMapCoor. Retrieves an array of visible marks and their points.
	Return:
		- An array of string and point. [[STRING, X, Y], [...], [...]]
		*Returns empty array if nothing is found.
	Pre-condition:
		- Global variable, $g_aImageMarks, must be defined. [STRING, STRING, ...]
#ce
Func _getMapMarks()
	Local $finalArr[0] ;Empty array for marks.

	;Adding marks that are found in map
	CaptureRegion()
	For $myMark In $g_aImageMarks
		Local $imageCoor = findImage($myMark, 100, 0, Default, Default, Default, Default, False)

		;If image found then it adds a mark into $finalArr
		If isArray($imageCoor) Then
			Local $newMark = [$myMark, $imageCoor[0], $imageCoor[1]]
			_ArrayAdd($finalArr, $newMark, 0, default, default, 1) ;Force as single item
		EndIf
	Next

	;Output
	Return $finalArr
EndFunc

#cs
	Function: Retrieves data of current gem on screen. Works during battle-sell-item location
	Parameters:
		$bCapture: Save unknown gems
	Returns: [grade, shape, type, stat, sub, price]
		- If one of the items are missing then return -1
#ce
Func getGemData($bCapture = True)
	Local $aGemData[6] = ["-", "-", "-", "-", "-", "-"] ;Stores current gem data
	If getLocation() = "battle-sell-item" Then
		Select ;grade
			Case isPixel("399,175,0xF39C72|399,164,0xF769BA|406,144,0x261612")
				$aGemData[0] = "EGG"
				Return $aGemData
			Case isPixel("399,175,0x9A450C|399,164,0xF5D444|406,144,0xFDF953", 20)
				$aGemData[0] = "GOLD"
				Return $aGemData
			Case isPixel("406,144,0x261612")
				$aGemData[0] = 1
			Case isPixel("413,144,0x261612")
				$aGemData[0] = 2
			Case isPixel("418,144,0x261612")
				$aGemData[0] = 3
			Case isPixel("423,144,0x261612")
				$aGemData[0] = 4
			Case isPixel("428,144,0x261714")
				$aGemData[0] = 5
			Case Else
				$aGemData[0] = 6
		EndSelect

		Select ;shape
			Case Not(isPixel("413,159,0x261612"))
				$aGemData[1] = "S"
			Case Not(isPixel("414,168,0x261612"))
				$aGemData[1] = "D"
			Case Else
				$aGemData[1] = "T"
		EndSelect

		For $strType In $g_aGem_pixelTypes ;types
			If isPixelOR(StringSplit($strType, ":", 2)[1], 20) Then
				$aGemData[2] = StringSplit($strType, ":", 2)[0]
				ExitLoop
			EndIf
		Next

		For $strStat In $g_aGem_pixelStats ;main stats
			If isPixelOR(StringSplit($strStat, ":", 2)[1], 20) Then
				$aGemData[3] = StringSplit($strStat, ":", 2)[0]
				ExitLoop
			EndIf
		Next

		If isArray(findColor("350,329", "50,1", "0xE9E3DE", 20)) Then ;number of substats
			$aGemData[4] = "4"
		ElseIf isArray(findColor("350,311", "50,1", "0xE9E3DE", 20)) Then
			$aGemData[4] = "3"
		ElseIf isArray(findColor("350,296", "50,1", "0xE9E3DE", 20)) Then
			$aGemData[4] = "2"
		ElseIf isArray(findColor("350,329", "50,1", "0xE9E3DE", 20)) Then
			$aGemData[4] = "1"
		EndIf

		$aGemData[5] = getGemPrice($aGemData)

		;Handles if gem is unknown
		If (($aGemData[0] = "-") Or ($aGemData[1] = "-") Or ($aGemData[2] = "-") Or ($aGemData[3] = "-") Or ($aGemData[4] = "-")) Then
			$g_sErrorMessage = "getGemPrice() => Something is missing: " & _ArrayToString($aGemData)
			Return -1
		EndIf
	EndIf
	Return $aGemData
EndFunc

#cs
	Function: Returns gem price using the data passed in
	Parameters:
		gemData: [Array] [grade, shape, type, stat, sub]
	Returns: (Int) Gem price
#ce
Func getGemPrice($aGemData)
	Local $iRank = 0

	;Looking if rank exists in g_aGemRanks
	For $i = 0 To UBound($g_aGemRanks)-1
		If StringInStr($g_aGemRanks[$i], $aGemData[2]) = True Then
			$iRank = $i
			ExitLoop
		EndIf
	Next

	Local $iSub = 0 ;Formatting sub for index
	Switch $aGemData[4]
		Case 4
			$iSub = 0
		Case 3
			$iSub = 1
		Case 2
			$iSub = 2
	EndSwitch

	;Gem prices are location in 3 different arrays organized in ranks. Refer to Global variables.
	Return Int(Execute("$g_aGemGrade" & $aGemData[0] & "Price[" & $iSub & "][" & $iRank & "]"))
EndFunc

#cs
	Function: Filters gems that do not meet the criteria
	Parameters:
		$aGemData: Gem data. Refer to getGemData() function.
		$aFilter: format=[[4*-Filter, ""], [4*-Types, ""], [4*-Stats, ""], [4*-Substats, ""], ...]
	Returns:
		If the gem meets the criteria returns true; otherwise, returns false.
#ce
Func filterGem($aGemData, $aFilter = formatArgs(getScriptData($g_aScripts, "_Filter")[2]))
	Local $iGrade = $aGemData[0]
	If getArg($aFilter, $iGrade & "*-Filter") = "Disabled" Then Return False

	If StringInStr(getArg($aFilter, $iGrade & "*-Types"), $aGemData[2]) = False Then Return False
	If StringInStr(getArg($aFilter, $iGrade & "*-Stats"), $aGemData[3]) = False Then Return False
	If StringInStr(getArg($aFilter, $iGrade & "*-Substats"), $aGemData[4]) = False Then Return False

	Return True
EndFunc

#cs
	Function: Puts gem data into readable string.
	Parameters:
		$aGemData: Gem data. Refer to function: getGemData()
	Returns: Ex. 4*	Triangle Intuition %Atk
#ce
Func stringGem($aGemData)
	Local $sShape = "[Shape]"
	Switch $aGemData[1]
	Case "S"
		$sShape = "Square"
	Case "T"
		$sShape = "Triangle"
	Case "D"
		$sShape = "Diamond"
	EndSwitch

	Local $sType = "[Type]"
	$sType = _StringProper($aGemData[2])

	Local $sStat = "[Stat]"
	If StringInStr($aGemData[3], ".") = True Then
		Local $t_aSplit = StringSplit($aGemData[3], ".", $STR_NOCOUNT)

		$sStat = "+"
		If $t_aSplit[0] = "P" Then $sStat = "%"

		$sStat &= _StringProper($t_aSplit[1])
	Else
		$sStat = _StringProper($aGemData[3])
	EndIf

	Local $sSub = "[Substat]"
	$sSub = $aGemData[4] & " Substat"
	If $aGemData[4] > 1 Then $sSub &= "s"

	Return $aGemData[0] & "*; " & $sShape & "; " & $sType & "; " & $sStat & "; " & $sSub
EndFunc

#cs
	Function: Looks for level in map stage selection location.
	Parameters:
		$iLevel: Integer from 1-17.
	Return:
		Array point of where the energy is. -1 on not found.
#ce
Func findLevel($iLevel)
	Local $sLocation = getLocation($g_aLocations, False)
	If $sLocation = "map-stage" Then
		If StringIsDigit($iLevel) = True Then
			If ($iLevel > 0) And ($iLevel < 19) Then
				;Looking for level using findImage
				If $iLevel < 10 Then $iLevel = "0" & $iLevel ;Must be in format ##

				Local $aPoint = findImage("level-n" & $iLevel, 100, 0, 402, 229, 50, 250) ;tolerance 100, rectangle at (402,229) dim. 50x250
				If isArray($aPoint) = False Then Return -1
				;Found point

				$aPoint[0] = 725
				Return $aPoint
			EndIf
		Else
			;usually gold, exp, fruit, or boss
			Local $sLevel = StringLower($iLevel)
			Switch $sLevel
				Case "exp", "fruit", "gold"
					LocaL $t_aPoint = findImage("level-" & $sLevel, 100, 0, 681, 229, 90, 250) ;tolerance 100; rectangle at (681,229) dim. 125x250
					If isArray($t_aPoint) = True Then $t_aPoint[0] = 725

					Return $t_aPoint
				Case "boss"
					;Checks second position if there is boss
					Local $t_hColor = 0x3A2923
					Local $t_aPoint = [535, 469]
					Do
						Local $aBoss = findColor($t_aPoint, "1," & 229-$t_aPoint[1], $t_hColor, 20, 1, -1)
						If isArray($aBoss) = False Then Return False

						If (isPixel($t_aPoint[0] & "," & $t_aPoint[1]-7 & "," & 0x673A2C, 30) = False) And (isPixel($t_aPoint[0] & "," & $t_aPoint[1]-30 & "," & $t_hColor, 20) = True) Then
							Local $aResult = [725, $t_aPoint[1]-30]
							Return $aResult
						Else
							$t_aPoint[1] = findColor($t_aPoint[0] & "," & $t_aPoint[1], "1,-78", 0x673A2C, 30, 1, -1)[1]-13
						EndIf
					Until $t_aPoint[1] <= 229
				Case Else
					CaptureRegion()
					Return findColor("744,270", "1,230", 0xFED328, 20, 1, 1)
			EndSwitch
		EndIf
	EndIf

	Return False
EndFunc

#cs
	Function: Finds an available guardian dungeon based on the current guardian dungeons.
	Parameters:
		$sMode: "left", "right", "both" - Handles the left/right side on the two visible guardian dungeon.
	Return: Points of the energy of the guardian dungeon.
#ce
Func findGuardian($sMode)
	captureRegion()
	If isArray(findColor("386,470", "1,-220", 0xCC0F12, 10, 1, -1)) = False Then Return -1

	$sMode = StringLower(StringStripWS($sMode, $STR_STRIPALL))
	Local $sImagePath = "misc-guardian-" & $sMode
	Local Const $iX = 650

	Switch $sMode
		Case "left", "right"
		Case Else
			Return findColor("678,470", "1,-220", 0xFCD128, 10, 1, -1)
	EndSwitch

	Local $aResult = findImage($sImagePath, 100, 0, 550, 250, 60, 250)
	If isArray($aResult) Then $aResult[0] = $iX

	Return $aResult
EndFunc

#cs
	Function: Retrieves village position and angle.
	Return: Village position from 0-5. 0-2 for first ship, 3-4 for second, and 5-6 for third.
#ce
Func getVillagePos()
	CaptureRegion()

	;Traverse through idShip checking the pixel sets.
	For $i = 0 To UBound($g_aVillagePos)-1
		If isPixelOR($g_aVillagePos[$i], 10) = True Then Return $i
	Next

	;Return -1 if ship not found.
	Return -1
EndFunc

#cs
	Function: Checks if there are still astrochips left, only works if in 'battle' location.
	Returns Codes:
	   -2: Unknown
	   -1: Not in battle
		0: No astrocips
		1: Has astrochips
#ce
Func hasAstrochips()
	If getLocation() <> "battle" Then Return -1
	If isPixelOR("162,509,0x612C22/340,507,0x612C22/513,520,0x612C22/683,520,0x612C22", 10) = True Then
		If isPixel("743,279,0x53100C|746,266,0xBD3229") Then
			Return 0
		Else
			Return 1
		EndIf
	EndIf

	Return -2
EndFunc

#cs
	Function: Gets stone data.
	Returns: Array => [ELEMENT, GRADE, QUANTITY] ex. ["fire", "high", 3]
#ce
Func getStone()
	;Defining variables
	Local $sElement = "", $sGrade = "", $iQuantity = -1

	;Check if egg or gold
	If isPixel("399,175,0xF39C72|399,164,0xF769BA|406,144,0x261612") Then
		Local $t_aData = ["egg", "n/a", "1"]
		Return $t_aData
	ElseIf isPixel("399,175,0x9A450C|399,164,0xF5D444|406,144,0xFDF953", 20) Then
		Local $t_aData = ["gold", "n/a", "n/a"]
		Return $t_aData
	EndIf

	;Getting element and grade
	Local $aElements = ["normal", "water", "wood", "fire", "dark", "light"]
	Local $aGrades = ["low", "mid", "high"]
	For $sCurElement In $aElements
		For $sCurGrade In $aGrades
			If isPixel(getArg($g_aPixels, "stone-" & $sCurElement & "-" & $sCurGrade), 50) Then
				$sElement = $sCurElement
				$sGrade = $sCurGrade

				ExitLoop(2)
			EndIf
		Next
	Next

	If ($sElement = "") Or ($sGrade = "") Then
		$g_ErrorMessage = "getStone() => Could not get Element or Grade"
		Return -1
	EndIf

	;Getting quantity
	CaptureRegion("", 440, 214, 50, 20)
	For $i = 1 To 5
		If isArray(findImage("misc-stone-x" & $i, 100, 0, 440, 214, 50, 20, False)) = True Then
			$iQuantity = $i
			ExitLoop
		EndIf
	Next

	If ($iQuantity = -1) Then
		$g_sErrorMessage = "getStone() => Could not get quantity."
		Return -1
	EndIf

	Local $t_aData = [$sElement, $sGrade, $iQuantity]
	Return $t_aData
EndFunc
