// ============================================================================
// LD10 variantų konfigūracija (bankas LD10-64-A-2026). Lygiagreti RLC
// grandinė: L pagal stulpelį, C pagal eilutę. R = round(100·Qt·sqrt(L/C))/100,
// Qt = 2..3,5 pagal (a+b)%4; srovių kokybė IL/I > 1 visuose variantuose.
// E = 5 V RMS. Skaičiavimas sutampa su core/src/model.cpp.
// ============================================================================

function cfg = ld10_variant_config(number)
    if ~ld10_valid_index(number, 64) then error("Eilės numeris turi būti nuo 1 iki 64."); end
    ls = [10;12;15;18;22;27;33;39]; cs = [47;56;68;82;100;120;150;180];
    row = floor((number-1)/8)+1; column = modulo(number-1, 8)+1;
    // Sukeistas tinklelis: L pagal stulpelį, C pagal eilutę (skiriasi nuo LD9).
    l = ls(column)*1e-3; c = cs(row)*1e-9;
    qt = 2 + 0.5*modulo(row-1+column-1, 4);
    cfg = struct("E", 5, "L", l, "C", c, ...
        "R", round(100*qt*sqrt(l/c))/100, "LmH", ls(column), "CnF", cs(row));
endfunction

function [valid, why] = ld10_validate_config(cfg)
    valid = %f; why = "Netinkamos priskirtos reikšmės.";
    if typeof(cfg) <> "st" then return; end
    for field = ["E" "R" "L" "C" "LmH" "CnF"]
        if ~isfield(cfg, field) then return; end
        value = cfg(field);
        if type(value) <> 1 | size(value, "*") <> 1 then return; end
        if ~isreal(value) | isnan(value) | isinf(value) then return; end
        if value <= 0 then return; end
    end
    if cfg.E <> 5 then return; end
    ls = [10 12 15 18 22 27 33 39]; cs = [47 56 68 82 100 120 150 180];
    if ~or(cfg.LmH == ls) | ~or(cfg.CnF == cs) then return; end
    if abs(cfg.L - cfg.LmH*1e-3) > 1e-15 | abs(cfg.C - cfg.CnF*1e-9) > 1e-18 then return; end
    qt = 2 + 0.5*modulo(find(ls == cfg.LmH) + find(cs == cfg.CnF) - 2, 4);
    if abs(cfg.R - round(100*qt*sqrt(cfg.L/cfg.C))/100) > 1e-9 then return; end
    valid = %t; why = "";
endfunction
