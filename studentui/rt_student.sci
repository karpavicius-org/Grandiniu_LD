// Tikslinės matavimo užduotys originaliuose LD stenduose.
function s=rt_lab()
    global MO;
    execstr("global "+MO.lab+";s="+MO.lab+";");
endfunction
function rt_set_lab(s)
    global MO;
    execstr("global "+MO.lab+";"+MO.lab+"=s;");
endfunction
function rt_launch(root,lab)
    try bench_core_require(); catch
        messagebox(["Stendo paleisti nepavyko.";strcat(lasterror()," ");"Išskleiskite visą paketą ir paleiskite iš naujo."],"Paleidimas","error");return;
    end
    [ok,st,cfg]=student_enroll(lab);
    if ok then student_remember(st); rt_start(root,lab,st,cfg); end
endfunction
function rt_start(root,lab,st,cfg)
    global MO;
    if typeof(MO)=="st" then
        if isfield(MO,"fig") then if typeof(MO.fig)=="handle" then if is_handle_valid(MO.fig) then delete(MO.fig); end; end; end
        if isfield(MO,"guideFig") then if typeof(MO.guideFig)=="handle" then if is_handle_valid(MO.guideFig) then delete(MO.guideFig); end; end; end
    end
    p=mo_protocol(lab,cfg);
    MO=struct("root",root,"lab",lab,"student",st,"cfg",cfg,"protocol",p,"trialIndex",1, ...
        "readingIndex",1,"phase","wiring","wires",emptystr(0,2),"pending","","helpEnabled",%f, ...
        "helpUsed",%f,"records",list(),"current",struct(),"displayed",emptystr(0,1), ...
        "copied",emptystr(0,1),"wiringErrors",0,"copyErrors",0,"reportPath","", ...
        "message","Sujunkite grandinę. Jei reikia, spauskite Pagalba.","resumePath","", ...
        "attached",%f,"focusHandle",[],"guideFig",[], ...
        "sessionId",bench_id(),"createdAt",strcat(string(getdate()),"-"),"events",list(), ...
        "callbackEpoch",bench_id(),"lastConnected",emptystr(0,1),"lastBadCopyKey","","reportFolder","","copyHintIndex",0,"portfolioReady",%f);
    mo_restore();
    // A completed older laboratory joins the same student file; originals remain intact.
    if MO.phase=="complete" then
        if MO.reportPath<>"" then
            [reportKind,previousReport,reportWhy]=mo_read_report(MO.reportPath);
            if reportKind==1 then MO.portfolioReady=mo7_is_portfolio(previousReport);end
        end
        if ~MO.portfolioReady then
            previousPath=MO.reportPath;
            try MO.reportPath=mo_export_report(MO);MO.portfolioReady=%t;mo_checkpoint();
            catch MO.reportPath=previousPath;MO.message="Matavimai atkurti. Bendro studento failo išsaugoti nepavyko: "+strcat(lasterror()," ");end
        end
    end
    execstr("v=rt_prepare_"+part(lab,3:length(lab))+"(root,st,cfg);");
    rt_fit_viewport(v.fig);
    MO.fig=v.fig; MO.ui=v; rt_attach(); MO.attached=%t; MO.fig.closerequestfcn="rt_close()";MO.fig.resizefcn="rt_render()";rt_render();MO.fig.visible="on";rt_guide_refresh();
endfunction

function rt_fit_viewport(fig)
    canvas=student_guide_find(fig,"student-canvas");
    if isempty(canvas) then return;end
    screen=get(0,"screensize_px");design=canvas.position(3:4);
    decoration=max([0 0],fig.figure_size-fig.axes_size);
    if or(design+decoration>screen(3:4)) then return;end
    // The original fixed canvas really fits. Restore the original wide-screen
    // parent tree: a resized JScrollPane can keep its former clipped viewport.
    scroll=canvas.parent;
    for child=matrix(canvas.children,1,-1)
        position=child.position;child.parent=fig;child.position=position;
    end
    delete(canvas);delete(scroll);
    fig.axes_size=design;
    fig.figure_position=max([0 0],min(fig.figure_position,screen(3:4)-fig.figure_size));
    student_reflow(fig,design);
endfunction

function rt_attach()
    global MO;
    // Original task frame, primary control and physical circuit remain in place.
    p=MO.ui.task;
    for h=matrix(p.children,1,-1)
        if h.type=="uicontrol" then h.visible="off"; end
    end
    MO.ui.instruction=student_text(p,[.07 .60 .86 .35],"",14,%f,[1 1 1]);
    MO.ui.instruction.verticalalignment="top";
    MO.ui.copyLabels=[]; MO.ui.copyEdits=[]; MO.ui.copyHints=[]; MO.ui.entryToken="";
    MO.ui.primary.visible="on"; MO.ui.primary.enable="on"; MO.ui.primary.callback="rt_primary()";
    MO.ui.primary.tag="RT_PRIMARY";
    MO.ui.undo=student_button(p,[.07 .015 .60 .045],"Atjungti kabelį","rt_undo()");
    MO.ui.undo.tag="RT_UNDO";
    MO.ui.reportFile=student_text(p,[.07 .40 .86 .18],"",12,%f,[1 1 1]);
    MO.ui.reportFile.tag="RT_REPORT_FILE";MO.ui.reportFile.visible="off";
    MO.ui.folder=student_button(p,[.07 .18 .86 .065],"Rodyti ataskaitos aplanką","rt_report_folder()");
    MO.ui.folder.tag="RT_REPORT_FOLDER";MO.ui.folder.visible="off";
    MO.ui.saveAs=student_button(p,[.07 .275 .86 .065],"Išsaugoti failo kopiją…","rt_report_save_as()");
    MO.ui.saveAs.tag="RT_REPORT_SAVE_AS";MO.ui.saveAs.visible="off";
    MO.ui.status=student_text(MO.fig,[.025 .020 .95 .055],"",13,%t,[.94 .96 .96]);
    MO.ui.status.tag="RT_STATUS";
    rt_mask_controls();
endfunction
function rt_walk_mask(p)
    global MO;
    for h=matrix(p.children,1,-1)
        if h.type<>"uicontrol" then continue; end
        if or(h.style==["pushbutton" "slider" "popupmenu" "edit" "checkbox" "radiobutton"]) then
            cb=h.callback;
            help=~isempty(strindex(cb,"show_actions")) | ~isempty(strindex(cb,"student_help")) | ~isempty(strindex(cb,"help_menu")) | ~isempty(strindex(cb,"rt_help("));
            keep=(h==MO.ui.primary | h==MO.ui.measure | h==MO.ui.undo | h==MO.ui.folder | h==MO.ui.saveAs);
            if ~isempty(MO.ui.copyEdits) then if or(MO.ui.copyEdits==h) then keep=%t; end; end
            if help then h.callback="rt_help("""+rt_context()+""")";h.string="<html><center>Pagalba</center></html>";h.visible="on";
            elseif ~keep then h.visible="off";end
        end
        rt_walk_mask(h);
    end
endfunction
function rt_mask_controls()
    global MO;
    rt_walk_mask(MO.fig);
    s=rt_lab();
    if isfield(s,"ui") then
        for key=["statusMain" "statusFix"]
            if isfield(s.ui,key) then if is_handle_valid(s.ui(key)) then s.ui(key).visible="off"; end; end
        end
    end
endfunction
function rt_unfocus()
    global MO;
    if typeof(MO.focusHandle)=="handle" then
        if is_handle_valid(MO.focusHandle) then
            MO.focusHandle.backgroundcolor=MO.focusBg; MO.focusHandle.foregroundcolor=MO.focusFg;
        end
    end
    MO.focusHandle=[];
endfunction
function rt_focus(h)
    global MO;
    if ~is_handle_valid(h) then return; end
    MO.focusHandle=h; MO.focusBg=h.backgroundcolor; MO.focusFg=h.foregroundcolor;
    h.backgroundcolor=[1 .86 .20]; h.foregroundcolor=[.12 .19 .22];
endfunction
function [row,target,cancel]=rt_next_port()
    global MO;
    t=MO.protocol.trials(MO.trialIndex); row=0; target=""; cancel=%f; first=0;
    for k=1:size(t.wires,1)
        present=%f;
        for j=1:size(MO.wires,1)
            if and(t.wires(k,:)==MO.wires(j,:)) | and(t.wires(k,:)==MO.wires(j,[2 1])) then present=%t; break; end
        end
        if ~present then
            if first==0 then first=k; end
            if MO.pending<>"" & or(t.wires(k,:)==MO.pending) then row=k; break; end
        end
    end
    if row==0 then row=first; end
    if row==0 then return; end
    target=t.wires(row,1);
    if MO.pending<>"" then
        if MO.pending==target then target=t.wires(row,2);
        elseif MO.pending==t.wires(row,2) then target=t.wires(row,1);
        else target=MO.pending; cancel=%t; end
    end
endfunction
function name=rt_port_name(id)
    global MO;
    name=id;
    try execstr("name=ld"+part(MO.lab,3:length(MO.lab))+"_terminal_name(id);"); catch end
endfunction
function txt=rt_trial_caption()
    global MO;
    if typeof(MO)<>"st" then txt="";return;end
    t=MO.protocol.trials(MO.trialIndex);
    txt=msprintf("Bandymas %d / %d · ",MO.trialIndex,length(MO.protocol.trials))+t.condition;
endfunction
function rt_render()
    global MO;
    if typeof(MO)<>"st" then return; end
    if ~isfield(MO,"attached") then return; end
    if ~MO.attached then return; end
    if ~is_handle_valid(MO.fig) then return; end
    rt_unfocus(); MO.fig.immediate_drawing="off";
    t=MO.protocol.trials(MO.trialIndex);
    s=rt_lab(); s.wires=MO.wires; s.pending=MO.pending;
    if isfield(s,"guide_enabled") then s.guide_enabled=MO.helpEnabled; end
    rt_set_lab(s);
    execstr("rt_apply_"+part(MO.lab,3:length(MO.lab))+"(t,MO.phase);");
    execstr("rt_draw_"+part(MO.lab,3:length(MO.lab))+"();");
    execstr("[hs,ids]=rt_ports_"+part(MO.lab,3:length(MO.lab))+"();");
    MO.ui.ports=hs; MO.ui.portIds=ids;
    rt_mask_controls();
    active=matrix(t.wires,-1,1);
    for k=1:size(ids,"*")
        h=hs(k); if ~is_handle_valid(h) then continue; end
        h.callback="rt_port("""+ids(k)+""","""+rt_context()+""")";
        if or(active==ids(k)) then
            h.visible="on"; h.enable="off"; if MO.phase=="wiring" then h.enable="on"; end
        else h.visible="off"; end
        if MO.phase=="wiring" & MO.pending==ids(k) then h.backgroundcolor=[.08 .40 .70];h.foregroundcolor=[1 1 1];end
    end
    s=rt_lab();
    if isfield(s,"ui") then
        if isfield(s.ui,"progress") then s.ui.progress.string=msprintf("%d / %d bandymas",MO.trialIndex,length(MO.protocol.trials)); end
        if isfield(s.ui,"identity") then s.ui.identity.string=student_caption(MO.student); end
        if isfield(s.ui,"studentIdentity") then s.ui.studentIdentity.string=student_caption(MO.student); end
        if isfield(s.ui,"studentProgress") then s.ui.studentProgress.string=msprintf("%d / %d bandymas",MO.trialIndex,length(MO.protocol.trials)); end
        if isfield(s.ui,"trialProgress") then s.ui.trialProgress.string=student_wrap(rt_trial_caption(),100); end
    end
    MO.ui.primary.visible="off"; MO.ui.primary.enable="on"; MO.ui.undo.visible="off";
    ctx=rt_context();
    MO.ui.primary.callback="rt_primary("""+ctx+""")";MO.ui.undo.callback="rt_undo("""+ctx+""")";
    MO.ui.folder.callback="rt_report_folder("""+ctx+""")";MO.ui.saveAs.callback="rt_report_save_as("""+ctx+""")";
    MO.ui.folder.visible="off";MO.ui.saveAs.visible="off";MO.ui.reportFile.visible="off";
    if is_handle_valid(MO.ui.measure) then
        MO.ui.measure.callback="rt_measure("""+ctx+""")"; MO.ui.measure.tag="RT_MEASURE";MO.ui.measure.string="Įjungti ir matuoti";
        MO.ui.measure.visible="off";
    end
    for h=matrix(MO.ui.copyLabels,1,-1); if is_handle_valid(h) then h.visible="off"; end; end
    for h=matrix(MO.ui.copyEdits,1,-1); if is_handle_valid(h) then h.visible="off"; end; end
    for h=matrix(MO.ui.copyHints,1,-1);if is_handle_valid(h) then h.visible="off";end;end
    base=[t.title;"";"Tikslas: "+rt_first_sentence(t.why)];
    select MO.phase
    case "wiring" then
        MO.ui.instruction.string=student_wrap([base;"";"Sujunkite grandinę. Pagalba parodys kiekvieną kabelio galą."],38);
        if mo_wires_equal(MO.wires,t.wires) then
            MO.ui.measure.visible="on"; MO.ui.measure.enable="on";
            MO.message="Kabeliai sujungti. Spauskite Įjungti ir matuoti.";
        end
        if MO.pending<>"" | size(MO.wires,1)>0 then MO.ui.undo.visible="on"; end
    case "copy" then
        token=string(MO.trialIndex);
        if MO.ui.entryToken<>token then rt_make_copy_fields(); MO.ui.entryToken=token; end
        MO.ui.instruction.string=student_wrap([base;"";"Perrašykite žemiau nurodytų prietaisų rodmenis."],38);
        for h=matrix(MO.ui.copyLabels,1,-1);h.visible="on";end
        for h=matrix(MO.ui.copyEdits,1,-1);h.visible="on";end
        MO.ui.primary.string="Įrašyti rodmenis"; MO.ui.primary.visible="on";
    case "between" then
        next=MO.protocol.trials(MO.trialIndex+1);
        MO.ui.instruction.string=student_wrap([t.title;"";"Rodmenys įrašyti:";rt_reading_caption();rt_comparison_caption();"";"Toliau: "+next.title],38);
        MO.ui.primary.string="Kitas bandymas →"; MO.ui.primary.visible="on";
    case "complete" then
        MO.ui.saveAs.visible="on";
        if MO.reportPath<>"" & isfile(MO.reportPath) then
            MO.ui.instruction.string=student_wrap(["Darbas baigtas. Ataskaita išsaugota.";"";"Joje rasite matavimus, grafikus ir rezultatų paaiškinimus.";"";"Dėstytojui perduokite šį vieną HTML failą."],38);
            MO.ui.primary.string="Atverti ataskaitą";MO.ui.folder.visible="on";
            if MO.portfolioReady then
                MO.ui.instruction.string=student_wrap(["Darbas baigtas. Bendras studento failas atnaujintas.";"";"Jame kaupiami visi jūsų užbaigti LD: matavimai, grafikai ir paaiškinimai.";"";"Dėstytojui perduokite šį vieną HTML failą."],38);
                MO.ui.primary.string="Atverti studento failą";
            end
            [rp,rn,re]=fileparts(MO.reportPath);MO.ui.reportFile.string=student_wrap("Failas: "+rn+re,42);MO.ui.reportFile.visible="on";
        else
            MO.ui.instruction.string=student_wrap(["Visi matavimai išsaugoti šiame darbe.";"";"HTML ataskaitos įrašyti dar nepavyko.";"";"Bandykite išsaugoti dar kartą arba pasirinkite kitą aplanką."],38);
            MO.ui.primary.string="Pakartoti ataskaitos išsaugojimą";
        end
        MO.ui.primary.visible="on";
    end
    if typeof(MO.ui.journal)=="handle" then
    if is_handle_valid(MO.ui.journal) then
        rows="Matavimų žurnalas";
        for k=1:length(MO.records)
            rec=MO.records(k);line=string(k)+". ";
            for j=1:size(rec.reading.values,"*");line=line+rt_quantity_symbol(rec.reading.units(j))+"="+rec.displayed(j)+" "+rec.reading.units(j)+"  ";end
            rows($+1,1)=line;
        end
        if MO.phase=="copy" then rows($+1,1)="Dabar: "+rt_reading_caption(); end
        MO.ui.journal.string=rows;
    end
    end
    MO.ui.status.string=student_wrap(MO.message,120);
    rt_copy_feedback();rt_preview_render();rt_public_labels(MO.fig);rt_guide_refresh(); MO.fig.immediate_drawing="on";
endfunction
function txt=rt_reading_caption()
    global MO;
    txt="";
    for j=1:size(MO.current.values,"*")
        if j>1 then txt=txt+"; "; end
        txt=txt+rt_quantity_symbol(MO.current.units(j))+" = "+MO.displayed(j)+" "+MO.current.units(j);
    end
endfunction
function rt_make_copy_fields()
    global MO;
    for h=matrix(MO.ui.copyLabels,1,-1);if is_handle_valid(h) then delete(h);end;end
    for h=matrix(MO.ui.copyEdits,1,-1);if is_handle_valid(h) then delete(h);end;end
    for h=matrix(MO.ui.copyHints,1,-1);if is_handle_valid(h) then delete(h);end;end
    MO.ui.copyLabels=[]; MO.ui.copyEdits=[]; MO.ui.copyHints=[]; p=MO.ui.task;
    for j=1:size(MO.current.values,"*")
        y=.49-(j-1)*.12;
        label=rt_copy_label(j);
        h=student_text(p,[.07 y .45 .09],student_wrap("Įrašykite: "+label,20),14,%f,[1 1 1]);
        MO.ui.copyLabels($+1)=h;
        h=uicontrol(p,"style","edit","units","normalized","position",[.56 y+.012 .37 .065], ...
            "string","","fontsize",17,"fontunits","pixels","backgroundcolor",[.94 .96 .96], ...
            "tag","RT_COPY_"+string(j),"callback","rt_copy_changed("""+rt_context()+""")","tooltipstring","Perrašykite tik matomą prietaiso skaičių. Vienetų rašyti nereikia.");
        if j<size(MO.copied,"*")+1 then h.string=MO.copied(j); end
        MO.ui.copyEdits($+1)=h;
        hint=student_text(p,[.07 y-.029 .86 .027],"",11,%f,[1 1 1]);
        hint.foregroundcolor=[.64 .25 .12];hint.tag="RT_COPY_HINT_"+string(j);hint.visible="off";
        MO.ui.copyHints($+1)=hint;
    end
endfunction
function rt_port(id,token)
    global MO;
    if argn(2)>1 then if ~rt_accept_context(token) then return;end;end
    if MO.phase<>"wiring" then return; end
    t=MO.protocol.trials(MO.trialIndex);
    if ~or(matrix(t.wires,-1,1)==id) then return; end
    if MO.pending=="" then
        MO.pending=id; MO.message="Pasirinktas "+rt_port_name(id)+". Spauskite kitą kabelio galą.";rt_event("contact_selected",id);
    elseif MO.pending==id then
        MO.pending=""; MO.message="Kontakto pasirinkimas atšauktas.";rt_event("selection_cancelled",id);
    else
        pair=[MO.pending id];valid=mo_wires_subset(pair,t.wires);rtPairPresent=%f;existingIndex=0;
        for k=1:size(MO.wires,1);if and(pair==MO.wires(k,:)) | and(pair==MO.wires(k,[2 1])) then rtPairPresent=%t;existingIndex=k;end;end
        if rtPairPresent then
            MO.wires(existingIndex,:)=[];MO.message="Kabelis atjungtas. Tęskite jungimą.";rt_event("wire_removed",strcat(pair," → "));
        elseif ~valid then
            MO.wiringErrors=MO.wiringErrors+1;MO.message="Šių kontaktų jungti nereikia. Kabelis nepridėtas. Pagalba parodys tinkamą jungtį.";rt_event("wire_rejected",strcat(pair," → "));
        else
            MO.wires($+1,:)=pair;MO.lastConnected=matrix(pair,-1,1);MO.message="Kabelis prijungtas: "+rt_port_code(pair(1))+" → "+rt_port_code(pair(2))+".";rt_event("wire_connected",strcat(pair," → "));
        end
        MO.pending="";
    end
    mo_checkpoint();rt_render();
endfunction
function rt_undo(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    rt_event("undo",MO.pending);
    if MO.phase<>"wiring" then return;end
    if MO.pending<>"" then MO.pending="";
    elseif size(MO.wires,1)>0 then MO.wires($,:)=[];end
    MO.message="Pasirinkimas atšauktas. Tęskite jungimą.";mo_checkpoint();rt_render();
endfunction
function rt_measure(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    if MO.phase<>"wiring" then return;end
    t=MO.protocol.trials(MO.trialIndex);
    if ~mo_wires_equal(MO.wires,t.wires) then MO.message="Dar trūksta kabelių. Spauskite Pagalba, jei reikia parodyti kontaktą.";rt_render();return;end
    saved=rt_lab();
    try
        r=mo_measure(MO.lab,MO.cfg,t,MO.wires);rt_set_lab(saved);
        MO.current=r;MO.displayed=emptystr(size(r.values,"*"),1);MO.copied=MO.displayed;
        for j=1:size(r.values,"*");MO.displayed(j)=mo_display(r.values(j));end
        MO.phase="copy";MO.readingIndex=1;MO.ui.entryToken="";MO.copyHintIndex=0;
        MO.message="Matavimas atliktas. Pažiūrėkite į prietaisus ir perrašykite rodmenis.";rt_event("measurement_completed",t.key);
    catch
        rt_set_lab(saved);MO.message="Pamatuoti nepavyko: "+strcat(lasterror()," ");
    end
    mo_checkpoint();rt_render();
endfunction
function rt_primary(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    t=MO.protocol.trials(MO.trialIndex);
    try
        select MO.phase
        case "wiring" then rt_measure();return;
        case "copy" then
            valid=%t;
            for j=1:size(MO.current.values,"*")
                raw=stripblanks(MO.ui.copyEdits(j).string);
                if ~mo_copy_matches(raw,MO.displayed(j)) then
                    MO.readingIndex=j;valid=%f;
                    badKey=string(MO.trialIndex)+"|"+string(j)+"|"+raw;
                    if MO.lastBadCopyKey<>badKey then MO.copyErrors=MO.copyErrors+1;rt_event("reading_correction",MO.current.ids(j)+"="+raw);MO.lastBadCopyKey=badKey;end
                    MO.copyHintIndex=j;MO.message=rt_copy_hint(j);break;
                end
                MO.copied(j)=raw;
            end
            if valid then
                MO.lastBadCopyKey="";rt_event("readings_confirmed",t.key);
                MO.records($+1)=struct("trial",t,"reading",MO.current,"copied",MO.copied,"displayed",MO.displayed,"wires",MO.wires);
                if MO.trialIndex==length(MO.protocol.trials) then
                    MO.phase="complete";rt_save_report(%t);
                else MO.phase="between";MO.message="Rodmenys išsaugoti. Galite tęsti kitą bandymą.";end
            end
        case "between" then
            MO.trialIndex=MO.trialIndex+1;next=MO.protocol.trials(MO.trialIndex);
            // Keep already connected useful cables; remove only obsolete links.
            keep=emptystr(0,2);
            for k=1:size(MO.wires,1)
                for j=1:size(next.wires,1)
                    if and(MO.wires(k,:)==next.wires(j,:)) | and(MO.wires(k,:)==next.wires(j,[2 1])) then keep($+1,:)=MO.wires(k,:);break;end
                end
            end
            MO.wires=keep;MO.pending="";MO.phase="wiring";MO.readingIndex=1;MO.lastConnected=emptystr(0,1);rt_event("trial_started",next.key);
            MO.message="Kitas bandymas paruoštas. Tinkami kabeliai palikti; jei reikia, prijunkite likusius.";
        case "complete" then
            if MO.reportPath=="" then rt_save_report(%t);
            elseif ~isfile(MO.reportPath) then MO.reportPath="";rt_save_report(%t);
            else bench_open_local(MO.reportPath);end
        end
    catch
        MO.message="Veiksmo užbaigti nepavyko: "+strcat(lasterror()," ")+". Ankstesni rodmenys išliko.";
    end
    mo_checkpoint();rt_render();
endfunction
function rt_help(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    rt_event("help_opened","");
    MO.helpEnabled=%t;MO.helpUsed=%t;rt_render();mo_checkpoint();
endfunction
function rt_help_close()
    global MO;
    MO.helpEnabled=%f;
    if typeof(MO.guideFig)=="handle" then if is_handle_valid(MO.guideFig) then delete(MO.guideFig);end;end
    MO.guideFig=[];rt_render();mo_checkpoint();
endfunction
function rt_guide_refresh()
    global MO;
    if ~MO.helpEnabled then return;end
    lines=emptystr(0,1);target=[];readout=[];t=MO.protocol.trials(MO.trialIndex);
    select MO.phase
    case "wiring" then
        row=0;id="";cancel=%f;
        if mo_wires_subset(MO.wires,t.wires) then [row,id,cancel]=rt_next_port();end
        if ~mo_wires_subset(MO.wires,t.wires) then
            target=MO.ui.undo;lines=["Laidų būsena neatitinka šio bandymo.";"Atjunkite paskutinį kabelį ir tęskite jungimą."];
        elseif row==0 then
            target=MO.ui.measure;lines=["Visi "+string(size(t.wires,1))+" kabeliai vietoje.";"Spauskite Įjungti ir matuoti."];
        else
            idx=find(MO.ui.portIds==id);if ~isempty(idx) then target=MO.ui.ports(idx(1));end
            pair=t.wires(row,:);pairText=rt_port_code(pair(1))+" → "+rt_port_code(pair(2));
            lines=["Kabelis "+string(row)+" iš "+string(size(t.wires,1))+": "+pairText;""];
            if cancel then lines=[lines;"Paspauskite pasirinktą kontaktą dar kartą, kad atšauktumėte pasirinkimą."];
            elseif MO.pending=="" then
                if size(MO.lastConnected,"*")==2 then
                    if MO.lastConnected(2)==id then lines=[lines;"Tą patį kontaktą naudojame naujam kabeliui.";"Spustelėkite jį dar kartą."];end
                end
                lines=[lines;"Pirmas galas: "+rt_port_code(id);rt_port_name(id);"Spustelėkite geltonai pažymėtą kontaktą."];
            else lines=[lines;"Antras galas: "+rt_port_code(id);rt_port_name(id);"Spustelėkite geltonai pažymėtą kontaktą."];end
        end
    case "copy" then
        j=1;
        for k=1:size(MO.current.values,"*")
            if ~mo_copy_matches(MO.ui.copyEdits(k).string,MO.displayed(k)) then j=k;break;end
            j=k+1;
        end
        if j>size(MO.current.values,"*") then target=MO.ui.primary;lines=["Visi rodmenys perrašyti.";"Spauskite Įrašyti rodmenis."];
        else target=MO.ui.copyEdits(j);readout=rt_guide_readout(j);lines=[MO.current.names(j)+": "+MO.displayed(j)+" "+MO.current.units(j); ...
            "Į geltonai pažymėtą lauką įrašykite "+MO.displayed(j)+".";"Vienetų rašyti nereikia. Tada perrašykite kitus rodomus rodmenis ir spauskite Įrašyti rodmenis."];end
    case "between" then target=MO.ui.primary;lines=["Šio bandymo rodmenys jau įrašyti.";"Spauskite Kitas bandymas. Nustatymus paruoš programa."];
    case "complete" then
        target=MO.ui.primary;
        if MO.reportPath<>"" then lines=["Darbas baigtas, HTML ataskaita išsaugota.";"Spauskite "+MO.ui.primary.string+" arba Rodyti ataskaitos aplanką."];
        else lines=["Matavimai išliko. HTML ataskaita dar neišsaugota.";"Spauskite Pakartoti ataskaitos išsaugojimą arba pasirinkite kitą aplanką."];end
    end
    if ~isempty(target) then
        if rt_target_ready(target) then rt_focus(target);
        else target=[];lines=["Reikiamas valdiklis šiuo metu nepasiekiamas.";"Atšaukite pasirinkimą arba atverkite Pagalba dar kartą."];end
    end
    if typeof(MO.guideFig)<>"handle" then MO.guideFig=[];end
    need=%t;if ~isempty(MO.guideFig) then need=~is_handle_valid(MO.guideFig);end
    if need then
        f=figure("default_axes","off","dockable","off","menubar","none","toolbar","none", ...
            "axes_size",[500 300],"figure_name",MO.lab+" · Pagalba žingsnis po žingsnio","resize","off");
        f.infobar_visible="off";f.closerequestfcn="rt_help_close()";MO.guideFig=f;
        MO.guideText=student_text(f,[.05 .25 .90 .68],"",16,%f,[1 1 1]);
        student_button(f,[.05 .06 .90 .13],"Baigti pagalbą","rt_help_close()");
    end
    MO.guideText.string=student_wrap(mo_public_text(lines),55);
    rt_guide_place(target,readout);
endfunction

// Screen rectangles follow the original nested canvas, including its viewport.
// Only the helper window moves; physical controls and instruments stay put.
function rect=rt_guide_screen_rect(h)
    if h.type=="Figure" then
        client=h.axes_size;decor=max([0 0],h.figure_size-client);
        rect=[h.figure_position+[decor(1)/2 decor(2)-decor(1)/2] client];return;
    end
    parent=rt_guide_screen_rect(h.parent);r=h.position;
    if h.units=="normalized" then r=r.*[parent(3:4) parent(3:4)];end
    rect=[parent(1)+r(1) parent(2)+parent(4)-r(2)-r(4) r(3:4)];
endfunction

function h=rt_guide_readout(j)
    global MO;
    h=[];unit=MO.current.units(j);
    if MO.lab=="LD1" then s=rt_lab();h=s.ui.meterDisplay;return;end
    if MO.lab=="LD2" then
        tag="component:VM";if or(unit==["A" "mA"]) then tag="component:AM";end
    else
        tag="reading:V";
        if or(unit==["A" "mA"]) then tag="reading:A";end
        if or(unit==["W" "mW"]) then tag="reading:W";end
        
    end
    h=student_guide_find(MO.fig,tag);
endfunction

function area=rt_guide_overlap(a,b)
    width=max(0,min(a(1)+a(3),b(1)+b(3))-max(a(1),b(1)));
    height=max(0,min(a(2)+a(4),b(2)+b(4))-max(a(2),b(2)));
    area=width*height;
endfunction

function rt_guide_place(target,readout)
    global MO;
    if isempty(target) then return;end
    screen=get(0,"screensize_px");wh=max(MO.guideFig.figure_size,MO.guideFig.axes_size);
    right=max(10,screen(3)-wh(1)-10);bottom=max(30,screen(4)-wh(2)-10);
    // Copying starts on the left, away from the original right-hand inputs.
    if MO.phase=="copy" then candidates=[10 30;10 bottom;right 30;right bottom];
    else candidates=[right 30;10 bottom;10 30;right bottom];end
    targetRect=rt_guide_screen_rect(target)+[-12 -12 24 24];
    sourceRect=[];if ~isempty(readout) then sourceRect=rt_guide_screen_rect(readout)+[-12 -12 24 24];end
    best=1;bestCost=%inf;
    for candidate=1:size(candidates,1)
        box=[candidates(candidate,:) wh];cost=candidate;
        overlap=rt_guide_overlap(box,targetRect);
        if overlap>0 then cost=cost+1d9+overlap;end
        if ~isempty(sourceRect) then
            overlap=rt_guide_overlap(box,sourceRect);
            if overlap>0 then cost=cost+1d6+overlap;end
        end
        if cost<bestCost then best=candidate;bestCost=cost;end
    end
    MO.guideFig.figure_position=candidates(best,:);
endfunction

function rt_copy_changed(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    if MO.phase<>"copy" then return; end
    rt_capture_copy_draft(); mo_checkpoint();
    rt_unfocus();rt_copy_feedback();rt_guide_refresh();
endfunction

// Keep unfinished transcription when a novice closes and later resumes.
// Drafts become recorded measurements only after the normal confirmation.
function rt_capture_copy_draft()
    global MO;
    if MO.phase<>"copy" then return; end
    n=size(MO.current.values,"*");
    if size(MO.ui.copyEdits,"*")<>n then return; end
    MO.copied=emptystr(n,1); MO.readingIndex=n; firstInvalid=0;
    for j=1:n
        if is_handle_valid(MO.ui.copyEdits(j)) then
            MO.copied(j)=stripblanks(MO.ui.copyEdits(j).string);
        end
        if firstInvalid==0 & ~mo_copy_matches(MO.copied(j),MO.displayed(j)) then firstInvalid=j; end
    end
    if firstInvalid>0 then MO.readingIndex=firstInvalid; end
endfunction

function label=rt_quantity_label(unit)
    select unit
    case "V" then label="Voltmetras, V";
    case "mA" then label="Ampermetras, mA";
    case "A" then label="Ampermetras, A";
    case "W" then label="Vatmetras, W";
    case "mW" then label="Vatmetras, mW";
    else label="Prietaiso rodmuo, "+unit;
    end
endfunction
function label=rt_quantity_symbol(unit)
    select unit
    case "V" then label="U";
    case "mA" then label="I";
    case "A" then label="I";
    case "W" then label="P";
    case "mW" then label="P";
    else label=unit;
    end
endfunction
function rt_close()
    global MO;
    rt_capture_copy_draft();
    mo_checkpoint();
    if typeof(MO.guideFig)=="handle" then if is_handle_valid(MO.guideFig) then delete(MO.guideFig);end;end
    if is_handle_valid(MO.fig) then delete(MO.fig);end
endfunction

function label=rt_copy_label(j)
    global MO;
    unit=MO.current.units(j);label=rt_quantity_label(unit);
    if MO.lab=="LD1" then label="Multimetras, "+unit;end
    if or(MO.lab==["LD8" "LD9" "LD10" "LD12"]) then
        if unit=="V" then label="Voltmetras "+MO.current.ids(j)+", V";end
        if unit=="mA" then label="Ampermetras "+MO.current.ids(j)+", mA";end
    end
endfunction
function text=rt_first_sentence(text)
    stops=strindex(text,". ");
    if ~isempty(stops) then text=part(text,1:stops(1));end
endfunction


function token=rt_context()
    global MO;token=MO.callbackEpoch+"-"+string(MO.trialIndex)+"-"+MO.phase;
endfunction
function ok=rt_accept_context(token)
    global MO;ok=%f;
    if typeof(MO)<>"st" then return;end
    if ~isfield(MO,"callbackEpoch") then return;end
    ok=(token==rt_context());
endfunction
function code=rt_port_code(id)
    global MO;code=id;
    try execstr("code=ld"+part(MO.lab,3:length(MO.lab))+"_terminal_code(id);");catch end
endfunction
function ok=rt_target_ready(h)
    ok=%f;
    if typeof(h)<>"handle" then return;end
    if ~is_handle_valid(h) then return;end
    if h.visible<>"on" | h.enable<>"on" then return;end
    if stripblanks(h.callback)=="" then return;end
    parent=h.parent;
    while parent.type<>"Figure"
        if parent.visible<>"on" then return;end
        parent=parent.parent;
    end
    ok=%t;
endfunction
function rt_event(action,detail)
    global MO;
    if ~isfield(MO,"events") then MO.events=list();end
    MO.events($+1)=struct("sequence",length(MO.events)+1,"time",getdate(), ...
        "trial",MO.trialIndex,"phase",MO.phase,"action",action,"detail",detail);
endfunction
function txt=rt_comparison_caption()
    global MO;txt="";
    if length(MO.records)<2 then return;end
    a=MO.records($-1).reading;b=MO.records($).reading;
    for j=1:size(b.values,"*")
        k=find(a.ids==b.ids(j) & a.units==b.units(j));
        if isempty(k) then continue;end
        if abs(a.values(k(1))-b.values(j))<.005 then continue;end
        txt=b.ids(j)+": "+mo_display(a.values(k(1)))+" → "+mo_display(b.values(j))+" "+b.units(j);return;
    end
endfunction
function rt_save_report(showSaved)
    global MO;
    MO.reportPath=mo_export_report(MO);
    MO.portfolioReady=%t;
    rt_event("report_saved",MO.reportPath);MO.message="Ataskaita išsaugota: "+MO.reportPath;
    mo_checkpoint();
    if showSaved then bench_report_saved(MO.reportPath,"Ataskaita paruošta");end
endfunction
function rt_report_folder(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    if MO.reportPath<>"" then bench_open_local(fileparts(MO.reportPath));end
endfunction
function rt_report_save_as(token)
    global MO;
    if argn(2)>0 then if ~rt_accept_context(token) then return;end;end
    folder=uigetdir(bench_documents(),"Pasirinkite aplanką bendro studento failo kopijai");
    if isempty(folder) then return;end
    if type(folder)<>10 then return;end
    if stripblanks(folder)=="" then return;end
    try
        dest=mo7_export_copy(MO,folder);
        if MO.reportPath=="" then MO.reportPath=dest;MO.portfolioReady=%t;end
        if ~isfile(MO.reportPath) then MO.reportPath=dest;MO.portfolioReady=%t;end
        bench_report_saved(dest,"Ataskaita paruošta");
        MO.message="Bendro studento failo kopija išsaugota: "+dest;
    catch MO.message="Ataskaitos išsaugoti nepavyko: "+strcat(lasterror()," ");end
    mo_checkpoint();rt_render();
endfunction

// Local feedback uses the same rounded number as the physical device face.
function text=rt_copy_hint(j)
    global MO;
    unit=MO.current.units(j);device="Voltmetras";
    if or(unit==["A" "mA"]) then device="Ampermetras";end
    if or(unit==["W" "mW"]) then device="Vatmetras";end
    shown=mo_num(bench_safe_number(MO.displayed(j)));
    text=device+" rodo "+shown+" "+unit+". Įrašykite "+shown+" be "+unit+".";
endfunction
function rt_copy_feedback()
    global MO;
    if MO.phase<>"copy" then return;end
    first=0;
    for j=1:size(MO.ui.copyEdits,"*")
        h=MO.ui.copyEdits(j);raw=stripblanks(h.string);hint=MO.ui.copyHints(j);hint.visible="off";
        h.backgroundcolor=[.94 .96 .96];
        if raw<>"" then
            if mo_copy_matches(raw,MO.displayed(j)) then h.backgroundcolor=[.91 .97 .94];
            else h.backgroundcolor=[1 .96 .90];if first==0 then first=j;end;end
        end
    end
    if first==0 & MO.copyHintIndex>0 then
        j=MO.copyHintIndex;
        if ~mo_copy_matches(MO.ui.copyEdits(j).string,MO.displayed(j)) then first=j;end
    end
    MO.copyHintIndex=first;
    if first>0 then MO.ui.copyHints(first).string=rt_copy_hint(first);MO.ui.copyHints(first).visible="on";end
endfunction
function rt_public_labels(parent)
    global MO;
    identity=student_caption(MO.student);
    for h=matrix(parent.children,1,-1)
        if h.type<>"uicontrol" then continue;end
        if h.style<>"edit" then
            value=h.string;
            if type(value)==10 then
                skip=%f;if size(value,"*")==1 then skip=value==identity;end
                if ~skip then cleaned=mo_public_text(value);if ~and(cleaned==value) then h.string=cleaned;end;end
            end
            tip=h.tooltipstring;
            if type(tip)==10 then cleaned=mo_public_text(tip);if ~and(cleaned==tip) then h.tooltipstring=cleaned;end;end
        end
        rt_public_labels(h);
    end
endfunction
