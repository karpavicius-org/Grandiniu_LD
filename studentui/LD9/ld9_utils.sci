// ============================================================================
// LD9 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld9_set_status(msg, kind, hint)
    global LD9;
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD9, "ui") then
        if isfield(LD9.ui, "headless") then
            if LD9.ui.headless then return; end
        end
        if isfield(LD9.ui, "statusMain") & is_handle_valid(LD9.ui.statusMain) then
            LD9.ui.statusMain.string = msg;
        end
        if isfield(LD9.ui, "statusFix") & is_handle_valid(LD9.ui.statusFix) then
            LD9.ui.statusFix.string = hint;
        end
    end
    ld9_guide_refresh();
endfunction

function v = ld9_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld9_trim(s)
    s = stripblanks(s);
endfunction

function ok = ld9_valid_index(value, maximum)
    ok = %f;
    if type(value) <> 1 | size(value, "*") <> 1 then return; end
    if ~isreal(value) | isnan(value) | isinf(value) then return; end
    ok = value >= 1 & value <= maximum & value == floor(value);
endfunction
