// ============================================================================
// Bendros LD2 funkcijos
// ============================================================================

function s=ld2_num(x,digits)
    digits=max([0 min([8 round(digits)])]);
    s=msprintf("%."+string(digits)+"f",x);
endfunction

function s = ld2_value_or_dash(x, unit)
    if isnan(x) then
        s = "—";
    else
        s = ld2_num(x, 3) + " " + unit;
    end
endfunction

function v = ld2_safe_number(txt)
    v=bench_safe_number(txt);
endfunction

function ld2_set_status(msg, kind, hint)
    global LD2;
    if argn(2)<3 then hint=""; end
    LD2.state.status_text=msg;
    LD2.state.status_hint=hint;
    shown=msg;
    if hint<>"" then shown=msg+" "+hint; end
    if isfield(LD2.ui,"headless") then
        if LD2.ui.headless then return; end
    end
    if ~isfield(LD2.ui, "status") then return; end
    LD2.ui.status.string = shown;
    LD2.ui.status.tooltipstring = shown;
    select kind
    case "ok" then
        LD2.ui.status.backgroundcolor = [0.84 0.96 0.84];
        LD2.ui.status.foregroundcolor = [0.05 0.35 0.10];
    case "warn" then
        LD2.ui.status.backgroundcolor = [1.00 0.95 0.72];
        LD2.ui.status.foregroundcolor = [0.45 0.25 0.00];
    case "error" then
        LD2.ui.status.backgroundcolor = [1.00 0.84 0.84];
        LD2.ui.status.foregroundcolor = [0.55 0.05 0.05];
    else
        LD2.ui.status.backgroundcolor = [0.88 0.93 0.98];
        LD2.ui.status.foregroundcolor = [0.05 0.18 0.32];
    end
endfunction

function ld2_show_error(problem, fixes)
    global LD2;
    LD2.state.last_error=problem;
    fixes=matrix(fixes,-1,1);
    LD2.state.last_fix=strcat(fixes," ");
    if isfield(LD2.ui,"test_no_dialogs") then
        if LD2.ui.test_no_dialogs then return; end
    end
    if isfield(LD2.ui,"headless") then
        if LD2.ui.headless then return; end
    end
    ld2_set_status(problem+" "+strcat(fixes," "),"error");
    messagebox(["KLAIDA: "+problem;"";"KAIP PATAISYTI:";fixes], ...
        "LD2 – taisymo nurodymas","error","modal");
endfunction

function ld2_show_info(title, lines)
    global LD2;
    if isfield(LD2.ui,"headless") then
        if LD2.ui.headless then return; end
    end
    messagebox(matrix(lines,-1,1),title,"info","modal");
endfunction

function phase = ld2_phase_for_step(step)
    if step >= 2 & step <= 4 then
        phase = "RC";
    elseif step >= 5 & step <= 7 then
        phase = "RL";
    elseif step >= 8 & step <= 12 then
        phase = "RLC";
    else
        phase = "OVERVIEW";
    end
endfunction

function c = ld2_get_phase_connections(phase)
    global LD2;
    select phase
    case "RC" then
        c = LD2.state.rc_connections;
    case "RL" then
        c = LD2.state.rl_connections;
    case "RLC" then
        c = LD2.state.rlc_connections;
    else
        c = emptystr(0,2);
    end
endfunction

function ld2_set_phase_connections(phase, c)
    global LD2;
    select phase
    case "RC" then
        LD2.state.rc_connections = c;
    case "RL" then
        LD2.state.rl_connections = c;
    case "RLC" then
        LD2.state.rlc_connections = c;
    end
endfunction

function tf = ld2_pair(a, b, x, y)
    tf = (a == x & b == y) | (a == y & b == x);
endfunction

function tf = ld2_has_connection(c, a, b)
    tf = %f;
    for k = 1:size(c,1)
        if ld2_pair(c(k,1), c(k,2), a, b) then
            tf = %t;
            return;
        end
    end
endfunction

function tf = ld2_terminal_used(c, id)
    tf = %f;
    for k = 1:size(c,1)
        if c(k,1) == id | c(k,2) == id then
            tf = %t;
            return;
        end
    end
endfunction

function c = ld2_remove_terminal_connections(c, ids)
    keep = [];
    for k = 1:size(c,1)
        remove = %f;
        for q = 1:size(ids, "*")
            if c(k,1) == ids(q) | c(k,2) == ids(q) then
                remove = %t;
            end
        end
        if ~remove then keep($+1) = k; end
    end
    if size(keep, "*") == 0 then
        c = emptystr(0,2);
    else
        c = c(keep,:);
    end
endfunction

function lines = ld2_connection_list_text(req)
    lines = emptystr(size(req,1),1);
    for k = 1:size(req,1)
        lines(k) = msprintf("%d. %s  →  %s", k, ...
            ld2_terminal_name(req(k,1)), ld2_terminal_name(req(k,2)));
    end
endfunction

function txt = ld2_step_title(step)
    titles = [ ...
        "1. Darbo sandara ir parametrai"; ...
        "2. RC grandinės sujungimas"; ...
        "3. RC teoriniai skaičiavimai"; ...
        "4. RC matavimai ir fazoriai"; ...
        "5. RL grandinės sujungimas"; ...
        "6. RL teoriniai skaičiavimai"; ...
        "7. RL matavimai ir fazoriai"; ...
        "8. RLC rezonanso grandinės sujungimas"; ...
        "9. Rezonansinio dažnio paieška"; ...
        "10. Įtampų rezonansas: UL, UC ir ULC"; ...
        "11. -3 dB dažniai, juostos plotis ir Q"; ...
        "12. Rezonanso kreivė ir rezultatų suvestinė"];
    txt = titles(step);
endfunction

function lines = ld2_instruction_lines(step)
    // trumpa etapo instrukcija su [Bxx]/[Txx]/[Wxx]/[Axx.xx] nuorodomis;
    // pilnas turinys – ld2_method_data (metodikos langas [B41] / PAGALBA).
    d = ld2_method_data(step);
    lines = [ ...
      "TIKSLAS: "+d.goal; ...
      "EIGA:"; ...
      d.method; ...
      "Detaliau – metodikos lange (PAGALBA / [B41])."];
endfunction
