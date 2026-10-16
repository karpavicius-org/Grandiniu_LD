// LD12-64-A-2026: simetrinis trifazis 50 Hz šaltinis, Ul=30..220 V RMS,
// trys vienodi imtuvai R=10..100 Ω; tie patys Ul ir R abiem jungimams.
// Banko formulės sutampa su core/src/model.cpp.

function cfg = ld12_variant_config(number)
    if ~ld12_valid_index(number, 64) then error("Eilės numeris turi būti nuo 1 iki 64."); end
    uv = [30;40;50;60;100;110;127;220]; rv = [10;15;22;33;47;68;82;100];
    row = floor((number-1)/8)+1; column = modulo(number-1, 8)+1;
    cfg = struct("Ul", uv(column), "R", rv(row));
endfunction

function [valid, why] = ld12_validate_config(cfg)
    valid = %f; why = "Netinkamos priskirtos reikšmės.";
    if typeof(cfg) <> "st" then return; end
    for field = ["Ul" "R"]
        if ~isfield(cfg, field) then return; end
        value = cfg(field);
        if type(value) <> 1 | size(value, "*") <> 1 then return; end
        if ~isreal(value) | isnan(value) | isinf(value) then return; end
        if value <= 0 then return; end
    end
    if ~or(cfg.Ul == [30 40 50 60 100 110 127 220]) then return; end
    if ~or(cfg.R == [10 15 22 33 47 68 82 100]) then return; end
    valid = %t; why = "";
endfunction
