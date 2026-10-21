// ============================================================================
// LD4 pagalbinės funkcijos: statusas, skaičių skaitymas, headless apsaugos.
// ============================================================================

function ld4_set_status(msg, kind, hint)
    global LD4;
    ld4_guide_refresh();
    if argn(2) < 3 then hint = ""; end
    if argn(2) < 2 then kind = "info"; end
    if isfield(LD4, "ui") then
        if isfield(LD4.ui, "headless") then
            if LD4.ui.headless then return; end
        end
        if isfield(LD4.ui, "statusMain") & is_handle_valid(LD4.ui.statusMain) then
            LD4.ui.statusMain.string = msg;
        end
        if isfield(LD4.ui, "statusFix") & is_handle_valid(LD4.ui.statusFix) then
            LD4.ui.statusFix.string = hint;
        end
    end
endfunction

function v = ld4_parse_number(s)
    v = %nan;
    if exists("bench_safe_number") == 1 then
        v = bench_safe_number(s);
    end
endfunction

function s = ld4_trim(s)
    s = stripblanks(s);
end
