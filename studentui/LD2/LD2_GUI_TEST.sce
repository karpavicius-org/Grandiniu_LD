// OPTIONAL: actual native GUI smoke test. Run with full Scilab, not scilab-cli.
// It opens a NEW bench and exercises examples, actual editable controls and graphs.
mode(-1);
LD2_TEST_ROOT=get_absolute_file_path("LD2_GUI_TEST.sce");
exec(LD2_TEST_ROOT+"LD2_LOAD.sce",-1);
[LD2_TEST_OK,LD2_TEST_LOG]=ld2_selftest();
if ~LD2_TEST_OK then disp(LD2_TEST_LOG); error("Pirma turi praeiti LD2_SELFTEST.sce."); end
ld2_main(LD2_TEST_ROOT);
global LD2;
LD2_GUI_LOG=["Natyvi Scilab GUI patikra";getversion()];
LD2_GUI_OK=%t;
try
    for ld2_step=ld2_visible_steps()
        ld2_go_step(ld2_step,%t);
        ld2_show_solution();
        if ~LD2.example_active then error("Nepavyko atverti pavyzdžio "+string(ld2_step)); end
        sleep(100);
        if ld2_step==4 | ld2_step==7 then
            ld2_plot_impedance(); ld2_plot_voltage_current(); ld2_plot_scope_current();
        elseif ld2_step==9 | ld2_step==12 then
            ld2_plot_resonance(); ld2_plot_scope_current();
        end
        ld2_show_solution();
        if LD2.example_active then error("Nepavyko grįžti iš pavyzdžio."); end
        LD2_GUI_LOG($+1,1)="PASS | Etapo "+string(ld2_step)+" atvaizdavimas ir pavyzdžio grąžinimas";
    end
    ld2_go_step(11,%t);ld2_auto_stage();
    LD2.ui.answer_edits(1).string="12,34";
    ld2_render_step();
    if LD2.ui.answer_edits(1).string<>"12,34" then error("Įvesties tekstas prarastas po GUI atnaujinimo.");end
    ld2_go_step(10,%t);ld2_go_step(11,%t);
    if LD2.ui.answer_edits(1).string<>"12,34" then error("Tekstas prarastas pakeitus etapą.");end
    LD2_GUI_LOG($+1,1)="PASS | Tikrų įvesties valdiklių išsaugojimas";
    ld2_go_step(10,%t);
    ld2_show_solution();
    LD2_GUI_LOG($+1,1)="PASS | Pabaigoje paliktas 10 etapo veikiantis pavyzdys";
catch
    LD2_GUI_OK=%f;
    LD2_GUI_LOG($+1,1)="FAIL | "+strcat(lasterror()," | ");
end
if LD2_GUI_OK then LD2_GUI_LOG($+1,1)="GUI FUNKCIJŲ VYKDYMAS: PASS (vizualinį patogumą įvertinkite ekrane)"; end
try mputl(LD2_GUI_LOG,LD2_TEST_ROOT+"LD2_GUI_TEST_LAST.txt"); catch end
disp(LD2_GUI_LOG);
if ~LD2_GUI_OK then error("GUI testas aptiko klaidą. Žr. LD2_GUI_TEST_LAST.txt."); end
