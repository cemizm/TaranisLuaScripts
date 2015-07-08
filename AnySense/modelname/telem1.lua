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

local isImperial       = 1             -- 0 = metric, 1 = imperial

local headingHomeLock 	= 1							-- reset heading to zero on home set (1 = yes, 0 = no)

local playHomeSet 		= 1							  -- play home position set sound (1 = yes, 0 = no)
local playMotorArmed 	= 1						  	-- play motors armed sound (1 = yes, 0 = no)

local alternatePeriod = 3              -- period in seconds to alternate the values in the bottom right corner

----------------------------------------------------------
-- Display Values
---------------------------
--
-- 
--
----
-- uncomment/comment the lines below to display 
-- the values in the bottom right corner of the script.
--
-- more then 3 active values will be alternated in the 
-- given alternate period above. 
-- The sort order of the items is in the same 
-- order like in the list below.
--
-- change the Label to customize the display.
--
-- DO NOT EDIT Value OR Unit!
----------------------------------------------------------


local displayValues = { 
  { Label = "Alt", Value = 1, Unit = 5, },      -- Altitude in m / ft
  { Label = "Speed", Value = 2, Unit = 4, },        -- Speed in kmh / mph
  { Label = "Dist.", Value = 3, Unit = 5, },        -- Distance in m / ft
  { Label = "Volt", Value = 4, Unit = 0, },         -- Vfas: Spannung der Naza in V / Battery Voltage from Naza in V
  { Label = "Cells", Value = 5, Unit = 0, },        -- Cells: Summe der Einzellspannung in V / Sum of cell voltages in V(Lipo Sensor)
  { Label = "Cell", Value = 6, Unit = 0, },         -- Cell: Schwächste Lipo Zelle in V / Lowest Lipo Voltage in V
  { Label = "Curr.", Value = 7, Unit = 1, },     -- Strom in A / current in A
  { Label = "Cnsp.", Value = 8, Unit = 2, },     -- Gesamt-Stromverbrauch in mAh / current consumption in mAh
  { Label = "Vario", Value = 9, Unit = 3, },      -- Steigrate in m/s / vertical speed in ft/s
  { Label = "Temp1", Value = 10, Unit = 6, },     -- Temperatur Sensor 1 in C / F
  { Label = "Temp2", Value = 11, Unit = 6, },     -- Temperatur Sensor 2 in C / F
}

----------------------------------------------------------------------------------
--            please do not edit below, unless you know what you do             --
----------------------------------------------------------------------------------

---------------------------------
--            Timer            --
---------------------------------

local Timer = { 
  lastMeasture = 0, 
  counter = 0, 
  enabled = false,
  seconds = 0,
  minutes = 0,
  hours = 0,
}

function Timer:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Timer:update()
  if not self.enabled then 
    return
  end

  self.counter = self.counter + (getTime() - self.lastMeasure)
  self.lastMeasure = getTime()

  while self.counter >= 100 do
    self.seconds = self.seconds + 1

    if self.seconds > 59 then
      self.seconds = 0
      self.minutes = self.minutes + 1
    end

    if self.minutes > 59 then 
      self.minutes = 0
      self.hours = self.hours + 1
    end

    self.counter = self.counter - 100
  end
end

function Timer:start()
  if self.enabled then 
    return
  end

  self.lastMeasure = getTime()
  self.enabled = true
end

function Timer:stop()
  if not self.enabled then 
    return
  end

  self.lastMeasure = 0
  self.enabled = false
end

function Timer:reset()
  self.lastMeasure = getTime()
  self.counter = 0
  self.seconds = 0
  self.minutes = 0
  self.hours = 0
end



---------------------------------
--Definition sonstige Variablen--
---------------------------------
local number_cells	= 0								-- Zellenanzahl. Wird genutzt falls Einzelspannung nicht verfuegbar ist.
local wait = 25										  -- Wartezeit bis die Akku Spannung korrekt uebertragen wurde. 
local lat_home 	= 0									-- Homeposition Latitude
local long_home	 = 0								-- Homeposition Longitude
local myheading  = 0

local lastMotor = false									-- Nur bei Wertwechsel Sound
local lastHome = false									-- Nur bei Wertwechsel Sound

local motorTimer = Timer:new()

local modeDesc = {[0]="Manual", [1]="GPS", [2]="Failsafe", [3]="ATTI"}
local units = { 
  { 
    { Label = "V" },
    { Label = "A" },
    { Label = "mAh" },
    { Label = "ms" },
    { Label = "kmh" },
    { Label = "m" },
    { Label = "C" },
  },
  { 
    { Label = "V" },
    { Label = "A" },
    { Label = "mAh" },
    { Label = "fts" },
    { Label = "mph" },
    { Label = "ft" },
    { Label = "F" },
  },
}

local display = { }
local numPages = 0
local currentPage = 0

local pageTimer = Timer:new()

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



---------------------------------
--       Telemetry Data        --
---------------------------------

local data = {}

function data:getValue(type) 
  if type == 1 then return self.alt
  elseif type == 2 then return self.speed 
  elseif type == 3 then return self.distance
  elseif type == 4 then return self.lipo
  elseif type == 5 then return self.cells
  elseif type == 6 then return self.cell
  elseif type == 7 then return self.curr
  elseif type == 8 then return self.cnsp
  elseif type == 9 then return self.vario
  elseif type == 10 then return self.temp1
  elseif type == 11 then return self.temp2
  end

  return 0
end

function data:updateTelemetry()

  self.lat = getValueOrDefault ("latitude")				-- Aktuelle Position Latitude
  self.long = getValueOrDefault ("longitude")				-- Aktuelle Position Longitude
  self.heading = getValueOrDefault (223)					-- Aktuelle Flugrichtung
  self.distance = getValueOrDefault (212)					-- GPS Entferung
  self.speed = getValueOrDefault (211)*1.852				-- GPS Speed (*1,852, da die Werte in Knoten sind)
  self.alt = getValueOrDefault (206)						-- Baro Hoehe
  self.vario = getValueOrDefault (224)					-- Vario
  self.cell = getValueOrDefault (214)						-- Geringste Lipo Zelle, falls vorhanden
  self.lipo = getValueOrDefault (216)						-- Summe Lipo Spannung
  self.rssi = getValueOrDefault (200)						-- RSSI
  self.accx = getValueOrDefault (220)						-- Gyro X
  self.accy = getValueOrDefault (221)						-- Gyro y
  self.curr = getValueOrDefault (217)						-- Current
  self.cnsp = getValueOrDefault (218)						-- Current
  self.cells = getValueOrDefault(215)           
  self.temp1 = getValueOrDefault(209)           
  self.temp2 = getValueOrDefault(210)           

  --------------------------------------
  --  Kombinierter Wert vom AnySense  --
  --------------------------------------

  local fuel = getValueOrDefault(208)						-- Fuel enthaelt kombinierten Wert
  self.sats = fuel % 100    						
  fuel = math.floor((fuel - self.sats) / 100)

  self.satfix = fuel % 10
  fuel = math.floor((fuel - self.satfix) / 10)			

  self.fmode = fuel % 10
  fuel = math.floor((fuel - self.fmode) / 10)

  self.armed = bit32.band(fuel, 1) == 1
  self.homeSet = bit32.band(fuel, 2) == 2

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

      motorTimer:start()
    else
      if playMotorArmed == 1 then
        playFile("/SCRIPTS/WAV/AnySense/bldsoff.wav")
      end

      motorTimer:stop()
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


  motorTimer:update()

end

function init() 

  --local settings = getGeneralSettings()
  --isImperial = settings.imperial

  local cnt = 0
  numPages = 0
  for key, value in pairs(displayValues) do
    if cnt == 3 then
      cnt = 0
      numPages = numPages + 1
    end

    if display[numPages] == nil then
      display[numPages] = { }
    end

    display[numPages][cnt] = value

    cnt = cnt + 1
  end

  if numPages > 0 then
    pageTimer:start()
  end

end

local function run ()

  --------------------------------------
  -- Defintion der Werte aus der Naza --
  --------------------------------------

  data:updateTelemetry()

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

    lcd.drawNumber (lcd.getLastPos() + 4, 52, data.curr*10, MIDSIZE+PREC1+LEFT)
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
  --                Display Value                 --
  --------------------------------------------------

  pageTimer:update()

  if pageTimer.seconds > alternatePeriod then
    currentPage = currentPage + 1

    if currentPage > numPages then
      currentPage = 0
    end

    pageTimer:reset()
  end


  x = 0

  for x=0, 2 do

    if display[currentPage][x] ~= nil then

      lcd.drawText(125, 24 + x * 14, display[currentPage][x].Label, 0)  
      lcd.drawText(196, 24 + x * 14, units[isImperial + 1][display[currentPage][x].Unit + 1].Label, SMLSIZE)  
      lcd.drawNumber(196, 21 + x * 14, data:getValue(display[currentPage][x].Value), MIDSIZE + PREC2)
      
    end
    
  end


  ------------------
  --Timer anzeigen--
  ------------------

  lcd.drawPixmap(141, 4, "/SCRIPTS/BMP/AnySense/timer.bmp")

  x = 165

  if motorTimer.minutes < 10 then
    lcd.drawNumber(x, 2, 0, DBLSIZE+LEFT)
    x = lcd.getLastPos()
  end
  lcd.drawNumber(x, 2, motorTimer.minutes, DBLSIZE+LEFT)
  lcd.drawText(lcd.getLastPos(), 2, ":", DBLSIZE)
  if motorTimer.seconds < 10 then
    lcd.drawNumber(lcd.getLastPos(), 2, 0, DBLSIZE+LEFT)
  end
  lcd.drawNumber(lcd.getLastPos(), 2, motorTimer.seconds, DBLSIZE+LEFT)

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

  data:updateTelemetry()

  tasks()

end

return { run=run, background=background, init=init }

