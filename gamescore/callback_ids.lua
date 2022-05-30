local M = {
    ads_start = 0xFF00,
    ads_close = 0xFF01,
    ads_fullscreen_start = 0xFF02,
    ads_fullscreen_close = 0xFF03,
    ads_preloader_start = 0xFF04,
    ads_preloader_close = 0xFF05,
    ads_rewarded_start = 0xFF06,
    ads_rewarded_close = 0xFF07,
    ads_rewarded_reward = 0xFF08,
    ads_sticky_start = 0xFF09,
    ads_sticky_render = 0xFF0A,
    ads_sticky_refresh = 0xFF0B,
    ads_sticky_close = 0xFF0C,
    player_sync = 0xFF10,
    player_load = 0xFF11,
    player_login = 0xFF12,
    player_fetch_fields = 0xFF13,
    player_change = 0xFF14,
    achievements_unlock = 0xFF20,
    achievements_unlock_error = 0xFF21,
    achievements_open = 0xFF22,
    achievements_close = 0xFF23,
    achievements_fetch = 0xFF24,
    achievements_fetch_error = 0xFF25,
    payments_purchase = 0xFF30,
    payments_purchase_error = 0xFF31,
    payments_consume = 0xFF32,
    payments_consume_error = 0xFF33,
    payments_fetch_products = 0xFF34,
    payments_fetch_products_error = 0xFF35,
    game_variables_fetch = 0xFF40,
    game_variables_fetch_error = 0xFF41,
    games_collections_open = 0xFF50,
    games_collections_close = 0xFF51,
    games_collections_fetch = 0xFF52,
    games_collections_fetch_error = 0xFF53,
    images_upload = 0xFF60,
    images_upload_error = 0xFF61,
    images_choose = 0xFF62,
    images_choose_error = 0xFF63,
    images_fetch = 0xFF64,
    images_fetch_error = 0xFF65,
    images_fetch_more = 0xFF66,
    images_fetch_more_error = 0xFF67,
    fullscreen_open = 0xFF70,
    fullscreen_close = 0xFF71,
    fullscreen_change = 0xFF72,
    documents_open = 0xFF80,
    documents_close = 0xFF81,
    documents_fetch = 0xFF82,
    documents_fetch_error = 0xFF83,
}

return M