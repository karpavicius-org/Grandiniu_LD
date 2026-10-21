// ============================================================================
// LD5 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld5_set_status(msg, kind, hint)
    global LD5;
    ld5_guide_refresh();
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD5, "ui") then
        if isfield(LD5.ui, "headless") then
            if LD5.ui.headless then return; end
        end
        if isfield(LD5.ui, "statusMain") & is_handle_valid(LD5.ui.statusMain) then
            LD5.ui.statusMain.string = msg;
        end
        if isfield(LD5.ui, "statusFix") & is_handle_valid(LD5.ui.statusFix) then
            LD5.ui.statusFix.string = hint;
        end
    end
endfunction

function v = ld5_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld5_trim(s)
    s = stripblanks(s);
end
