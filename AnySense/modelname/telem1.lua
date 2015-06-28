------------------------------------------------------
--  09.05.2015										--
--  Telemetry script for FrSky Taranis				--
--  created by Frostie								--
--  extended by Cem Basoglu							--
--  www.multikopter-forum.de						--
--  www.anysense.de									--
------------------------------------------------------

----------------------------------------------------------------------------------
--							            Settings		            			--
----------------------------------------------------------------------------------

local headingHomeLock 	= 1							-- reset heading to zero on home set (1 = yes, 0 = no)

local playHomeSet 		= 1							-- play home position set sound (1 = yes, 0 = no)
local playMotorArmed 	= 1							-- play motors armed sound (1 = yes, 0 = no)

local titleAltitude 	= "Hoehe ";
local titleSpeed 		= "Geschw. ";
local titleDistanz	 	= "Distanz ";


----------------------------------------------------------------------------------
--            please do not edit below, unless you know what you do             --
----------------------------------------------------------------------------------

---------------------------------
--Definition sonstige Variablen--
---------------------------------
local number_cells	= 0								-- Zellenanzahl. Wird genutzt falls Einzelspannung nicht verfuegbar ist.
local wait = 25										-- Wartezeit bis die Akku Spannung korrekt uebertragen wurde. Ca. 7 Sekunden
local lat_home 	= 0									-- Homeposition Latitude
local long_home	 = 0								-- Homeposition Longitude
local myheading  = 0

local lastMotor = false									-- Nur bei Wertwechsel Sound
local lastHome = false									-- Nur bei Wertwechsel Sound

local seconds = 0
local minutes = 0
local counter = 0
local lastMeasure = 0

local modeDesc = {[0]="Manual", [1]="GPS", [2]="Failsafe", [3]="ATTI"}

local data = {}

---------------------------------
--      Helper Functions       --
---------------------------------

local function getValueOrDefault(value)
	local tmp = getValue(value)
	
	if tmp == nil then
		return 0
	end
	
	return tmp
end

local function math_map(in_min, in_max, num, out_min, out_max)

	return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

end

local function getCellPercent(cellVoltage)

	if cellVoltage > 4.15 then
		return 100
	elseif cellVoltage > 4.10 then
		return math_map(4.10, 4.15, cellVoltage, 90, 100)
	elseif cellVoltage > 3.97 then
		return math_map(3.97, 4.10, cellVoltage, 80, 90)
	elseif cellVoltage > 3.92 then
		return math_map(3.92, 3.97, cellVoltage, 70, 80)
	elseif cellVoltage > 3.87 then
		return math_map(3.87, 3.92, cellVoltage, 60, 70)
	elseif cellVoltage > 3.83 then
		return math_map(3.83, 3.87, cellVoltage, 50, 60)
	elseif cellVoltage > 3.79 then
		return math_map(3.79, 3.83, cellVoltage, 40, 50)
	elseif cellVoltage > 3.75 then
		return math_map(3.75, 3.79, cellVoltage, 30, 40)
	elseif cellVoltage > 3.70 then
		return math_map(3.70, 3.75, cellVoltage, 20, 30)
	elseif cellVoltage > 3.60 then
		return math_map(3.60, 3.70, cellVoltage, 10, 20)
	elseif cellVoltage > 3.30 then
		return math_map(3.30, 3.60, cellVoltage, 5, 10)
	elseif cellVoltage > 3.00 then
		return math_map(3.00, 3.30, cellVoltage, 0, 5)
	end
	
	return 0
end

local function tasks()

	if lastMotor ~= data.armed then
	
		if data.armed then
			if headingHomeLock == 1 then -- Richtung merken
				myheading = data.heading	
			end
	
			if playMotorArmed == 1 then
				playFile("/SCRIPTS/WAV/AnySense/bldson.wav")
			end
		else
			if playMotorArmed == 1 then
				playFile("/SCRIPTS/WAV/AnySense/bldsoff.wav")
			end
		end
	
		lastMotor = data.armed
	end

	if lastHome ~= data.homeSet then
	
		if data.homeSet then

			lat_home = data.lat
			long_home = data.long
	
			if playHomeSet == 1 then
				playFile("/SCRIPTS/WAV/AnySense/antrfrei.wav")
			end
	
		end
	
		lastHome = data.homeSet
	end
	
	
	if data.cell == 0 then 																-- Keine Einzelzellen Messung vorhanden
		if number_cells == 0 then														-- Zellenanzahl nur ermitteln wenn noch nicht ermittelt
			if data.lipo > 0 then														-- Gesamtspannung vorhanden
				if wait > 0 then														-- warten bis stabilisiert
					wait = wait - 1;
				else
					number_cells = math.ceil (data.lipo/4.2)							-- Zellenzahl berechnen
				end
			end
		end
	
		if number_cells > 0 then
			data.cell = data.lipo / number_cells
		end
	end
	
	if headingHomeLock == 1 then														-- Wenn die Startrichtung Norden sein soll...
		data.heading = data.heading - myheading
		if data.heading < 0 then
			data.heading = data.heading + 360
		end
	end
	
	if data.armed then
		if lastMeasure == 0 then
			lastMeasure = getTime()
		end
	
		counter = counter + (getTime() - lastMeasure)
	
		lastMeasure = getTime()
	
		
		while counter >= 100 do
			seconds = seconds + 1
		
			if seconds >= 60 then
				seconds = 0
				minutes = minutes + 1
			end
			
			counter = counter - 100
		end
		
	else
		lastMeasure = 0
	end
	
end

local function updateTelemetry()
	
	data.lat = getValueOrDefault ("latitude")				-- Aktuelle Position Latitude
	data.long = getValueOrDefault ("longitude")				-- Aktuelle Position Longitude
	data.heading = getValueOrDefault (223)					-- Aktuelle Flugrichtung
	data.distance = getValueOrDefault (212)					-- GPS Entferung
	data.speed = getValueOrDefault (211)*1.852				-- GPS Speed (*1,852, da die Werte in Knoten sind)
	data.alt = getValueOrDefault (206)						-- Baro Hoehe
	data.vario = getValueOrDefault (224)					-- Vario
	data.cell = getValueOrDefault (214)						-- Geringste Lipo Zelle, falls vorhanden
	data.lipo = getValueOrDefault (216)						-- Summe Lipo Spannung
	data.rssi = getValueOrDefault (200)						-- RSSI
	data.accx = getValueOrDefault (220)						-- Gyro X
	data.accy = getValueOrDefault (221)						-- Gyro y
	data.curr = getValueOrDefault (217)						-- Current
	data.cnsp = getValueOrDefault (218)						-- Current
	
	--------------------------------------
	--  Kombinierter Wert vom AnySense  --
	--------------------------------------

	local fuel = getValueOrDefault(208)						-- Fuel enthaelt kombinierten Wert
	data.sats = fuel % 100    						
	fuel = math.floor((fuel - data.sats) / 100)

	data.satfix = fuel % 10
	fuel = math.floor((fuel - data.satfix) / 10)			

	data.fmode = fuel % 10
	fuel = math.floor((fuel - data.fmode) / 10)

	data.armed = bit32.band(fuel, 1) == 1
	data.homeSet = bit32.band(fuel, 2) == 2
	
end

local function run ()

	--------------------------------------
	-- Defintion der Werte aus der Naza --
	--------------------------------------

	updateTelemetry()
	
	---------------------------------
	--Definition sonstige Variablen--
	---------------------------------

	local headingvalue                                 -- Zur Auswahl des Richtungpfeils
	local heading_home									-- Richtung zum Homepoint
	local voltage_percent								-- Aktuelle Spannung in Prozent
	local fileindex	 = 0								-- Index fuer Dateinamen
	local x												-- Einfache Zaehlervariable
	local yl											-- Fuer Horizont. Y-Koordinaten linke Seite
	local yr											-- Fuer Horizont. Y-Koordinaten rechte Seite
	local z1											-- Einfache Zaehlervariable
	local z2											-- Einfache Zaehlervariable


	--------------------------------------
	--              Tasks               --
	--------------------------------------

	tasks()

	--------------------
	--Raster zeichnen --
	--------------------

	lcd.drawLine(0, 14, 67, 14,SOLID,0) 		-- Linie unter Flightmode
	lcd.drawLine(113, 20, 211, 20,SOLID,0) 		-- Linie unter Uhr
	lcd.drawLine(0, 33, 67, 33,SOLID,0)  		-- Linie unter GPS
	lcd.drawLine(68, 0, 68, 50,SOLID,0)		    -- senkrechte rechts neben Flightmode
	lcd.drawLine(112, 0, 112, 64,SOLID,0)		-- senkrechte Linie zwischn GPS und RSSI
	lcd.drawLine(139, 0, 139, 19,SOLID,0)		-- senkrechte Linie zwischen RSSI und Timer
	lcd.drawLine(69, 14, 111, 14,SOLID,0)		-- waagerechte Linie ueber Kompass
	lcd.drawLine(69, 50, 111, 50,SOLID,0)		-- waagerechte Linie unter Kompass

	------------------------
	-- Flugmodus anzeigen --
	------------------------

	lcd.drawText (2, 1, modeDesc[data.fmode], MIDSIZE)

	----------------
	--GPS anzeigen--
	----------------

	lcd.drawPixmap(3, 16, "/SCRIPTS/BMP/AnySense/gps.bmp")
	lcd.drawNumber(60, 16, data.sats, DBLSIZE)
	
	if (data.sats > 6) then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_5.bmp")
	elseif (data.sats > 5) then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_4.bmp")
	elseif (data.sats > 4) then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_3.bmp")
	elseif (data.sats > 2) then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_2.bmp")
	elseif (data.sats > 0) then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_1.bmp")
	elseif data.sats < 1 then
		lcd.drawPixmap(18, 16, "/SCRIPTS/BMP/AnySense/gps_0.bmp")
	end

	lcd.drawPixmap (62,16, "/SCRIPTS/BMP/AnySense/satfix_"..data.satfix..".bmp")

	----------------
	--Akku Anzeige--
	----------------

	if data.cell > 0 then
		voltage_percent = math.floor(getCellPercent(data.cell))

		fileindex = math.floor(math_map(0, 100, voltage_percent, 0, 14))
	
		lcd.drawPixmap (3,35,"/SCRIPTS/BMP/AnySense/Akku-"..fileindex..".bmp")
		--lcd.drawText (26,40,voltage_percent.."%",SMLSIZE)
		
		lcd.drawNumber (3, 52, data.cell*100, MIDSIZE+PREC2+LEFT)		
		lcd.drawText (lcd.getLastPos(), 57, "V", SMLSIZE)
		
		lcd.drawNumber (lcd.getLastPos() + 10, 52, data.curr*10, MIDSIZE+PREC1+LEFT)
		lcd.drawText (lcd.getLastPos(), 57, "A", SMLSIZE)
		
		lcd.drawNumber (95, 52, data.cnsp, MIDSIZE)
		lcd.drawText (95, 57, "mAh", SMLSIZE)
	else																				
		lcd.drawPixmap (3,35,"/SCRIPTS/BMP/AnySense/Akku-0.bmp")
		lcd.drawText (5,52,"Keine Werte",BLINK)
	end

	----------------------------------
	--Kompass mit Homepunkt anzeigen--
	----------------------------------

	--Heading berechnen und anzeigen
	fileindex = math.floor (data.heading/15+0.5)														-- Berechnen welche BMP geladen werden soll (0-23 a 15 Grad)
	if fileindex > 23 then																		-- Durch das Runden springt er ab 352 Grad auf Index 24 fuer 360 Grad.
		fileindex = fileindex-24																-- Deswegen 24 abziehen.
	end
	lcd.drawPixmap (80,21,"/SCRIPTS/BMP/AnySense/Pfeil"..fileindex..".bmp")


	if not (long_home == 0 and lat_home == 0) then												--Homepunkt nur anzeigen, wenn er auch gesetzt ist.
		z1 = math.sin (math.rad(long_home) - math.rad(data.long)) * math.cos(math.rad(lat_home))	--Richtung nach Hause berechnen (geklaut von Sockeye)
		z2 = math.cos(math.rad(data.lat)) * math.sin(math.rad(lat_home)) - math.sin(math.rad(data.lat)) * math.cos(math.rad(lat_home)) * math.cos(math.rad(long_home) - math.rad(data.long))
		heading_home = math.deg(math.atan2(z1, z2)) - 90           								-- 90 Grad abziehen fuer Darstellung Home Kreis, da bei Polarkoordinaten 0 Grad rechts und 90 Grad oben
		if headingHomeLock == 2 then															-- Wenn die Startrichtung Norden ist...
			heading_home = heading_home - myheading												--...dann die Gradzahl entsprechend anpassen
		end
		if heading_home < 0 then
			heading_home=heading_home+360
		end
		x = math.floor(15* math.cos(math.rad(heading_home))+0,5)								-- X und y Koordianten fuer Home Kreis berechnen
		y = math.floor(15* math.sin(math.rad(heading_home))+0,5)
		lcd.drawPixmap (89+x,30+y,"/SCRIPTS/BMP/AnySense/Homepunkt.bmp")    						-- Home Kreis zeichnen
	end

	--------------------------------------------------
	--Hoehe, Entfernung und Geschwindigkeit anzeigen--
	--------------------------------------------------

	lcd.drawText(125, 24, titleAltitude, 0)
	lcd.drawText(125, 38, titleSpeed, 0)
	lcd.drawText(125, 52, titleDistanz, 0)
	lcd.drawText(196, 24, "m", SMLSIZE)
	lcd.drawText(196, 38, "kmh", SMLSIZE)
	lcd.drawText(196, 52, "m", SMLSIZE)

	lcd.drawNumber (196,21,data.alt,MIDSIZE)

	lcd.drawNumber (196,35,data.speed,MIDSIZE)
	lcd.drawNumber (196,49,data.distance,MIDSIZE)

	------------------
	--Timer anzeigen--
	------------------

	lcd.drawPixmap(141, 4, "/SCRIPTS/BMP/AnySense/timer.bmp")
	
	x = 165
	
	if minutes < 10 then
		lcd.drawNumber(x, 2, 0, DBLSIZE+LEFT)
		x = lcd.getLastPos()
	end
	lcd.drawNumber(x, 2, minutes, DBLSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(), 2, ":", DBLSIZE)
	if seconds < 10 then
		lcd.drawNumber(lcd.getLastPos(), 2, 0, DBLSIZE+LEFT)
	end
	lcd.drawNumber(lcd.getLastPos(), 2, seconds, DBLSIZE+LEFT)
		
	-----------------
	--RSSI anzeigen--
	-----------------

	lcd.drawText(116, 2, "RSSI", SMLSIZE)
	lcd.drawNumber(116, 10, data.rssi, LEFT)
	lcd.drawText(lcd.getLastPos(), 10, "dB", SMLSIZE)

	------------------
	--Vario anzeigen--
	------------------

	lcd.drawLine (121,21,121,63,SOLID,0)													--senkrechteLinie fuer rechten Rahmen Vario Anzeige
	lcd.drawLine (113,42,120,42,SOLID,0)													-- Mittelstrich anzeigen

	if data.vario < 0 then
		if data.vario < -2.1 then
			lcd.drawFilledRectangle (112,43,10,21,SOLID,0)
		else
			lcd.drawFilledRectangle (112,43,10,(data.vario*-10),SOLID,0)
		end
	else
		if data.vario > 2.1 then
			lcd.drawFilledRectangle (112,21,10,21,SOLID,0)
		else
			lcd.drawFilledRectangle (112,(42-data.vario*10),10,data.vario*10,SOLID,0)
		end
	end

	---------------------
	--Horizont anzeigen--
	---------------------
	lcd.drawLine (90,5,90,2,SOLID,0)
	lcd.drawLine (90,9,90,12,SOLID,0)
	lcd.drawLine (92,7,95,7,SOLID,0)
	lcd.drawLine (88,7,85,7,SOLID,0)

	if data.accx > 0 then
		data.accx = 360-data.accx
	else
		data.accx = data.accx*(-1)
	end


	if data.accy > 45 then
		data.accy = 45
	else
		if data.accy < -45 then
			data.accy = -45
		end
	end

	x=90
	y=10

	x = math.floor(20* math.cos(math.rad(data.accx))+0,5)
	yr = math.floor(20* math.sin(math.rad(data.accx))+0,5)
	yl = yr *-1

	yr = yr+ math.floor (data.accy/4.5)
	yl = yl+ math.floor (data.accy/4.5)

	lcd.drawLine (90+x,7+yr,90-x,7+yl,DOTTED,0)

end

function background()

	updateTelemetry()
	
	tasks()

end

return { run=run, background=background }

