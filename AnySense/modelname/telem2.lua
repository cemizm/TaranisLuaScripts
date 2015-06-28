


local function run(event)

    local fuel = getValue(208)
    local raw = fuel

    local sats = fuel % 100
    fuel = fuel / 100

    local fix = fuel % 10
    fuel = fuel / 10

    local mode = fuel % 10
    fuel = fuel / 10

    local armed = bit32.band(fuel, 1) == 1
    local homeSet = bit32.band(fuel, 2) == 2


	local oArm = "no"
	local oHome = "no"
	
	if armed then
		oArm = "yes"
	end

	if homeSet then
		oHome = "yes"
	end

    lcd.drawText(20, 2, "RAW:", SMLSIZE)
    lcd.drawNumber(60, 2, raw, LEFT+SMLSIZE)

    lcd.drawText(20, 12, "SAT:", SMLSIZE)
    lcd.drawNumber(60, 12, sats, LEFT+SMLSIZE)

    lcd.drawText(20, 22, "FIX:", SMLSIZE)
    lcd.drawNumber(60, 22, fix, LEFT+SMLSIZE)

    lcd.drawText(20, 32, "Mode:", SMLSIZE)
    lcd.drawNumber(60, 32, mode, LEFT+SMLSIZE)

    lcd.drawText(20, 42, "Arm:", SMLSIZE)
    lcd.drawText(60, 42, oArm, SMLSIZE)

    lcd.drawText(20, 52, "Home:", SMLSIZE)
    lcd.drawText(60, 52, oHome, SMLSIZE)

end

return { run=run }