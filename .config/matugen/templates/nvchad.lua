local M = {}

-- Pobieramy funkcję pomocniczą NvChad
local lighten = require("base46.colors").change_hex_lightness

-- Matugen wstawi tutaj "dark" lub "light"
local mode = "{{mode}}"

M.base_30 = {
    -- TŁO I PODSTAWY
    white = "{{colors.on_surface.default.hex}}", -- W jasnym to będzie ciemny tekst, w ciemnym jasny
    black = "{{colors.surface.default.hex | lighten:4}}",    -- Główne tło
    
    -- DYNAMICZNE DOPASOWANIE WARSTW (kontrast interfejsu)
    darker_black = mode == "dark" and lighten("{{colors.surface.default.hex | lighten:4}}", -3) or lighten("{{colors.surface.default.hex | lighten:4}}", -2),
    black2       = mode == "dark" and lighten("{{colors.surface.default.hex | lighten:4}}", 6)  or lighten("{{colors.surface.default.hex | lighten:4}}", -5),
    one_bg       = mode == "dark" and lighten("{{colors.surface.default.hex | lighten:4}}", 10) or lighten("{{colors.surface.default.hex | lighten:4}}", -10),
    
    -- KOLORYSTYKA AKCENTÓW
    red           = "{{colors.error.default.hex}}",
    baby_pink     = "{{colors.error_container.default.hex}}",
    pink          = "{{colors.tertiary.default.hex}}",
    green         = "{{colors.primary.default.hex}}",
    vibrant_green = "{{colors.primary.default.hex}}",
    nord_blue     = "{{colors.secondary.default.hex}}",
    blue          = "{{colors.secondary.default.hex}}",
    yellow        = "{{colors.tertiary.default.hex}}",
    sun           = "{{colors.primary_container.default.hex}}",
    purple        = "{{colors.primary.default.hex}}",
    dark_purple   = "{{colors.primary.default.hex}}",
    teal          = "{{colors.secondary.default.hex}}",
    orange        = "{{colors.error.default.hex}}",
    cyan          = "{{colors.secondary.default.hex}}",
    
    -- SZAROŚCI (Tekst pomocniczy i linie)
    grey       = "{{colors.outline.default.hex}}",
    light_grey = "{{colors.on_surface_variant.default.hex}}",
    line       = "{{colors.outline_variant.default.hex}}",
    pmenu_bg   = "{{colors.surface_container_high.default.hex | lighten:4}}",
    folder_bg  = "{{colors.primary.default.hex}}",
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
    base00 = "{{colors.surface.default.hex | lighten:4}}",           -- Tło
    base01 = "{{colors.surface_container_low.default.hex | lighten:4}}",
    base02 = "{{colors.surface_container.default.hex | lighten:4}}",
    base03 = "{{colors.outline.default.hex}}",           -- Komentarze
    base04 = "{{colors.on_surface_variant.default.hex}}",
    base05 = "{{colors.on_surface.default.hex}}",       -- Główny Tekst (Zmienna krytyczna!)
    base06 = "{{colors.on_surface.default.hex}}",
    base07 = "{{colors.outline_variant.default.hex}}",
    base08 = "{{colors.error.default.hex}}",             -- Zmienne
    base09 = "{{colors.tertiary.default.hex}}",          -- Integery
    base0A = "{{colors.primary.default.hex}}",           -- Klasy/Typy
    base0B = "{{colors.secondary.default.hex}}",         -- Stringi
    base0C = "{{colors.primary_container.default.hex}}", -- Escape characters
    base0D = "{{colors.secondary.default.hex}}",         -- Funkcje
    base0E = "{{colors.primary.default.hex}}",           -- Słowa kluczowe
    base0F = "{{colors.error_container.default.hex}}",
}

M.type = mode

M.polish_hl = {
    Operator = { fg = M.base_30.nord_blue },
    ["@operator"] = { fg = M.base_30.nord_blue },
}

return M
