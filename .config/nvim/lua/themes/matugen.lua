local M = {}

-- Pobieramy funkcję pomocniczą NvChad
local lighten = require("base46.colors").change_hex_lightness

-- Matugen wstawi tutaj "dark" lub "light"
local mode = "dark"

M.base_30 = {
    -- TŁO I PODSTAWY
    white = "#e9dfee", -- W jasnym to będzie ciemny tekst, w ciemnym jasny
    black = "#201928",    -- Główne tło
    
    -- DYNAMICZNE DOPASOWANIE WARSTW (kontrast interfejsu)
    darker_black = mode == "dark" and lighten("#201928", -3) or lighten("#201928", -2),
    black2       = mode == "dark" and lighten("#201928", 6)  or lighten("#201928", -5),
    one_bg       = mode == "dark" and lighten("#201928", 10) or lighten("#201928", -10),
    
    -- KOLORYSTYKA AKCENTÓW
    red           = "#ffb4ab",
    baby_pink     = "#93000a",
    pink          = "#ecb6e3",
    green         = "#dab9ff",
    vibrant_green = "#dab9ff",
    nord_blue     = "#dbbde2",
    blue          = "#dbbde2",
    yellow        = "#ecb6e3",
    sun           = "#6500b8",
    purple        = "#dab9ff",
    dark_purple   = "#dab9ff",
    teal          = "#dbbde2",
    orange        = "#ffb4ab",
    cyan          = "#dbbde2",
    
    -- SZAROŚCI (Tekst pomocniczy i linie)
    grey       = "#968e9b",
    light_grey = "#cdc3d1",
    line       = "#4b4450",
    pmenu_bg   = "#37313d",
    folder_bg  = "#dab9ff",
}

-- OBLICZANIE WARSTW POCHODNYCH
M.base_30.statusline_bg = M.base_30.black2
M.base_30.lightbg       = M.base_30.one_bg
M.base_30.one_bg2       = mode == "dark" and lighten(M.base_30.one_bg, 6) or lighten(M.base_30.one_bg, -6)
M.base_30.one_bg3       = mode == "dark" and lighten(M.base_30.one_bg2, 6) or lighten(M.base_30.one_bg2, -6)
M.base_30.grey_fg       = mode == "dark" and lighten(M.base_30.grey, 10) or lighten(M.base_30.grey, -10)
M.base_30.grey_fg2      = mode == "dark" and lighten(M.base_30.grey, 5) or lighten(M.base_30.grey, -5)

-- MAPOWANIE BASE16 (Syntax highlighting)
M.base_16 = {
    base00 = "#201928",           -- Tło
    base01 = "#292330",
    base02 = "#2d2734",
    base03 = "#968e9b",           -- Komentarze
    base04 = "#cdc3d1",
    base05 = "#e9dfee",       -- Główny Tekst (Zmienna krytyczna!)
    base06 = "#e9dfee",
    base07 = "#4b4450",
    base08 = "#ffb4ab",             -- Zmienne
    base09 = "#ecb6e3",          -- Integery
    base0A = "#dab9ff",           -- Klasy/Typy
    base0B = "#dbbde2",         -- Stringi
    base0C = "#6500b8", -- Escape characters
    base0D = "#dbbde2",         -- Funkcje
    base0E = "#dab9ff",           -- Słowa kluczowe
    base0F = "#93000a",
}

M.type = mode

M.polish_hl = {
    Operator = { fg = M.base_30.nord_blue },
    ["@operator"] = { fg = M.base_30.nord_blue },
}

return M
