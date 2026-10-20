// Only state/config are serialised, never UI handles.
function ld2_save_work()
    global LD2;
    if LD2.example_active then
        ld2_show_error("Pavyzdys nėra jūsų darbas.",["Pirma spauskite MANO DARBAS, tada IŠSAUGOTI."]); return;
    end
    ld2_save_answers();
    name=uiputfile("*.sod",LD2.root,"Išsaugoti LD2 darbą");
    if size(name,"*")==0 then return; end
    if type(name)<>10 then return; end
    if stripblanks(name)=="" then return; end
    path=name;
    if length(path)<4 then path=path+".sod";
    elseif convstr(part(path,length(path)-3:length(path)),"l")<>".sod" then path=path+".sod"; end
    try
        ld2_write_session(path);
        ld2_set_status("Darbas išsaugotas: "+path,"ok");
    catch
        ld2_show_error("Nepavyko išsaugoti darbo.",[lasterror();"Pasirinkite aplanką, kuriame turite rašymo teises."]);
    end
endfunction

function ld2_load_work()
    global LD2;
    if LD2.example_active then ld2_show_error("Pirmiausia uždarykite pavyzdį.",["Spauskite MANO DARBAS."]); return; end
    name=uigetfile("*.sod",LD2.root,"Atverti išsaugotą LD2 darbą");
    if size(name,"*")==0 then return; end
    if type(name)<>10 then return; end
    if stripblanks(name)=="" then return; end
    path=name;
    try
        session=ld2_read_session(path);
    catch
        ld2_show_error("Sesija neįkelta; jūsų dabartinis darbas nepakeistas.",[lasterror();"Pasirinkite šios versijos IŠSAUGOTI sukurtą .sod failą."]); return;
    end
    ld2_restore_session(session);
endfunction

function ld2_write_session(path)
    global LD2;
    if LD2.example_active then error("Pavyzdys nėra studento darbas."); end
    ld2_save_answers();
    session=struct("format","LD2-1.2","cfg",LD2.cfg,"state",LD2.state);
    save(path,"session");
endfunction

function session=ld2_read_session(path)
        load(path,"session");
        if ~isfield(session,"format") then error("Ne LD2 sesijos failas."); end
        if session.format<>"LD2-1.1" & session.format<>"LD2-1.2" then error("Reikia LD2 v1.1 arba v1.2 sesijos failo."); end
        [valid,why]=ld2_validate_config(session.cfg);
        if ~valid then error(why); end
        if ~isfield(session.state,"answers_text") | ~isfield(session.state,"measurements") then error("Trūksta sesijos duomenų."); end
        if session.state.step<1 | session.state.step>12 then error("Netinkamas etapo numeris."); end
        if or(size(session.state.answers_text)<>[12 8]) then error("Netinkami atsakymų matmenys."); end
    if ~isfield(session.state,"student") then session.state.student=student_empty("LD2"); end
    if ~isfield(session.state,"assessment") then session.state.assessment=%f;end
    st=session.state.student;
    if st.number>0 then
        checked=student_profile(st.number,st.name,st.group,"LD2");
        if st.variant_id<>checked.variant_id | st.bank<>checked.bank then error("Neatpažintas variantas."); end
        expected=ld2_variant_config(st.number);
        for field=["E_RC" "F_RC" "R8" "C2" "E_RL" "F_RL" "R9" "L1" "E_RLC" "R13" "L3" "C4"]
            if session.cfg(field)<>expected(field) then error("Parametrai neatitinka studentui priskirto varianto."); end
        end
    end
endfunction

function ld2_restore_session(session)
    global LD2;
    ld2_clear_dynamic();
    LD2.cfg=session.cfg; LD2.state=session.state;
    // LD2-2 never claims legacy theory inputs as current student's answers.
    for retired=[3 6]
        LD2.state.answers_text(retired,:)=emptystr(1,8);
        LD2.state.answers(retired,:)=%nan*ones(1,8);
    end
    if ~isfield(LD2.state,"student") then LD2.state.student=student_empty("LD2"); end
    LD2.state.power=%f;
    LD2.state.selected_terminal="";
    // Retired compatibility slots mirror the actual wiring stages exactly.
    // No independent scoring/measurement/answer state survives for 3 and 6.
    LD2.state.completed(3)=LD2.state.completed(2); LD2.state.skipped(3)=0;
    LD2.state.completed(6)=LD2.state.completed(5); LD2.state.skipped(6)=0;
    if LD2.state.step==3 then LD2.state.step=4; end
    if LD2.state.step==6 then LD2.state.step=7; end
    ld2_reset_live_readings(ld2_phase_for_step(LD2.state.step));
    ld2_render_step();
    if LD2.state.student.number>0 then student_remember(LD2.state.student); end
    ld2_set_status("Darbas atkurtas. Laidai ir istorija išliko; generatorius išjungtas, gyvą rodmenį išmatuokite iš naujo.","ok");
endfunction

function out=ld2_csv_field(txt)
    q=ascii(34);
    out=q+strsubst(string(txt),q,q+q)+q;
endfunction

function row=ld2_csv_row(fields)
    quoted=emptystr(1,size(fields,"*"));
    for j=1:size(fields,"*") quoted(j)=ld2_csv_field(fields(j)); end
    row=strcat(quoted,";");
endfunction

function ld2_export_all()
    global LD2;
    if LD2.example_active then
        ld2_show_error("Pavyzdžio duomenys neeksportuojami kaip studento darbas.",["Pirmiausia grįžkite į savo darbą."]); return;
    end
    ld2_save_answers();
    folder=uigetdir(LD2.root,"Pasirinkite aplanką LD2 CSV failams");
    if size(folder,"*")==0 then return; end
    if type(folder)<>10 then return; end
    if stripblanks(folder)=="" then return; end
    try
        ld2_write_exports(folder);
        ld2_set_status("Išsaugoti matavimai, atsakymai, parametrai ir dažninė lentelė: "+folder,"ok");
    catch
        ld2_show_error("CSV eksportas nepavyko.",[lasterror();"Pasirinkite rašymui leidžiamą aplanką."]);
    end
endfunction

function ld2_write_exports(folder)
    global LD2;
    if isfield(LD2.state,"student") then
        mputl(student_csv_lines(LD2.state.student),fullfile(folder,"LD2_studentas.csv"));
    end
    lines=ld2_csv_row(["ID" "Etapas" "Grandine" "Dydis" "f_Hz" "Reiksme" "Vienetas" "Kilme" "Grandines_revizija"]);
    for k=1:length(LD2.state.measurements)
        m=LD2.state.measurements(k);
        lines($+1,1)=ld2_csv_row([string(m.id) string(m.step) m.phase m.target ...
            msprintf("%.12g",m.f) msprintf("%.12g",m.value) m.unit m.origin string(m.revision)]);
    end
    mputl(lines,fullfile(folder,"LD2_matavimu_zurnalas.csv"));
    lines=ld2_csv_row(["Etapas" "Pavadinimas" "Laukas" "Studento_tekstas" "Etapo_busena"]);
    for step=ld2_visible_steps()
        status="NEATLIKTA";
        if LD2.state.completed(step)==1 then status="PATIKRINTA"; end
        if LD2.state.skipped(step)==1 & LD2.state.completed(step)==0 then status="PRALEISTA"; end
        [labels,n]=ld2_answer_spec(step);
        if n==0 then lines($+1,1)=ld2_csv_row([string(step) ld2_step_title(step) "" "" status]); end
        for j=1:n
            lines($+1,1)=ld2_csv_row([string(step) ld2_step_title(step) labels(j) LD2.state.answers_text(step,j) status]);
        end
    end
    mputl(lines,fullfile(folder,"LD2_studento_atsakymai.csv"));
    lines=ld2_csv_row(["f_Hz" "UR13_V" "Kilme"]);
    for k=1:size(LD2.state.sweep_f,"*")
        lines($+1,1)=ld2_csv_row([string(LD2.state.sweep_f(k)) msprintf("%.12g",LD2.state.sweep_ur(k)) LD2.state.sweep_source(k)]);
    end
    mputl(lines,fullfile(folder,"LD2_daznine_lentele.csv"));
    lines=ld2_csv_row(["Parametras" "Reiksme_SI"]);
    names=fieldnames(LD2.cfg);
    for k=1:size(names,"*") lines($+1,1)=ld2_csv_row([names(k) msprintf("%.12g",ld2_config_value(LD2.cfg,names(k)))]); end
    mputl(lines,fullfile(folder,"LD2_parametrai.csv"));
    note=LD2.state.free_note;
    if note=="" then note="Studento išvados dar neįrašytos."; end
    mputl(note,fullfile(folder,"LD2_isvados.txt"));
endfunction

function ld2_edit_conclusions()
    global LD2;
    if LD2.example_active then
        ld2_show_info("Pavyzdys – išvadų orientyrai", [ ...
            "Savo išvadose palyginkite RC ir RL srovės bei įtampos fazes."; ...
            "Aptarkite, ar įtampų moduliai sudedami aritmetiškai, ar vektoriškai."; ...
            "Nurodykite savo rastą rezonansą, UL/UC maksimumų dažnius ir -3 dB ribas."; ...
            "Grįžkite mygtuku MANO DARBAS ir įrašykite savo išvadas."]); return;
    end
    note=x_dialog(["LD2 – jūsų išvados"; ...
        "Palyginkite RC/RL fazes, įtampų vektorius ir RLC rezonanso matavimus."],LD2.state.free_note);
    if size(note,"*")==0 then return; end
    LD2.state.free_note=strcat(matrix(note,-1,1),ascii(10));
    ld2_set_status("Išvados įrašytos į darbo būseną. IŠSAUGOTI išlaiko visą darbą, CSV eksportas – ir išvadų tekstą.","ok");
endfunction
