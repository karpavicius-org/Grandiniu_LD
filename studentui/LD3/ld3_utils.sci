// ============================================================================
// LD3 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld3_set_status(msg, kind, hint)
    global LD3;
    ld3_guide_refresh();
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD3, "ui") then
        if isfield(LD3.ui, "headless") then
            if LD3.ui.headless then return; end
        end
        if isfield(LD3.ui, "statusMain") & is_handle_valid(LD3.ui.statusMain) then
            LD3.ui.statusMain.string = msg;
        end
        if isfield(LD3.ui, "statusFix") & is_handle_valid(LD3.ui.statusFix) then
            LD3.ui.statusFix.string = hint;
        end
    end
endfunction

function v = ld3_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld3_trim(s)
    s = stripblanks(s);
end
