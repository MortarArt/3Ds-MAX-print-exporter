/*
Usage Notes:

This script is designed for use in conjunction with MakerWare, and currently optimised for use with the Replicator 2.

In order to use the slicing profile that is edited by the script, the user must select it in Makerware at export time. It will be called MaxScriptControlled and it's settings are created when exporting from 3Ds MAX, so changes made afterwards by the user in a text editor will also be valid.
*/
fn CreateIncrementalName InputString =
	(
		FileNeedsIncrement = doesFileExist InputString
		if FileNeedsIncrement == true then
			(
				FilePath = getFilenamePath InputString
				
				if FilePath.count == InputString.count then
					(
						folder = true
						IncrementStart = InputString.count - 4
					)
				else
					(
						folder = false
						IncrementStart = InputString.count - 7
					)
				
				--Removes existing incremental number from InputString
				InputUnderScoreTest = substring InputString IncrementStart 1
				InputIntegerTest = substring InputString (IncrementStart + 1) 3
				InputIntegerTest = InputIntegerTest as integer
				if InputIntegerTest != undefined then
					(
						if (findstring InputUnderScoreTest "_") == 1 then
							(
								if folder == false then (InputString = (substring InputString 1 (IncrementStart - 1)) + (getfilenametype InputString))
								else ((InputString = (substring InputString 1 (IncrementStart - 1)) + "\\")
									FilePath = getFilenamePath InputString)
							)
					)
				
				--Create
				for i = 0 to 999 do
					(
						--Protect creating lower value then original increment
						if InputIntegerTest != undefined then (while (i - 1) < InputIntegerTest do (i = i + 1))
						--if i < InputIntegerTest
						if i < 10 then			(IncNum = "00" + i as string)
						else if i < 100 then	(IncNum = "0" + i as string)
						else							(IncNum = i as string)
						
						if folder == true then (global OutputString = (substring FilePath 1 (FilePath.count - 1)) + "_" + IncNum + "\\")
						else (global OutputString = FilePath + (getfilenamefile InputString) + "_" + IncNum + (getfilenametype InputString))
						
						FileNeedsIncrement = doesFileExist OutputString
						if FileNeedsIncrement == false then (exit)
						
					)
				OutputString
			)
		else
			(
				OutputString = InputString
			)
		OutputString
	)
fn ReadFileLinesAsArray File LimitLines: FilterBy: = --No dependencies
	(
		local NewStream = openfile File mode:"r"
		if NewStream == undefined then #()
		else
			(
				if LimitLines == unsupplied then
					(
						LimitLines = 0
						while not eof NewStream do (readline NewStream;LimitLines += 1)
						seek NewStream 0
					)
				/*if (filePos NewStream != #eof) then*/local NewArray = for i = 1 to LimitLines while not eof NewStream collect 
					(
						local CurrentLine = readline NewStream
						if FilterBy == unsupplied then CurrentLine else (filterstring CurrentLine FilterBy)
					)
				close NewStream
				NewArray
			)
		--NewArray
	)
fn WriteStringAsFile File theString AppendtoFile:false = --No dependencies
	(
		if not AppendtoFile then if doesfileexist file then deletefile file
		local NewStream = if AppendtoFile then openfile File mode:"a" else createfile file
			--createfile file
		--else openfile File mode:"a"
		--if NewStream == undefined then NewStream = openfile File mode:"a"
		if NewStream == undefined then false
		else
			(
				format "%" theString to:NewStream
				close NewStream
				true
			)
	)
fn MakeArrayIntoString TheArray EndLine:"" StringsOnly:true =
	(
		local theString = ""
		for obj in TheArray where 
			(
				if StringsOnly then classof obj == string else 
					(--Can this fail? Is it better to just write 'true'
						obj = obj as string
						classof obj == string
					)
			)
		do TheString += obj + EndLine
		TheString--The Return
	)
--theFile = ReadFileLinesAsArray @"W:\Users\JamesR\My Things\Profiles\MaxScriptControlled\miracle.json"
--for strLines in theFile do format "\n%" strLines
fn findPropByName inFileArray propName = for propINT = 7 to inFileArray.count where findString inFileArray[propINT] ("\"" + propName + "\":") != undefined collect propINT

fn findPropValue inFileArray propName =
	(
		local propLine = inFileArray[(findPropByName inFileArray propName)[1]]
		local filtered = filterString propLine ": ,"
		filtered[filtered.count]
	)
fn changeMakerWareValue inFileArray propName newValue =
	(
		local indexsOfLine = findPropByName inFileArray propName
		for indexOfLine in indexsOfLine do
			(
				local propLine = inFileArray[indexOfLine]
				local filtered = filterString propLine ":,"
				inFileArray[indexOfLine] = filtered[1] + ": " + newValue as string + ","
			)
		--inFileArray
	)


--findPropValue theFile "infilldensity"
	
fn CalculateVolumeOf obj =
	(
		local Volume= 0.0
		local theMesh = snapshotasmesh obj
		local numFaces = theMesh.numfaces
		for i = 1 to numFaces do
			(
				local Face= getFace theMesh i
				local vert2 = getVert theMesh Face.z
				local vert1 = getVert theMesh Face.y
				local vert0 = getVert theMesh Face.x
				local dV = Dot (Cross (vert1 - vert0) (vert2 - vert0)) vert0
				Volume+= dV
			)
		delete theMesh
		Volume /= 6
		Volume
	)
fn getLowestVert ofObj lowestVert:undefined =
	(
		for vertINT = 1 to ofObj.numVerts do
			(
				local currentVert = (polyOp.getVert ofObj vertINT).z
				if lowestVert == undefined then lowestVert = currentVert
				else if currentVert < lowestVert then lowestVert = currentVert
			)
		lowestVert
	)
	
	
struct printerProperties
	(
		name,
		width,
		depth,
		height
	)
struct printerPresets
	(
		printers = #(),
		fn getByName theName = (for printer in printers where printer.name == theName collect printer)[1]
	)
--global declarations:
MakerWareCustomProfile = #()
MakerWareCustomProfileAsString
--substitutestring "d	e	f	g	h	i	j	k	l	m	n	o	p	q	r	s	t	u	v	w	x	y	z" "\t" ""


MasterExporterTool = newRolloutFloater "Print Expoter" 350 520

rollout PrintingCost "Printing Cost"
	(
		
		label lblCosts "Material Profile" align:#left
		dropDownList ddlCosts "" pos:[90,4] width:280 items:#("Strong & Flexible Plastic; $1.40", "Metallic Plastic; $1.75", "Detail Plastic; $2.99", "Frosted Detail Plastic; $2.39", "Steel; $8.00", "Sterling Silver; $20.00", "Brass; $16.00", "Bronze; $16.00", "Elasto Plastic; $1.75", "Full Colour Sandstone; $0.75", "Ceramics; $0.35", "Gold; $600.00", "Castable Wax; $8.00", "Platinum; $1750.00")
		spinner spnCubicCentimeters "Cubic Centimeters" range:[0.0,10000,0.0] across:2
		spinner spnCostPerCubicCM "Cost per CM" range:[0.01, 100000.00, 1.40]
		spinner spnActualCost "Cost USD" range:[0.0,10000000.00,0.0]
		on ddlCosts selected changedTo do
			(
				spnCostPerCubicCM.value = (filterString ddlCosts.selected "$")[2] as float
				spnActualCost.value = spnCubicCentimeters.value * spnCostPerCubicCM.value
			)
		on spnCubicCentimeters changed changedTo do spnActualCost.value = spnCubicCentimeters.value * spnCostPerCubicCM.value
		on spnCostPerCubicCM changed changedTo do spnActualCost.value = spnCubicCentimeters.value * spnCostPerCubicCM.value
		
		fn setVolume ofSpn:spnCubicCentimeters withObjs:#() printerType:unsupplied =
			(
				if printerType != unsupplied then
					(
						local currentPrinterMaxBuildArea = (printerType.width * printerType.depth * printerType.height) / 1000.0
						ofSpn.range[2] = currentPrinterMaxBuildArea
					)
				ofSpn.value = 0
				for obj in withObjs do ofSpn.value += CalculateVolumeOf obj
				--by units
				if units.SystemType == #Inches then ofSpn.value /= 0.0610237441
				else if units.SystemType == #Feet then ofSpn.value *= 28317
				else if units.SystemType == #Miles then ofSpn.value *= 4.16818e+015
				else if units.SystemType == #Millimeters then ofSpn.value /= 1000
				else if units.SystemType == #Meters then ofSpn.value *= 1000000
				else if units.SystemType == #Kilometers then ofSpn.value *= 1e+15
				ofSpn.value *= units.SystemScale
			)
		


		fn resetVolumeAndCost =
			(
				setVolume withObjs:MasterExporterTool.rollouts[2].ObjectsToPlace printerType:MasterExporterTool.rollouts[2].allKnownPrinters.printers[1]--also do when an object cloned
				spnActualCost.value = spnCubicCentimeters.value * spnCostPerCubicCM.value
			)
		
		on PrintingCost open do resetVolumeAndCost()
	)
rollout MakerWareProfile "MakerWare Settings"
	(
		label lblProfiles "Profile:" align:#left-- across:2
		dropdownlist ddlProfiles "" items:#("Last Used") pos:[70,4] width:260
		--label lblBlank ""
		
		spinner spnrapidMoveFeedRateXY "Travel Rate" range:[1,150,150] across:2
		spinner spnextruderTemp0 "Temperature" range:[0,280,225]
		spinner spnFeedDiameter "Feed Diameter" range:[0.1,4.0,1.75] across:2
		spinner spnFeedStockMultipler "Feed Multiplier" range:[0.1,2.0,0.97]
		checkbox chkDoRaft "Use Raft" checked:false across:4
		checkbox chkDoSupport "Use Support" checked:true
		label lblBlank ""
		spinner spnSupportDensity "Support Density" range:[0.05,1.0,0.12]
		spinner spnInfillDensity "Infill Density" range:[0.01,1.0,0.1] across:2
		spinner spnNumberOfShells "Number of Shells" range:[1,100,2] type:#integer width:80 align:#right
		
		on spnrapidMoveFeedRateXY changed changedTo do changeMakerWareValue MakerWareCustomProfile "rapidMoveFeedRateXY" changedTo
		on spnextruderTemp0 changed changedTo do changeMakerWareValue MakerWareCustomProfile "extruderTemp0" changedTo
		on spnFeedDiameter changed changedTo do changeMakerWareValue MakerWareCustomProfile "feedDiameter" changedTo
		on spnFeedStockMultipler changed changedTo do changeMakerWareValue MakerWareCustomProfile "feedstockMultiplier" changedTo
		on chkDoRaft changed changedTo do changeMakerWareValue MakerWareCustomProfile "doRaft" changedTo
		on chkDoSupport changed changedTo do changeMakerWareValue MakerWareCustomProfile "doSupport" changedTo
		on spnSupportDensity changed changedTo do changeMakerWareValue MakerWareCustomProfile "supportDensity" changedTo
		on spnInfillDensity changed changedTo do changeMakerWareValue MakerWareCustomProfile "infillDensity" changedTo
		on spnNumberOfShells changed changedTo do changeMakerWareValue MakerWareCustomProfile "numberOfShells" changedTo	
		
		on MakerWareProfile open do
			(
				if MakerWareCustomProfile.count > 0 then
					(
						spnrapidMoveFeedRateXY.value = (findPropValue MakerWareCustomProfile "rapidMoveFeedRateXY") as float
						spnextruderTemp0.value = (findPropValue MakerWareCustomProfile "extruderTemp0") as float
						spnFeedDiameter.value = (findPropValue MakerWareCustomProfile "feedDiameter") as float
						spnFeedStockMultipler.value = (findPropValue MakerWareCustomProfile "feedstockMultiplier") as float
						chkDoRaft.checked = if findPropValue MakerWareCustomProfile "doRaft" == "true" then true else false
						chkDoSupport.checked = if findPropValue MakerWareCustomProfile "doSupport" == "true" then true else false
						spnSupportDensity.value = (findPropValue MakerWareCustomProfile "supportDensity") as float
						spnInfillDensity.value = (findPropValue MakerWareCustomProfile "infillDensity") as float
						spnNumberOfShells.value = (findPropValue MakerWareCustomProfile "numberOfShells") as float
					)
			)
	)
rollout affectObjects "Place Objects"
	(
		checkbutton btnAddBrim "Add Brim" across:2 enabled:false
		spinner spnBrimOffset "Offset" range:[0.1, 100.0,1.5]
		button btnAddHelperDisk "Add Helper Disk" across:2 enabled:false
		spinner spnRadius "Radius" range:[0.1,100.0,3.0]
		button btnPackObjects "Pack Objects" across:2 enabled:false
		spinner spnSpacing "Spacing" range:[0.1,100.0,0.5]
		button btnCloneSelection "Clone Selection" across:2
		button btnPutToZ "Drop to Bed"-- enabled:false
		--checkbox chkDeleteContent "Delete placement meshes" checked:true
		--store placement locations on originals
		on btnPutToZ pressed do for obj in MasterExporterTool.rollouts[2].ObjectsToPlace do obj.pos.z -= getLowestVert Obj
		on btnCloneSelection pressed do 
			(
				local objectsToClone = getCurrentSelection()
				local newNodes = #()
				maxOps.cloneNodes objectsToClone cloneType:#copy newNodes:&newNodes
				--select nnl
				MasterExporterTool.rollouts[2].ObjectsToPlace += newNodes
				MasterExporterTool.rollouts[4].resetVolumeAndCost()
			)
	)
rollout organiseExport "File Settings"
	(
		local allKnownPrinters = printerPresets printers:#(\
				printerProperties name:"replicator2" width:285 depth:153 height:155 --,\ remove comment and add another line for your preferred printer
				)
		
		local placementLayer = LayerManager.getLayerFromName "Placing objects"--creates layer within scene to put exported iterations
		local outputLayer = LayerManager.getLayerFromName "Exported objects"--creates layer within scene to put exported iterations
		local currentPrinter = allKnownPrinters.printers[1]
		local buildBox = Box lengthsegs:1 widthsegs:1 heightsegs:1 length:currentPrinter.depth width:currentPrinter.width height:currentPrinter.height mapcoords:on pos:[0,0,0] boxmode:on isFrozen:on showFrozenInGray:false
		local buildPlate = Plane length:153 width:285 pos:[0,0,0] backfacecull:on xray:on isFrozen:on showFrozenInGray:false
		local FrontIndicator = text size:20 kerning:0 leading:0 pos:[0,-100,0] text:"front"  isFrozen:on showFrozenInGray:false
		local userSelection = getCurrentSelection()
		local userVisible = #()
		local ObjectsToPlace = #()
		local MakerWarePath = @":\Program Files\MakerBot\MakerWare\makerware.exe"
		local DrivesToSearch = "cdefghijklmnopqrstuvwxyz"
		local MakerWareProfileFolder
		
		checkbox chkUseMaxProfile "MaxScript Slicing Profile" checked:false enabled:false
		checkbox chkSendToMakerWare "Load In Makerware" checked:false enabled:false pos:[170,7] 
		button btnMakerwarePath "" width:22 pos:[305,5] tooltip:"Set MakerWare Executable Path"
		
		on btnMakerwarePath pressed do 
			(
				local newMakerWarePath = getOpenFileName filename:MakerWarePath types:"Executable(*.exe)"
				if doesFileExist newMakerWarePath then MakerWarePath = newMakerWarePath
			)
		
		editText edtExportPath "Export Path" pos:[5,31] width:290-- text:maxFilePath
		button btnExportPath "" width:22 pos:[305,31] tooltip:"Set Export File Name"

		editText edtExportName "Export Name" width:210 text:(getFilenameFile maxFileName) pos:[5,58] 
		checkbox chkIncrementalName "Incremental Name" checked:true pos:[225,58]
		checkbox chkOpenFolder "Open target Folder on export" checked:true pos:[5,85]
		
		button btnExport "Export" enabled:false pos:[280,85] 
		on btnExportPath pressed do
			(
				local newExportFile = getSaveFileName filename:(edtExportPath.text + edtExportName.text) types:"SteroLitho(*.stl)"
				edtExportPath.text = getFilenamePath newExportFile
				edtExportName.text = getFilenameFile newExportFile
				btnExport.enabled = makeDir newExportFile
			)

		
		on btnExport pressed do
			(
				if chkOpenFolder.checked then shellLaunch btnExportPath.text ""
				ObjectToExport = box lengthsegs:1 widthsegs:1 heightsegs:1 length:1 width:1 height:1 name:edtExportName.text--creates fresh node for property removal
				convertTo ObjectToExport Editable_Poly--converts fresh node
				polyop.deleteFaces ObjectToExport #{1..ObjectToExport.numFaces}--deletes fresh node's faces
				for obj in ObjectsToPlace do ObjectToExport.EditablePoly.attach (copy obj) ObjectToExport

				--EXPORT portion
				select ObjectToExport
				local theFileName = edtExportPath.text + ObjectToExport.name + ".stl"--defining export file name
				if chkIncrementalName.checked then theFileName = CreateIncrementalName theFileName
				else deleteFile theFileName
				
				--CreateIncrementalName @"W:\proj\misc prints\s-caribiner.stl"
				exportFile theFileName #noPrompt using:STL_Export--actual export line
				--setup makerware profile
				
				if chkSendToMakerWare.checked then
					(
						--setup makerware profile
						MakerWareCustomProfileAsString = MakeArrayIntoString MakerWareCustomProfile EndLine:"\n" StringsOnly:true
						WriteStringAsFile (MakerWareProfileFolder + @"MaxScriptControlled\" + "miracle.json") MakerWareCustomProfileAsString AppendtoFile:false
						
						format "\nExecuting Shell Command; %\nWith argument; %\n" MakerWarePath theFileName
						shellLaunch MakerWarePath ("\"" + theFileName + "\"")
					)
				max select none

				--delete #(buildBox,buildPlate,FrontIndicator)
				/*if chkDeleteContent.checked then */delete ObjectsToPlace
				--destroyDialog organiseExport
			)
		on edtExportPath entered newVar do btnExport.enabled = doesFileExist newVar

		on organiseExport open do
			(
				local folderIcon = #("bip_rsvr_i.bmp", "bip_rsvr_a.bmp", 14, 5, 5, 6, 6, false, true)
				btnMakerwarePath.images = folderIcon
				btnExportPath.images = folderIcon
				--format "\n%" this.parent
				for letterINT = 1 to DrivesToSearch.count where doesFileExist (drivesToSearch[letterINT] + MakerWarePath) do 
					(
						chkSendToMakerWare.enabled = true
						chkSendToMakerWare.checked = true
						MakerWarePath = drivesToSearch[letterINT] + MakerWarePath
						MakerWareProfileFolder = systemTools.getEnvVariable("USERPROFILE") + @"\My Things\Profiles\"
						--@"MaxScriptControlled\"
						if doesFileExist MakerWareProfileFolder then
							(
								if not doesFileExist (MakerWareProfileFolder + @"MaxScriptControlled\") then
									(
										makeDir (MakerWareProfileFolder + @"MaxScriptControlled\")
										for files in getFiles (MakerWareProfileFolder + @"example\*") do 
											(
												local newHome = MakerWareProfileFolder + @"MaxScriptControlled\" + filenameFromPath files
												local success = copyFile files newHome--make profile from template
												format "\nCopying % to % success; %" files newHome success
											)
									)
								chkUseMaxProfile.enabled = true
								chkUseMaxProfile.checked = true
								--getSlicingProperties
									
									
								MakerWareCustomProfile = ReadFileLinesAsArray (MakerWareProfileFolder + @"MaxScriptControlled\" + "miracle.json")
								addRollout MakerWareProfile MasterExporterTool
								--MasterExporterTool.size[2] += MasterExporterTool.rollouts[MasterExporterTool.rollouts.count].height
								
							)
					)
				--@":\Program Files\MakerBot\MakerWare\makerware.exe"
				edtExportPath.text = maxFilePath
				btnExport.enabled = doesFileExist edtExportPath.text
				
				if outputLayer == undefined then outputLayer = LayerManager.newLayerFromName "Exported objects"
				if placementLayer == undefined then placementLayer = LayerManager.newLayerFromName "Placing objects"
				fn resetObj theObj IntoLayer:placementLayer =
					(
						format "\nFlattening; %" theObj.name
						local tempObj = box lengthsegs:1 widthsegs:1 heightsegs:1 length:1 width:1 height:1 name:theObj.name--creates fresh node for property removal
						convertTo tempObj Editable_Poly--converts fresh node
						polyop.deleteFaces tempObj #{1..tempObj.numFaces}--deletes fresh node's faces
						tempObj.EditablePoly.attach (copy theObj) tempObj--adds copy of user selection to fresh node
						ResetTransform tempObj
						ResetScale tempObj
						ResetXForm tempObj
						convertTo tempObj Editable_Poly
						placementLayer.addnode tempObj
						tempObj
					)
				userVisible = for obj in objects where not obj.isHidden collect (hide obj; obj)
				ObjectsToPlace = for obj in userSelection collect resetObj obj
				FrontIndicator.isHidden = buildPlate.isHidden = buildBox.isHidden = false
			)
		on organiseExport close do
			(
				try (delete #(buildBox, buildPlate,FrontIndicator)) catch (format "\nNothing to delete")
			)
	)
addRollout affectObjects MasterExporterTool
--MasterExporterTool.size[2] += MasterExporterTool.rollouts[MasterExporterTool.rollouts.count].height
addRollout organiseExport MasterExporterTool
--MasterExporterTool.size[2] += MasterExporterTool.rollouts[MasterExporterTool.rollouts.count].height
addRollout PrintingCost MasterExporterTool
--MasterExporterTool.size[2] += MasterExporterTool.rollouts[MasterExporterTool.rollouts.count].height