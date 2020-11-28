
-- Copyright (C) 2018-2020 DBotThePony

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


gui.misc.apply = 'Применить'
gui.misc.cancel = 'Отмена'
gui.misc.yes = 'Да'
gui.misc.no = 'Нет'
gui.misc.confirm = 'Подтвердить'
gui.misc.decline = 'Отклонить'
gui.misc.add = 'Добавить'
gui.misc.delete = 'Удалить'

gui.entry.invalidsymbol = 'Символ не разрешён.'
gui.entry.limit = 'Превышена максимальная длинна значения.'

gui.dlib.hudcommons.reset = 'Сбросить'

info.dlib.tformat.seconds = 'секунд'
info.dlib.tformat.minutes = 'минут'
info.dlib.tformat.hours = 'часов'
info.dlib.tformat.days = 'дней'
info.dlib.tformat.weeks = 'недель'
info.dlib.tformat.months = 'месяцев'
info.dlib.tformat.years = 'лет'
info.dlib.tformat.centuries = 'веков'

info.dlib.tformat.long = 'Никогда™'
info.dlib.tformat.now = 'Прямо сейчас'
info.dlib.tformat.past = 'В прошлом'

local function define(from, to, target, form1, form2, form3)
	for i = from, to do
		local div = i % 10

		if i == 0 or i > 9 and i < 19 or div > 4 or div == 0 then
			target[tostring(i)] = i .. ' ' .. form1
		elseif div == 1 then
			target[tostring(i)] = i .. ' ' .. form2
		elseif div == 2 or div == 3 or div == 4 then
			target[tostring(i)] = i .. ' ' .. form3
		end
	end
end

define(1, 60, info.dlib.tformat.countable.second, 'секунд', 'секунда', 'секунды')
define(1, 60, info.dlib.tformat.countable.minute, 'минут', 'минута', 'минуты')
define(1, 24, info.dlib.tformat.countable.hour, 'часов', 'час', 'часа')
define(1, 7, info.dlib.tformat.countable.day, 'день', 'дня', 'дней')
define(1, 4, info.dlib.tformat.countable.week, 'неделя', 'недели', 'недель')
define(1, 12, info.dlib.tformat.countable.month, 'месяц', 'месяца', 'месяцев')
define(1, 100, info.dlib.tformat.countable.year, 'год', 'года', 'лет')
define(1, 100, info.dlib.tformat.countable.century, 'век', 'века', 'веков')

define(1, 60, info.dlib.tformat.countable_ago.second, 'секунд', 'секунду', 'секунды')
define(1, 60, info.dlib.tformat.countable_ago.minute, 'минут', 'минуту', 'минуты')
define(1, 24, info.dlib.tformat.countable_ago.hour, 'часов', 'час', 'часа')
define(1, 7, info.dlib.tformat.countable_ago.day, 'дней', 'день', 'дня')
define(1, 4, info.dlib.tformat.countable_ago.week, 'недель', 'неделю', 'недели')
define(1, 12, info.dlib.tformat.countable_ago.month, 'месяцев', 'месяц', 'месяца')
define(1, 100, info.dlib.tformat.countable_ago.year, 'лет', 'год', 'года')
define(1, 100, info.dlib.tformat.countable_ago.century, 'веков', 'век', 'века')

info.dlib.tformat.ago = '%s тому назад'
info.dlib.tformat.ago_inv = 'Через %s'

gui.dlib.friends.title = 'DLib друзья'
gui.dlib.friends.open = 'Отрыть меню друзей'

gui.dlib.friends.edit.add_title = 'Добавление %s <%s> как друга'
gui.dlib.friends.edit.edit_title = 'Редактирование настроек друга %s <%s>'
gui.dlib.friends.edit.going = 'Вы будете другом с %s в...'
gui.dlib.friends.edit.youare = 'Вы являетесь другом с %s в...'
gui.dlib.friends.edit.remove = 'Удалить друга'

gui.dlib.friends.invalid.title = 'Неверный SteamID'
gui.dlib.friends.invalid.ok = 'Окай :('
gui.dlib.friends.invalid.desc = '%q не выглядит как SteamID!'

gui.dlib.friends.settings.steam = 'Считать Steam друзей как DLib друзей'
gui.dlib.friends.settings.your = 'Ваши друзья ->'
gui.dlib.friends.settings.server = 'Игроки на сервере ->'

gui.dlib.friends.settings.foreign = '[Внешний] '

gui.dlib.menu.i18n.settings = 'Настройка языка DLib'
gui.dlib.menu.i18n.volume_convar = 'Отображать объем в кубических метрах вместо литров'
gui.dlib.menu.i18n.temperature_convar = 'Температура'
gui.dlib.menu.i18n.debug_convar = 'Режим отладки'
gui.dlib.menu.i18n.tooltip = "Предпочительный язык интерфейса аддонов использующих DLib.I18n\nПочти каждый аддон на DLib можно перевести на любой язык! Помогите в переводе путем присылания Merge Request'ов на GitLab соотвествующего мода"
gui.dlib.menu.i18n.iso_name = 'Код языка в ISO'
gui.dlib.menu.i18n.lang_column = 'Язык'
gui.dlib.menu.i18n.name_english = 'Имя на Английском'
gui.dlib.menu.i18n.name_self = 'Эндоэтноним'
gui.dlib.menu.i18n.move_up = 'Выше'
gui.dlib.menu.i18n.move_down = 'Ниже'

gui.dlib.donate.top = 'DLib: Сделаете пожертвование?'
gui.dlib.donate.button.yes = 'Так и сделать (Яндекс.Деньги)!'
gui.dlib.donate.button.paypal = 'Так и сделать, только на PayPal!'
gui.dlib.donate.button.no = 'Спросить меня позже'
gui.dlib.donate.button.never = 'Больше никогда не спрашивать'
gui.dlib.donate.button.learnabout = 'Прочитать про "Donationware"...'
gui.dlib.donate.button.learnabout_url = 'https://ru.wikipedia.org/wiki/Donationware'

message.dlib.hudcommons.edit.notice = 'Нажмите ESC для выхода из режима редактирования'

gui.dlib.donate.text = [[Привет! Как я вижу, Вы были долго не за клавиатурой, чтож... Я хотел бы Вас попросить:
Сделайте пожалуйста пожертвование! DLib как и аддоны котороые базируются на нем являются Donationware
Тоесть, данное ПО существует только из-за энтузиазма и (возможно) регулярных пожертвований пользователей
для поддержания автора данного ПО! Я понимаю, что времена сейчас тугие, и не прошу вас "Пожертвуй сейчас!"
Но хотел что бы Вы хотя бы прочитали данное обращение. Как вы знаете - что к примеру 50₽ это мало,
примерно столько же стоит проезд в автобусе в Москве, но давайте вдумаемся в статистику: если сейчас
абсолютно все, кто использует DLib и другие аддоны пожертвуют 50₽ каждый, то этого будет достаточно
что бы покрыть все кредиты моих родителей, а так же помочь моей Матери, которая работает с 5 утра до 22 вечера
ради того, что бы придти потом домой поспать и не высыпаться на следующий рабочий день.
Если вы сделаете пожертвование, это окажет помощь следующим аддонам, которые используются:
DLib%s]]

gui.dlib.donate.more = ' и еще %i аддонов!..'

gui.dlib.hudcommons.positions = '%s позиции'
gui.dlib.hudcommons.fonts = '%s шрифты'
gui.dlib.hudcommons.colors = '%s цвета'
gui.dlib.hudcommons.font = 'Шрифт'
gui.dlib.hudcommons.font_label = 'Настройки %s'
gui.dlib.hudcommons.save_hint = 'Не забудьте написать host_writeconfig в\nконсоле после любых изменений!'
gui.dlib.hudcommons.weight = 'Вес'
gui.dlib.hudcommons.size = 'Размер'

gui.dlib.notify.families_loading = 'Возможны подвисания, DLib печёт тортик\n(поиск установленных шрифтов)'

local prefix = {
	{'yocto',   'и',     'Иокто'},
	{'zepto',   'з',     'Зепто'},
	{'atto',    'а',     'Аптр'},
	{'femto',   'ф',     'Фемто'},
	{'pico',    'п',     'Пико'},
	{'nano',    'н',     'Нано'},
	{'micro',   'мк',    'Микро'},
	{'milli',   'м',     'Милли'},
	{'centi',   'с',     'Санти'},
	{'deci',    'д',     'Деци'},
	{'kilo',    'к',     'Кило'},
	{'mega',    'М',     'Мега'},
	{'giga',    'Г',     'Гига'},
	{'tera',    'Т',     'Тера'},
	{'peta',    'П',     'Пета'},
	{'exa',     'Э',     'Экза'},
	{'zetta',   'З',     'Зетта'},
	{'yotta',   'И',     'Иотта'},
}

for i, row in ipairs(prefix) do
	info.dlib.si.prefix[row[1]].name = row[3] or row[1]:formatname()
	info.dlib.si.prefix[row[1]].prefix = row[2]
end

info.dlib.si.units.hertz.name = "Герц"
info.dlib.si.units.hertz.suffix = "Гц"
info.dlib.si.units.radian.name = "Радиан"
info.dlib.si.units.radian.suffix = "рад"
info.dlib.si.units.steradian.name = "Стерадиан"
info.dlib.si.units.steradian.suffix = "ср"
info.dlib.si.units.newton.name = "Ньютон"
info.dlib.si.units.newton.suffix = "Н"
info.dlib.si.units.pascal.name = "Паскаль"
info.dlib.si.units.pascal.suffix = "Па"
info.dlib.si.units.joule.name = "Джоуль"
info.dlib.si.units.joule.suffix = "Дж"
info.dlib.si.units.watt.name = "Ватт"
info.dlib.si.units.watt.suffix = "Вт"
info.dlib.si.units.coulomb.name = "Кулон"
info.dlib.si.units.coulomb.suffix = "Кл"
info.dlib.si.units.volt.name = "Вольт"
info.dlib.si.units.volt.suffix = "В"
info.dlib.si.units.farad.name = "Фарад"
info.dlib.si.units.farad.suffix = "Ф"
info.dlib.si.units.ohm.name = "Ом"
info.dlib.si.units.ohm.suffix = "Ом"
info.dlib.si.units.siemens.name = "Сименс"
info.dlib.si.units.siemens.suffix = "См"
info.dlib.si.units.weber.name = "Вебер"
info.dlib.si.units.weber.suffix = "Вб"
info.dlib.si.units.tesla.name = "Тесла"
info.dlib.si.units.tesla.suffix = "Тл"
info.dlib.si.units.henry.name = "Генри"
info.dlib.si.units.henry.suffix = "Гн"
info.dlib.si.units.degree.name = "Градус Цельсия"
info.dlib.si.units.degree.suffix = "°C"
info.dlib.si.units.lumen.name = "Люмен"
info.dlib.si.units.lumen.suffix = "лм"
info.dlib.si.units.lux.name = "Люкс"
info.dlib.si.units.lux.suffix = "лк"
info.dlib.si.units.becquerel.name = "Беккерель"
info.dlib.si.units.becquerel.suffix = "Бк"
info.dlib.si.units.gray.name = "Грей"
info.dlib.si.units.gray.suffix = "Гр"
info.dlib.si.units.sievert.name = "Зиверт"
info.dlib.si.units.sievert.suffix = "Зв"
info.dlib.si.units.katal.name = "Катал"
info.dlib.si.units.katal.suffix = "кат"

info.dlib.si.units.kelvin.name = 'Кельвин'
info.dlib.si.units.kelvin.suffix = 'К'

info.dlib.si.units.celsius.name = 'Цельсий'
info.dlib.si.units.celsius.suffix = 'С'

info.dlib.si.units.fahrenheit.name = 'Фаренгейт'
info.dlib.si.units.fahrenheit.suffix = 'F'

info.dlib.si.units.gram.name = 'Грам'
info.dlib.si.units.gram.suffix = 'г'

info.dlib.si.units.metre.name = 'Метр'
info.dlib.si.units.metre.suffix = 'м'

info.dlib.si.units.litre.name = 'Литр'
info.dlib.si.units.litre.suffix = 'л'

info.dlib.si.units.second.name = 'Секунда'
info.dlib.si.units.second.suffix = 'с'

info.dlib.si.units.kmh.name = 'Километров в час'
info.dlib.si.units.kmh.suffix = 'км/ч'

gui.dlib.menu.settings.name = 'DLib'

gui.dlib.menu.settings.blur_enable = 'Включить размытие фона'
gui.dlib.menu.settings.blur_new = 'Улучшенное размытие'
gui.dlib.menu.settings.blur_passes = 'Количество проходов'
gui.dlib.menu.settings.blur_x = 'X размер'
gui.dlib.menu.settings.blur_y = 'Y размер'
gui.dlib.menu.settings.vgui_blur = 'Включить размытие для VGUI'
gui.dlib.menu.settings.screenscale = 'Рассчитывать размер на основе высоты экрана'
gui.dlib.menu.settings.screenscale_mul = 'Множитель размера'
gui.dlib.menu.settings.strict = 'Строгий режим выполнения кода'
gui.dlib.menu.settings.debug = 'Включить отладку'
gui.dlib.menu.settings.donation_never = 'Никогда не показывать окно пожертвования'
gui.dlib.menu.settings.profile_hooks_tip = 'Для просмотра результата профайлинга откройте консоль'
gui.dlib.menu.settings.profile_hooks = 'Профайлинг хуков'
gui.dlib.menu.settings.print_profile_hooks = 'Показать последние результаты профайлинга'
gui.dlib.menu.settings.reload_materials = 'Перезагрузить материалы DLib'
gui.dlib.menu.settings.replace_missing_textures = 'Подменять отсутствующие текстуры'
gui.dlib.menu.settings.oldalpha = 'Старый ползунок альфа канала'
gui.dlib.menu.settings.oldhue = 'Старый ползунок цвета'
gui.dlib.menu.settings.wangbars = 'Ползунки цвета'
