// ============================================================================
// LD11 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld11_set_status(msg, kind, hint)
    global LD11;
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    ld11_guide_refresh();
    if isfield(LD11, "ui") then
        if isfield(LD11.ui, "headless") then
            if LD11.ui.headless then return; end
        end
        if isfield(LD11.ui, "statusMain") & is_handle_valid(LD11.ui.statusMain) then
            LD11.ui.statusMain.string = msg;
        end
        if isfield(LD11.ui, "statusFix") & is_handle_valid(LD11.ui.statusFix) then
            LD11.ui.statusFix.string = hint;
        end
    end
endfunction

function v = ld11_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld11_trim(s)
    s = stripblanks(s);
endfunction

function ok = ld11_valid_index(value, maximum)
    ok = %f;
    if type(value) <> 1 | size(value, "*") <> 1 then return; end
    if ~isreal(value) | isnan(value) | isinf(value) then return; end
    ok = value >= 1 & value <= maximum & value == floor(value);
endfunction
