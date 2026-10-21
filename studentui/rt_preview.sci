// Nedidelis paskutinių tos pačios rūšies matavimų palyginimas tarp bandymų.
// Vienas esamo užduočių skydelio grafikas; nėra papildomų studento veiksmų.
function [id,unit,indices,values]=rt_preview_values(records)
    last=records($);id=last.reading.ids(1);unit=last.reading.units(1);best=-1;
    for j=1:size(last.reading.ids,"*")
        candidate=last.reading.ids(j);candidateUnit=last.reading.units(j);prior=[];
        for k=1:length(records)-1
            found=find(records(k).reading.ids==candidate & records(k).reading.units==candidateUnit);
            if ~isempty(found) then prior=records(k).reading.values(found(1));end
        end
        score=0;
        if ~isempty(prior) then
            score=1+abs(last.reading.values(j)-prior)/max([abs(last.reading.values(j)) abs(prior) 1d-12]);
        end
        if score>best+1d-9 | (abs(score-best)<=1d-9 & candidateUnit=="mA") then id=candidate;unit=candidateUnit;best=score;end
    end
    indices=[];values=[];
    for k=1:length(records)
        found=find(records(k).reading.ids==id & records(k).reading.units==unit);
        if ~isempty(found) then indices($+1)=k;values($+1)=records(k).reading.values(found(1));end
    end
    if size(indices,"*")>4 then indices=indices($-3:$);values=values($-3:$);end
    indices=matrix(indices,1,-1);values=matrix(values,1,-1);
endfunction
function h=rt_preview_text(parent,position,text,sizePx,bold)
    h=uicontrol(parent,"style","text","units","normalized","position",position, ...
        "string",text,"fontsize",sizePx,"fontunits","pixels","backgroundcolor",[.96 .98 .97], ...
        "foregroundcolor",[.13 .25 .23],"horizontalalignment","left");
    if bold then h.fontweight="bold";end
endfunction
function rt_preview_render()
    global MO;
    if ~isfield(MO.ui,"preview") then
        MO.ui.preview=uicontrol(MO.ui.task,"style","frame","units","normalized", ...
            "position",[.07 .205 .86 .37],"backgroundcolor",[.96 .98 .97],"visible","off","tag","RT_RESULT_PREVIEW");
        MO.ui.previewKey="";
    end
    p=MO.ui.preview;
    if MO.phase<>"between" | length(MO.records)==0 then p.visible="off";return;end
    key=string(MO.trialIndex)+"|"+string(length(MO.records));
    if MO.ui.previewKey==key then p.visible="on";return;end
    for h=matrix(p.children,1,-1);delete(h);end
    [id,unit,indices,values]=rt_preview_values(MO.records);n=size(values,"*");
    quantity="Rodmenų palyginimas";
    if unit=="V" then quantity="Įtampos palyginimas";end
    if unit=="mA" then quantity="Srovės palyginimas";end
    if unit=="mW" then quantity="Galios palyginimas";end
    rt_preview_text(p,[.04 .82 .92 .15],quantity+", "+unit,14,%t);
    lo=min([0 values]);hi=max([0 values]);span=hi-lo;if span<1d-12 then span=1;end
    x=.24;plotWidth=.38;zero=x+plotWidth*(0-lo)/span;
    for j=1:n
        y=.65-(j-1)*.16;
        rt_preview_text(p,[.04 y-.025 .19 .14],string(indices(j))+" band.",13,%f);
        endpoint=x+plotWidth*(values(j)-lo)/span;width=abs(endpoint-zero);
        color=[.62 .77 .72];bold=%f;if j==n then color=[.05 .47 .40];bold=%t;end
        // A zero reading is shown by its numeric value and baseline only.
        if width>1d-9 then uicontrol(p,"style","frame","units","normalized", ...
            "position",[min(zero,endpoint) y+.015 width .065],"backgroundcolor",color);end
        uicontrol(p,"style","frame","units","normalized", ...
            "position",[zero y-.005 .003 .105],"backgroundcolor",[.38 .52 .47]);
        h=rt_preview_text(p,[.65 y-.025 .33 .14],mo_display(values(j))+" "+unit,13,bold);
        h.tag="RT_RESULT_PREVIEW_VALUE_"+string(j);
    end
    caption="Paskutiniai "+string(n)+" šio dydžio matavimai";if n==1 then caption="Pirmasis šio dydžio matavimas";end
    rt_preview_text(p,[.04 .005 .92 .12],caption,12,%f);
    MO.ui.previewKey=key;p.visible="on";
endfunction
