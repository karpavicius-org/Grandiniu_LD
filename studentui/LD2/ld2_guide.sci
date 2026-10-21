// LD2: state-aware guide + visible automatic virtual experiment button.
// Built on LD1: show ONE next action and highlight the relevant contact/control.
// The guide itself never writes student answers or measurements. A separate
// deliberately clicked ld2_auto_stage() callback performs traceable operations.

function line=ld2_guide_terminal(id)
    code=ld2_terminal_code(id);
    line="["+code+"] "+strsubst(ld2_terminal_name(id),code+" – ","");
endfunction

function [lines,focus]=ld2_guide_pair(first,second,context)
    global LD2;
    chosen=LD2.state.selected_terminal;
    focus=[first;second];
    if chosen==first then
        focus=second;
        lines=[context; "Jau pasirinkote "+ld2_guide_terminal(first)+"."; ...
            "Dabar spauskite "+ld2_guide_terminal(second)+"."];
    elseif chosen==second then
        focus=first;
        lines=[context; "Jau pasirinkote "+ld2_guide_terminal(second)+"."; ...
            "Dabar spauskite "+ld2_guide_terminal(first)+"."];
    elseif chosen<>"" then
        focus=chosen;
        lines=[context; "Dabar pažymėtas kitas kontaktas: "+ld2_guide_terminal(chosen)+"."; ...
               "Paspauskite jį dar kartą, kad atšauktumėte pasirinkimą."];
    else
        lines=[context; "Spauskite "+ld2_guide_terminal(first)+"."; ...
            "Tada spauskite "+ld2_guide_terminal(second)+"."];
    end
endfunction

function [lines,focus,button]=ld2_guide_probe(phase,target)
    // The expected pair is determined by a real component, never by a hardcoded screen pixel.
    global LD2;
    focus=emptystr(0,1); button="";
    pair=ld2_probe_pair(phase,target);
    if size(pair,"*")<>2 then
        lines="Atverkite Pagalba → Kontaktų žinynas."; return;
    end
    c=ld2_get_phase_connections(phase);
    h1=ld2_has_connection(c,"VM_H",pair(1)); h2=ld2_has_connection(c,"VM_H",pair(2));
    l1=ld2_has_connection(c,"VM_L",pair(1)); l2=ld2_has_connection(c,"VM_L",pair(2));
    // Correct partial connection: keep it and point to the only missing probe.
    if h1 & ~ld2_terminal_used(c,"VM_L") then
        [lines,focus]=ld2_guide_pair("VM_L",pair(2),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif h2 & ~ld2_terminal_used(c,"VM_L") then
        [lines,focus]=ld2_guide_pair("VM_L",pair(1),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif l2 & ~ld2_terminal_used(c,"VM_H") then
        [lines,focus]=ld2_guide_pair("VM_H",pair(1),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif l1 & ~ld2_terminal_used(c,"VM_H") then
        [lines,focus]=ld2_guide_pair("VM_H",pair(2),"Užbaikite "+target+" voltmetro jungimą:");return;
    end
    // Other probe connections, including a wrongly completed pair: reset only probes.
    if ld2_terminal_used(c,"VM_H") | ld2_terminal_used(c,"VM_L") then
        lines=["Voltmetras dabar prijungtas ne prie reikiamo "+target+" taikinio."; ...
               "Stendo apačioje spauskite Nuimti zondus [B13]."; ...
               "Pagrindinės grandinės laidai liks nepakitę."];
        button="ld2_remove_voltage_probes()";return;
    end
    [lines,focus]=ld2_guide_pair("VM_H",pair(1),"Pradėkite "+target+" įtampos matavimą:");
endfunction

function yes=ld2_guide_peak_done(target)
    global LD2;
    yes=%f;
    idx=find(LD2.state.peak_target==target);
    if size(idx,"*")<3 then return; end
    [f,u,ok]=ld2_peak_best(target);
    if ~ok then return; end
    sample=LD2.state.peak_f(idx);
    if min(sample)>=f | max(sample)<=f then return; end
    if target=="ULC" & u>0.1*LD2.cfg.E_RLC then return; end
    yes=%t;
endfunction

function yes=ld2_guide_enabled()
    global LD2;
    yes=%f;
    if typeof(LD2)<>"st" then return; end
    if isfield(LD2,"guide_enabled") then yes=LD2.guide_enabled; end
endfunction

function lines=ld2_stage_purpose(step)
    select step
    case 1 then lines="Tirsime kintamąją srovę: kaip įtampa pasiskirsto tarp rezistoriaus, kondensatoriaus ir ritės.";
    case 2 then lines="RC grandinę sudaro rezistorius R ir kondensatorius C. Šiame etape paruošiama jų grandinė.";
    case 4 then lines="Palyginkite RC grandinės šaltinio įtampą su iš dviejų rodmenų apskaičiuota įtampa.";
    case 5 then lines="RL grandinę sudaro rezistorius R ir ritė L. Šiame etape paruošiama jų grandinė.";
    case 7 then lines="Palyginkite RL grandinės šaltinio įtampą su iš dviejų rodmenų apskaičiuota įtampa.";
    case 8 then lines="RLC grandinėje kartu yra rezistorius, ritė ir kondensatorius. Toliau tirsime dažnio poveikį.";
    case 9 then lines="Rezonansas – dažnis, ties kuriuo šioje grandinėje rezistoriaus įtampa yra didžiausia.";
    case 10 then lines="UL yra ritės, UC – kondensatoriaus įtampa. ULC yra bendra šių dviejų elementų įtampa.";
    case 11 then lines="BW vadinama dažnių juosta: skirtumas tarp parodytų ribinių dažnių f2 ir f1.";
    case 12 then lines="Peržiūrėkite tyrimo kreivę ir išsaugokite originalią HTML ataskaitą.";
    else lines=ld2_workflow_title(step);
    end
endfunction

function [lines,focus,button,answer]=ld2_guide_next()
    global LD2;
    focus=emptystr(0,1);button="";answer=0;step=LD2.state.step;
    if LD2.example_active then
        lines="Rodomas pavyzdys. Grįžkite į savo darbą.";button="ld2_student_primary()";return;
    end
    if step==1 then
        lines=["Patikrinkite savo vardą ir variantą.";"Spauskite Pradėti →."];button="ld2_student_primary()";return;
    end
    [action,ready]=ld2_auto_stage_status(step);
    if ~ready then
        if or(step==[2 5 8]) then
            [ok,missing]=ld2_validate_main(ld2_phase_for_step(step));
            [pairtext,focus]=ld2_guide_pair(missing(1,1),missing(1,2),"");
            lines=[pairtext;"Jungti galite ir mygtuku „"+action+"“ po grandine."];
        else lines=["Po grandine spauskite „"+action+"“.";"Rodmenys atsiras dešinėje."];end
        button="ld2_auto_stage()";return;
    end
    [ok,why]=ld2_workflow_ready();
    if ~ok then
        if step==11 then
            lines=["Abu dažniai jau išmatuoti.";"Įrašykite jų skirtumą: BW = f2 - f1."];answer=1;
        else lines=why;end
        return;
    end
    if step==12 then lines="Darbas užbaigtas. Spauskite Išsaugoti ataskaitą.";
    else
        lines=["Bandymas ir jūsų atsakymas paruošti.";"Spauskite „"+ld2_primary_label(step)+"“."];
        if ld2_primary_label(step)=="Patikrinti" then lines=[lines;"Po patikrinimo spauskite „Toliau →“."];end
    end
    button="ld2_student_primary()";
endfunction

function ld2_guide_refresh()
    // Update only visible guidance and input focus; never rebuild the window while typing.
    global LD2;
    enabled=ld2_guide_enabled();
    lines=ld2_stage_purpose(LD2.state.step);button="";answer=0;
    if enabled then [lines,focus,button,answer]=ld2_guide_next(); end
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    if isfield(LD2.ui,"guide_text") then
        if is_handle_valid(LD2.ui.guide_text) then
            LD2.ui.guide_text.string=student_wrap(lines,34);
        end
    end
    if isfield(LD2.ui,"answer_edits") then
        for k=1:size(LD2.ui.answer_edits,"*")
            h=LD2.ui.answer_edits(k);
            if is_handle_valid(h) & h.enable=="on" then
                h.backgroundcolor=[0.94 0.96 0.96];
                if answer==k then h.backgroundcolor=[1.00 0.92 0.65]; end
            end
        end
    end
    if isfield(LD2.ui,"studentPrimary") then
        h=LD2.ui.studentPrimary;
        if is_handle_valid(h) then
            [ready,why]=ld2_workflow_ready();
            if ready | LD2.example_active then h.enable="on";else h.enable="off";end
            if button=="ld2_student_primary()" then
                h.backgroundcolor=[0.97 0.72 0.26];h.foregroundcolor=[0.16 0.16 0.10];
            else
                h.backgroundcolor=[0.08 0.39 0.37];h.foregroundcolor=[1 1 1];
            end
        end
    end
    student_guide_update("LD2",string(ld2_visible_ordinal(LD2.state.step))+" etapas · "+ld2_workflow_title(LD2.state.step), ...
        ld2_workflow_help(LD2.state.step),enabled);
endfunction

function ld2_guide_show()
    global LD2;
    LD2.guide_enabled=%t;
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    ld2_render_step();ld2_guide_refresh();
endfunction

function ld2_guide_close()
    global LD2;
    LD2.guide_enabled=%f;
    student_guide_hide("LD2");
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    ld2_render_step();ld2_guide_refresh();
endfunction
