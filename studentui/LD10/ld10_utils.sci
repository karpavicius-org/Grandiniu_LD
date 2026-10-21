// ============================================================================
// LD10 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld10_set_status(msg, kind, hint)
    global LD10;
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD10, "ui") then
        if isfield(LD10.ui, "headless") then
            if LD10.ui.headless then return; end
        end
        if isfield(LD10.ui, "statusMain") & is_handle_valid(LD10.ui.statusMain) then
            LD10.ui.statusMain.string = msg;
        end
        if isfield(LD10.ui, "statusFix") & is_handle_valid(LD10.ui.statusFix) then
            LD10.ui.statusFix.string = hint;
        end
    end
    ld10_guide_refresh();
endfunction

function v = ld10_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld10_trim(s)
    s = stripblanks(s);
endfunction

function ok = ld10_valid_index(value, maximum)
    ok = %f;
    if type(value) <> 1 | size(value, "*") <> 1 then return; end
    if ~isreal(value) | isnan(value) | isinf(value) then return; end
    ok = value >= 1 & value <= maximum & value == floor(value);
endfunction
