// LD11-64-A-2026: 50 Hz ritė (R ir L nuosekliai), lygiagretus Ck.
// U=5..12 V RMS, R=10..100 Ω, L=100..1500 mH; Ck apvalintas iki 0,01 µF.
// Banko formulės sutampa su core/src/model.cpp.

function cfg = ld11_variant_config(number)
    if ~ld11_valid_index(number, 64) then error("Eilės numeris turi būti nuo 1 iki 64."); end
    ev = [5;6;7;8;9;10;11;12]; rv = [10;15;22;33;47;68;82;100];
    lv = [100;150;220;330;470;680;1000;1500];
    row = floor((number-1)/8)+1; column = modulo(number-1, 8)+1;
    li = modulo(row-1+column-1, 8)+1;
    e = ev(column); r = rv(row); l = lv(li)*1e-3;
    w = 2*%pi*50; xl = w*l;
    ck = round(xl/(w*(r*r+xl*xl))*1e8)/1e8;
    cfg = struct("E", e, "R", r, "L", l, "Ck", ck, "LmH", lv(li));
endfunction

function [valid, why] = ld11_validate_config(cfg)
    valid = %f; why = "Netinkamos priskirtos reikšmės.";
    if typeof(cfg) <> "st" then return; end
    for field = ["E" "R" "L" "Ck" "LmH"]
        if ~isfield(cfg, field) then return; end
        value = cfg(field);
        if type(value) <> 1 | size(value, "*") <> 1 then return; end
        if ~isreal(value) | isnan(value) | isinf(value) then return; end
        if value <= 0 then return; end
    end
    ev = [5 6 7 8 9 10 11 12]; rv = [10 15 22 33 47 68 82 100];
    lv = [100 150 220 330 470 680 1000 1500];
    if ~or(cfg.E == ev) | ~or(cfg.R == rv) | ~or(cfg.LmH == lv) then return; end
    if abs(cfg.L - cfg.LmH*1e-3) > 1e-12 then return; end
    w = 2*%pi*50; xl = w*cfg.L;
    if abs(cfg.Ck - round(xl/(w*(cfg.R^2+xl^2))*1e8)/1e8) > 1e-12 then return; end
    valid = %t; why = "";
endfunction
