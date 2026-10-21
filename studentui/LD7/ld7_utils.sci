// ============================================================================
// LD7 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld7_set_status(msg, kind, hint)
    global LD7;
    if exists("ld7_guide_refresh")==1 then ld7_guide_refresh(); end
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD7, "ui") then
        if isfield(LD7.ui, "headless") then
            if LD7.ui.headless then return; end
        end
        if isfield(LD7.ui, "statusMain") & is_handle_valid(LD7.ui.statusMain) then
            LD7.ui.statusMain.string = msg;
        end
        if isfield(LD7.ui, "statusFix") & is_handle_valid(LD7.ui.statusFix) then
            LD7.ui.statusFix.string = hint;
        end
    end
endfunction

function v = ld7_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld7_trim(s)
    s = stripblanks(s);
endfunction

function ok = ld7_valid_index(value, maximum)
    ok = %f;
    if type(value) <> 1 | size(value, "*") <> 1 then return; end
    if ~isreal(value) | isnan(value) | isinf(value) then return; end
    ok = value >= 1 & value <= maximum & value == floor(value);
endfunction
