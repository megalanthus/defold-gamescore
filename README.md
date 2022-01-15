# GameScore for Defold

[GameScore](https://gs.eponesh.com) расширение для движка [Defold](https://defold.com). GameScore это сервис для удобной
публикации HTML5 игр на разных платформах с одним SDK. Сервисом поддерживается локальная отладка игры.

- [Установка](#installation)
- [Инициализация](#initialize)
- [Заглушка для других платформ, отличных от html](#mock)
- [API](#api)

<a name="installation"></a>

## Установка

Вы можете использовать его в своем собственном проекте, добавив этот проект в
качестве [зависимости библиотеки Defold](https://defold.com/manuals/libraries/).

<a name="initialize"></a>

## Инициализация

В файл game.project необходимо добавить раздел gamescore и указать id и token игры, остальные параметры можно опустить:

```
[gamescore]
id = идентификатор игры
token = токен
description = There are not enough words to describe the awesomeness of the game
image = /img/ogimage.png
```

Дополнительные параметры: [(doc)](https://gs.eponesh.com/ru/docs/#socials-intro)

Для начала необходимо инициализировать SDK с помощью метода init:

```lua
local gamescore = require("gamescore.gamescore")

gamescore.init(function(success)
    if success then
        -- инициализация прошла успешно
    else
        -- ошибка инициализации
    end
end)
```

Для подписки на событие необходимо определить соответсвующий метод таблицы callbacks:

```lua
local gamescore = require("gamescore.gamescore")

local function ads_start()
    -- выключаем звук
end

local function ads_end(success)
    -- включаем звук
end

local function ads_reward()
    -- подкидываем золотишка игроку
end

-- функции событий можно назначить до инициализации SDK
gamescore.callbacks.ads_start = ads_start
gamescore.callbacks.ads_end = ads_end
gamescore.callbacks.ads_rewarded_reward = ads_reward
-- инициализация SDK
gamescore.init(function(success)
    if success then
        -- показываем прелоадер
        gamescore.ads_show_preloader(function(result)
            -- реклама закрыта, можно что-то делать
        end)
        -- что то делаем еще

        -- показываем рекламу за вознаграждение 
        gamescore.ads_show_rewarded_video()

        -- показываем рекламу за вознаграждение с использованием колбека
        gamescore.ads_show_rewarded_video(function(result)
            if result then
                -- подкидываем игроку кристаллов
            end
        end)
    else
        -- ошибка инициализации
    end
end)
```

<a name="mock"></a>

## Заглушка для других платформ, отличных от html

Для платформ отличных от html предусмотрены заглушки для удобства отладки.

При использовании функций:

- player_get(key)
- player_set(key, value)
- player_add(key, value)
- player_toggle(key)
- player_has(key)
- player_to_json()
- player_from_json(player)

данные будут сохраняться/считываться с помощью sys.save()/sys.load() локально в/из файла "gamescore.dat" (можно
поменять)

```lua
local mock_api = require("gamescore.mock_api")

-- установим имя для файла локального хранилища данных
mock_api.file_storage = "my_storage.dat"

-- установка параметров "заглушек"
mock_api.player.name = "my player name"
mock_api.player.id = 625

-- или так
mock_api.player = function()
    return {
        isLoggedIn = false,
        hasAnyCredentials = false,
        id = 234,
        score = 500,
        name = "player name",
        avatar = "avatar",
        isStub = true,
        fields = mock_api.fields_data
    }
end
```

Каждая функция-заглушка GameScore API может быть представлена таблицей данных или функцией выполняющее действие и/или
возвращающая данные. Любые функции/данные можно переопределять для удобства работы/отладки.

<a name="api"></a>

## API

| GameScore JS SDK                   | GameScore Lua API |
| ---------------------------------- | ----------------- |
| **Инициализация** [(doc)](https://gs.eponesh.com/ru/docs/#start-init-sdk)
| `window.onGSInit`                  | `init(callback)`<br> Инициализация модуля<br> после инициализации будет вызвана функция callback(success) с результатом
| **Язык** [(doc)](https://gs.eponesh.com/ru/docs/#language)
| `gs.language`                      | `language()`<br> Выбранный язык в формате ISO 639-1
| `gs.changeLanguage(languagecode)`  | `changelanguage(languagecode)`<br> Устанавливает язык в формате ISO 639-1<br> languagecode = string
| **Приложение** [(doc)](https://gs.eponesh.com/ru/docs/#app)
| `gs.app`                           | `app()`<br> Возвращает таблицу с информацией о приложении:<br> title: Заголовок<br> description: Описание<br> image: Изображение<br> url: URL на платформе
| **Платформа** [(doc)](https://gs.eponesh.com/ru/docs/#platform)
| `gs.platform`                      | `platform()`<br> Возвращает таблицу с информацией о платформе:<br> type: Тип платформы, например YANDEX, VK<br> hasIntegratedAuth: Возможность авторизации<br> isExternalLinksAllowed: Возможность размещать внешние ссылки
| **Реклама** [(doc)](https://gs.eponesh.com/ru/docs/#ads)
| `gs.ads`                           | `ads()`<br> Возвращает таблицу с информацией о менеджере рекламы:<br> isAdblockEnabled: Включен ли адблок<br> isStickyAvailable, isFullscreenAvailable, isRewardedAvailable, isPreloaderAvailable: Доступен ли баннер<br> isStickyPlaying, isFullscreenPlaying, isRewardedPlaying, isPreloaderPlaying: Играет ли сейчас реклама
| `gs.ads.showFullscreen()`          | `ads_show_fullscreen(callback)`<br> Показывает полноэкранную рекламу<br> callback(result) функция обратного вызова или nil
| `gs.ads.showPreloader()`           | `ads_show_preloader(callback)`<br> Показывает баннерную рекламу (preloader)<br> callback(result) функция обратного вызова или nil
| `gs.ads.showRewardedVideo()`       | `ads_show_rewarded_video(callback)`<br> Показывает рекламу за вознаграждение<br> callback(result) функция обратного вызова или nil
| `gs.ads.showSticky()`              | `ads_show_sticky(callback)`<br> Показывает баннер<br> callback(result) функция обратного вызова или nil
| `gs.ads.refreshSticky()`           | `ads_refresh_sticky(callback)`<br> Принудительное обновление баннера<br> callback(result) функция обратного вызова или nil
| `gs.ads.closeSticky()`             | `ads_close_sticky(callback)`<br> Закрывает баннер<br> callback() функция обратного вызова или nil
| | События:
| `gs.ads.on('start', () => {})`     | `callbacks.ads_start()`<br> Показ рекламы
| `gs.ads.on('close', (success) => {})` | `callbacks.ads_close(success)`<br> Закрытие рекламы
| `gs.ads.on('fullscreen:start', () => {})` | `callbacks.ads_fullscreen_start()`<br> Показ полноэкранной рекламы
| `gs.ads.on('fullscreen:close', (success) => {})` | `callbacks.ads_fullscreen_close(success)`<br> Закрытие полноэкранной рекламы
| `gs.ads.on('preloader:start', () => {})` | `callbacks.ads_preloader_start()`<br> Показ preloader рекламы
| `gs.ads.on('preloader:close', (success) => {})` | `callbacks.ads_preloader_close(success)`<br> Закрытие preloader рекламы
| `gs.ads.on('rewarded:start', () => {})` | `callbacks.ads_rewarded_start()`<br> Показ рекламы за вознаграждение
| `gs.ads.on('rewarded:close', (success) => {})` | `callbacks.ads_rewarded_close(success)`<br> Закрытии рекламы за вознаграждение
| `gs.ads.on('rewarded:reward', () => {})` | `callbacks.ads_rewarded_reward()`<br> Получение награды за просмотр рекламы
| `gs.ads.on('sticky:start', () => {})` | `callbacks.ads_sticky_start()`<br> Показ sticky баннера
| `gs.ads.on('sticky:render', () => {})` | `callbacks.ads_sticky_render()`<br> Рендер sticky баннера
| `gs.ads.on('sticky:refresh', () => {})` | `callbacks.ads_sticky_refresh()`<br> Обновление sticky баннера
| `gs.ads.on('sticky:close', () => {})` | `callbacks.ads_sticky_close()`<br> Закрытие sticky баннера
| **Игрок** [(doc)](https://gs.eponesh.com/ru/docs/#player-manager)
| `gs.player`                        | `player()`<br> Возвращает таблицу с информацией об игроке:<br> isLoggedIn: Игрок авторизован<br> hasAnyCredentials: Игрок использует один из способов входа<br> id: Идентификатор игрока <br> score: Очки <br> name: Имя <br> avatar: Ссылка на аватар <br> isStub: Заглушка — пустой ли игрок или данные в нём отличаются умолчательных <br> fields: Поля игрока [(doc)](https://gs.eponesh.com/ru/docs/#player-state-fields)
| `gs.player.sync()`<br> `gs.player.sync({ override: true })` | `player_sync(parameters, callback)`<br> Синхронизирует игрока<br> parameters = {override = boolean или nil, silent = boolean или nil} или nil<br> callback(): функция обратного вызова или nil
| `gs.player.load()`                 | `player_load(callback)`<br> Принудительная загрузка игрока, с перезаписью локального<br> callback(): функция обратного вызова или nil
| `gs.player.login()`                | `player_login(callback)`<br> Вход игрока<br> callback(result): функция обратного вызова или nil
| `gs.player.fetchFields()`          | `player_fetch_fields(callback)`<br> Получить список полей игрока<br> callback(): функция обратного вызова или nil
| `gs.player.get(key)`               | `player_get(key)`<br> Получить значение поля key<br> key = string
| `gs.player.set(key, value)`        | `player_set(key, value)`<br> Установить значение поля key<br> key = string<br> value = string, number или boolean
| `gs.player.add(key, value)`        | `player_add(key, value)`<br> Добавить значение к полю key<br> key = string<br> value = string, number или boolean
| `gs.player.toggle(key)`            | `player_toggle(key)`<br> Инвертировать состояние поля key<br> key = string<br> value = string, number или boolean
| `gs.player.has(key)`               | `player_has(key)`<br> Проверить есть ли поле key и оно не пустое (не 0, '', false, null, undefined)<br> key = string
| `gs.player.toJSON()`               | `player_to_json()`<br> Возвращает состояние игрока объектом (таблицей)
| `gs.player.fromJSON()`             | `player_from_json(player)`<br> Устанавливает состояние игрока из объекта (таблицы)<br> player = {key = value, key2 = value2}
| `gs.player.reset()`                | `player_reset()`<br> Сбрасывает состояние игрока на умолчательное
| `gs.player.remove()`               | `player_remove()`<br> Удаляет игрока — сбрасывает поля и очищает ID
| `gs.player.getField(key)`          | `player_get_field(key)`<br> Получить поле по ключу key<br> key = string
| `gs.player.getFieldName(key)`      | `player_get_field_name(key)`<br> Получить переведенное имя поля по ключу key<br> key = string
| `gs.player.getFieldVariantName(key, value)` | `player_get_field_variant_name(key, value)`<br> Получить переведенное имя варианта поля (enum) по ключу key и его значению value<br> key = string<br> value = string
| | События:
| `gs.player.on('sync', (success) => {})` | `callbacks.player_sync(success)`<br> Синхронизация игрока
| `gs.player.on('load', (success) => {})` | `callbacks.player_load(success)`<br> Загрузка игрока
| `gs.player.on('login', (success) => {})` | `callbacks.player_login(success)`<br> Вход игрока
| `gs.player.on('fetchFields', (success) => {})` | `callbacks.player_fetch_fields(success)`<br> Получение полей игрока
| `gs.player.on('change', () => {})` | `callbacks.player_change()`<br> Изменение полей игрока
| **Таблица лидеров** [(doc)](https://gs.eponesh.com/ru/docs/#leaderboard)
| `gs.leaderboard.open()`<br> `gs.leaderboard.open(parameters)` | `leaderboard_open(parameters)`<br> Показать таблицу лидеров во внутриигровом оверлее, parameters таблица параметров вывода или nil
| `gs.leaderboard.fetch()`<br> `gs.leaderboard.fetch(parameters)` | `leaderboard_fetch(parameters, callback)`<br> Получить таблицу лидеров<br> parameters: таблица параметров вывода или nil<br> callback(leaders): или nil
| `gs.leaderboard.fetchPlayerRating()`<br> `gs.leaderboard.fetchPlayerRating(parameters)` | `leaderboard_fetch_player_rating(parameters, callback)`<br> Получить рейтинг игрока<br> parameters: таблица параметров вывода или nil<br> callback(leaders): или nil
| **Достижения** [(doc)](https://gs.eponesh.com/ru/docs/#achievements)
| `gs.achievements.unlock(achievement)` | `achievements_unlock(achievement, callback)`<br> Разблокировать достижение<br> achievement: id или tag достижения<br> callback(result): функция обратного вызова с результатом разблокировки достижения
| `gs.achievements.open()`           | `achievements_open(callback)`<br> Открыть достижения в оверлее<br> callback: функция обратного вызова при открытии окна достижений
| `gs.achievements.fetch()`          | `achievements_fetch(callback)`<br> Запросить достижения<br> callback(achievements): функция обратного вызова с достижениями
| | События:
| `gs.achievements.on('unlock', (achievement) => {})` | `callbacks.achievements_unlock(achievement)`<br> Разблокировка достижения
| `gs.achievements.on('error:unlock', (error) => {})` | `callbacks.achievements_unlock_error(error)`<br> Ошибка разблокировки достижения
| `gs.achievements.on('open', () => {})` | `callbacks.achievements_open()`<br> Открытие списка достижений в оверлее
| `gs.achievements.on('close', () => {})` | `callbacks.achievements_close()`<br> Закрытие списка достижений
| `gs.achievements.on('fetch', (result) => {})` | `callbacks.achievements_fetch(result)`<br> Получение списка достижений
| `gs.achievements.on('error:fetch', (error) => {})` | `callbacks.achievements_fetch_error(error)`<br> Ошибка получения списка достижений
| **Платежи** [(doc)](https://gs.eponesh.com/ru/docs/#payments)
| `gs.payments.isAvailable`         | `payments_is_available()`<br> Проверка поддержки платежей на платформе
| `gs.payments.purchase(product)`   | `payments_purchase(product, callback)`<br> Покупка продукта<br> product = number или string, id или tag продукта<br> callback(result): функция обратного вызова или nil
| `gs.payments.consume(product)`    | `payments_consume(product, callback)`<br> Использование продукта<br> product = number или string, id или tag продукта<br> callback(result): функция обратного вызова или nil
| `gs.payments.has(product)`        | `payments_has(product)`<br> Проверка наличия покупки<br> product: id или tag продукта
| | События:
| `gs.payments.on('purchase', (result) => {})` | `callbacks.payments_purchase(result)`<br> Покупка продукта
| `gs.payments.on('error:purchase', (error) => {})` | `callbacks.payments_purchase_error(error)`<br> Ошибка покупки продукта
| `gs.payments.on('consume', (result) => {})` | `callbacks.payments_consume(result)`<br> Использование продукта
| `gs.payments.on('error:consume', (error) => {})` | `callbacks.payments_consume_error(error)`<br> Ошибка использования продукта
| `gs.payments.on('fetchProducts', (result) => {})` | `callbacks.payments_fetch_products(result)`<br> Получение списка продуктов
| `gs.payments.on('error:fetchProducts', (error) => {})` | `callbacks.payments_fetch_products_error(error)`<br> Ошибка получения списка продуктов
| **Социальные действия** [(doc)](https://gs.eponesh.com/ru/docs/#socials)
| `gs.socials`                      | `socials()`<br> Возвращает таблицу с информацией о возможных социальных действиях<br> isSupportsNativeShare: поддерживается ли нативный шаринг<br> isSupportsNativePosts: поддерживается ли нативный постинг<br> isSupportsNativeInvite: поддерживаются ли нативные инвайты<br> canJoinCommunity: можно ли приглашать в сообщество на текущей платформе<br> isSupportsNativeCommunityJoin: поддерживается ли нативное вступление в сообщество
| `gs.socials.share(parameters)`    | `socials_share(parameters)`<br> Поделиться<br> parameters: таблица с параметрами или nil
| `gs.socials.post(parameters)`     | `socials_post(parameters)`<br> Опубликовать пост<br> parameters: таблица с параметрами или nil
| `gs.socials.invite(parameters)`   | `socials_invite(parameters)`<br> Пригласить друзей<br> parameters: таблица с параметрами или nil
| `gs.socials.joinCommunity()`      | `socials_join_community()`<br> Вступить в сообщество
| **Подборки игр** [(doc)](https://gs.eponesh.com/ru/docs/#games-collections)
| `gs.gamesCollections.open(collection)` | `games_collections_open(collection, callback)`<br> Открыть оверлей с играми<br> collection = number или string, id или tag коллекции или nil<br> callback(): Функция обратного вызова или nil
| `gs.gamesCollections.fetch(collection)` | `games_collections_fetch(collection, callback)`<br> Получить коллекцию игр<br> collection = number или string, id или tag коллекции или nil<br> callback(result): Функция обратного вызова или nil
| | События:
| `gs.gamesCollections.on('open', () => {})` | `callbacks.games_collections_open()`<br> Открыт оверлей с играми
| `gs.gamesCollections.on('close', () => {})` | `callbacks.games_collections_close()`<br> Закрыт оверлей с играми
| `gs.gamesCollections.on('fetch', (result) => {})` | `callbacks.games_collections_fetch(result)`<br> Получение коллекции игр
| `gs.gamesCollections.on('error:fetch', (error) => {})` | `callbacks.games_collections_fetch_error(error)`<br> Ошибка получения коллекции игр
| **Аналитика** [(doc)](https://gs.eponesh.com/ru/docs/#analytics)
| `gs.analytics.hit(url)`           | `analytics_hit(url)`<br> Посещение или просмотр страницы
| `gs.analytics.goal(event, value)` | `analytics_goal(event, value)`<br> Отправка достижения цели
| **Полный экран** [(doc)](https://gs.eponesh.com/ru/docs/#fullscreen)
| `gs.fullscreen.open()`            | `fullscreen_open()`<br> Войти в полноэкранный режим
| `gs.fullscreen.close()`           | `fullscreen_close()`<br> Выйти из полноэкранного режима
| `gs.fullscreen.toggle()`          | `fullscreen_toggle()`<br> Переключить полноэкранный режим
| | События:
| `gs.fullscreen.on('open', () => {})` | `callbacks.fullscreen_open()`<br> Вход в полноэкранный режим
| `gs.fullscreen.on('close', () => {})` | `callbacks.fullscreen_close()`<br> Выход из полноэкранного режима
| `gs.fullscreen.on('change', () => {})` | `callbacks.fullscreen_change()`<br> Переключение полноэкранного режима
