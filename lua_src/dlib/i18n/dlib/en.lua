
-- Copyright (C) 2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.


gui.misc.apply = 'Apply'
gui.misc.cancel = 'Cancel'
gui.misc.yes = 'Yes'
gui.misc.no = 'No'

gui.entry.invalidsymbol = 'Symbol is not allowed.'
gui.entry.limit = 'Field limit exceeded.'

gui.dlib.hudcommons.reset = 'Reset'

info.dlib.tformat.seconds = 'seconds'
info.dlib.tformat.minutes = 'minutes'
info.dlib.tformat.hours = 'hours'
info.dlib.tformat.days = 'days'
info.dlib.tformat.weeks = 'weeks'
info.dlib.tformat.months = 'months'
info.dlib.tformat.years = 'years'
info.dlib.tformat.centuries = 'centuries'

info.dlib.tformat.long = 'Never™'
info.dlib.tformat.now = 'Right now'
info.dlib.tformat.past = 'In the past'

gui.dlib.friends.title = 'DLib Friends'
gui.dlib.friends.open = 'Open Friends Menu'

gui.dlib.friends.edit.add_title = 'Adding %s <%s> as friend'
gui.dlib.friends.edit.edit_title = 'Editing %s <%s> friend settings'
gui.dlib.friends.edit.going = 'You are going to be a friend with %s in...'
gui.dlib.friends.edit.youare = 'You are friend with %s in...'
gui.dlib.friends.edit.remove = 'Remove friend'

gui.dlib.friends.invalid.title = 'Invalid SteamID'
gui.dlib.friends.invalid.ok = 'Okay :('
gui.dlib.friends.invalid.desc = '%q doesnt look like valid steamid!'

gui.dlib.friends.settings.steam = 'Consider Steam friends as DLib friends'
gui.dlib.friends.settings.your = 'Your friends ->'
gui.dlib.friends.settings.server = 'Server players ->'

gui.dlib.friends.settings.foreign = '[Foreign] '

gui.dlib.donate.top = 'DLib: Make a donation?'
gui.dlib.donate.button.yes = 'Make a donation!'
gui.dlib.donate.button.paypal = 'Make a donation, but on PayPal!'
gui.dlib.donate.button.no = 'Ask me later'
gui.dlib.donate.button.never = 'Never ask again'
gui.dlib.donate.button.learnabout = 'Read about "Donationware"...'
gui.dlib.donate.button.learnabout_url = 'https://en.wikipedia.org/wiki/Donationware'

message.dlib.hudcommons.edit.notice = 'Press ESC to close the editor'

gui.dlib.donate.text = [[Hello there! I see you were AFK for a long time (if you slept all these time, good morning... or whatever),
but so, if you are awake, i want to ask you: Can you please make a dontation?
DLib and all official addons on top of it are Donationware!
Just a bit of donation! Even if you can only give 1$ or 1€, thats great if you would ask! Just imagine:
If everyone who is subscribed to my addons will donate money for a cup of tea it will be enough to cover
all my parent's credits. It could also help a lot to my mother who spend entire days on her job.
Currently, the only thing i do is developing these free addons just for you!
Just for community! For free and it is even open source with easy way of contribution! If you could just
make a small donation you will support next addons:
DLib%s]]

gui.dlib.donate.more = ' and %i more addons!..'

gui.dlib.hudcommons.positions = '%s positions'
gui.dlib.hudcommons.fonts = '%s fonts'
gui.dlib.hudcommons.colors = '%s colors'
gui.dlib.hudcommons.font = 'Font'
gui.dlib.hudcommons.font_label = 'Settings for %s'
gui.dlib.hudcommons.save_hint = 'Don\'t forget to host_writeconfig in\nconsole after you did all your changes!'
gui.dlib.hudcommons.weight = 'Weight'
gui.dlib.hudcommons.size = 'Size'

gui.dlib.notify.families_loading = 'Expect lag, DLib is baking a cake\n(searching for installed font families)'

-- yotta    Y    10008      1024   1000000000000000000000000    septillion      quadrillion    1991
-- zetta    Z    10007      1021   1000000000000000000000   sextillion      trilliard  1991
-- exa      E    10006      1018   1000000000000000000      quintillion     trillion   1975
-- peta     P    10005      1015   1000000000000000     quadrillion     billiard   1975
-- tera     T    10004      1012   1000000000000    trillion    billion    1960
-- giga     G    10003      109    1000000000   billion     milliard   1960
-- mega     M    10002      106    1000000      million    1873
-- kilo     k    10001      103    1000     thousand   1795
-- hecto    h    10002/3     102    100      hundred    1795
-- deca     da   10001/3     101    10   ten    1795

-- deci     d    1000−1/3    10−1   0.1      tenth  1795
-- centi    c    1000−2/3    10−2   0.01     hundredth  1795
-- milli    m    1000−1      10−3   0.001    thousandth     1795
-- micro    μ    1000−2      10−6   0.000001     millionth  1873
-- nano     n    1000−3      10−9   0.000000001      billionth   milliardth     1960
-- pico     p    1000−4      10−12  0.000000000001   trillionth      billionth  1960
-- femto    f    1000−5      10−15  0.000000000000001    quadrillionth   billiardth (Proposed)  1964
-- atto     a    1000−6      10−18  0.000000000000000001     quintillionth   trillionth     1964
-- zepto    z    1000−7      10−21  0.000000000000000000001      sextillionth    trilliardth    1991
-- yocto    y    1000−8      10−24  0.000000000000000000000001   septillionth    quadrillionth  1991

local prefix = {
	{'yocto', 'y'},
	{'zepto', 'z'},
	{'atto', 'a'},
	{'femto', 'f'},
	{'pico', 'p'},
	{'nano', 'n'},
	{'micro', 'μ'},
	{'milli', 'm'},
	{'centi', 'c'},
	{'deci', 'd'},
	{'kilo', 'k'},
	{'mega', 'M'},
	{'giga', 'G'},
	{'tera', 'T'},
	{'peta', 'P'},
	{'exa', 'E'},
	{'zetta', 'Z'},
	{'yotta', 'Y'},
}

local units = [[hertz    Hz  frequency   1/s     s−1
radian   rad     angle   m/m     1
steradian    sr  solid angle     m2/m2   1
newton   N   force, weight   kg⋅m/s2     kg⋅m⋅s−2
pascal   Pa  pressure, stress    N/m2    kg⋅m−1⋅s−2
joule    J   energy, work, heat  N⋅m, C⋅V, W⋅s   kg⋅m2⋅s−2
watt     W   power, radiant flux     J/s, V⋅A    kg⋅m2⋅s−3
coulomb  C   electric charge or quantity of electricity  s⋅A, F⋅V    s⋅A
volt     V   voltage, electrical potential difference, electromotive force   W/A, J/C    kg⋅m2⋅s−3⋅A−1
farad    F   electrical capacitance  C/V, s/Ω    kg−1⋅m−2⋅s4⋅A2
ohm  Ω   electrical resistance, impedance, reactance     1/S, V/A    kg⋅m2⋅s−3⋅A−2
siemens  S   electrical conductance  1/Ω, A/V    kg−1⋅m−2⋅s3⋅A2
weber    Wb  magnetic flux   J/A, T⋅m2   kg⋅m2⋅s−2⋅A−1
tesla    T   magnetic induction, magnetic flux density   V⋅s/m2, Wb/m2, N/(A⋅m)  kg⋅s−2⋅A−1
henry    H   electrical inductance   V⋅s/A, Ω⋅s, Wb/A    kg⋅m2⋅s−2⋅A−2
degree Celsius   °C  temperature relative to 273.15 K    K   K
lumen    lm  luminous flux   cd⋅sr   cd
lux  lx  illuminance     lm/m2   cd⋅sr/m2
becquerel    Bq  radioactivity (decays per unit time)    1/s     s−1
gray     Gy  absorbed dose (of ionizing radiation)   J/kg    m2⋅s−2
sievert  Sv  equivalent dose (of ionizing radiation)     J/kg    m2⋅s−2
katal    kat     catalytic activity  mol/s   s−1⋅mol]]

for i, row in ipairs(prefix) do
	info.dlib.si.prefix[row[1]].name = row[3] or row[1]:formatname()
	info.dlib.si.prefix[row[1]].prefix = row[2]
end

for i, row in ipairs(units:split('\n')) do
	local measure, NaM = row:match('(%S+)%s+(%S+)')

	if measure and NaM then
		info.dlib.si.units[measure].name = measure:formatname()
		info.dlib.si.units[measure].suffix = NaM
	end
end

info.dlib.si.units.kelvin.name = 'Kelvin'
info.dlib.si.units.kelvin.suffix = 'K'

info.dlib.si.units.celsius.name = 'Celsius'
info.dlib.si.units.celsius.suffix = 'C'

info.dlib.si.units.fahrenheit.name = 'Fahrenheit'
info.dlib.si.units.fahrenheit.suffix = 'F'

info.dlib.si.units.gram.name = 'Gram'
info.dlib.si.units.gram.suffix = 'g'

info.dlib.si.units.metre.name = 'Metre'
info.dlib.si.units.metre.suffix = 'm'

info.dlib.si.units.litre.name = 'Litre'
info.dlib.si.units.litre.suffix = 'L'
