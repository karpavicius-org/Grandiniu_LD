#!/usr/bin/env python3
"""LD2-2 native grading: backwards compatibility and no unearned theory points."""
import copy
from pathlib import Path
import sys
import tempfile
from test_grading import fixture,write,run

def main(exe):
    with tempfile.TemporaryDirectory(prefix="LD2-2-grading-") as tmp:
        root=Path(tmp)
        source=root/"input"
        source.mkdir()
        old=fixture("LD2",17,"ld2-1-legacy")
        assert len([a for a in old["answers"] if a["id"].startswith(("s3.q","s6.q"))])==14
        revised=copy.deepcopy(old)
        revised.update(lab_revision="2",rubric_version="LD2-2",submission_id="ld2-2-correct")
        revised["answers"]=[a for a in revised["answers"] if not a["id"].startswith(("s3.q","s6.q"))]
        assert len(revised["answers"])==len(old["answers"])-14
        write(source/"legacy.html",old)
        write(source/"revised.html",revised)
        extra=copy.deepcopy(revised)
        extra["submission_id"]="ld2-2-injected-theory"
        extra["answers"].append(dict(id="s3.q1",raw="999",unit="Ohm"))
        write(source/"injected.html",extra)
        mismatch=copy.deepcopy(revised)
        mismatch["submission_id"]="ld2-2-bad-bank"
        mismatch["bank_id"]="LD2-WRONG-BANK"
        write(source/"mismatch.html",mismatch)
        results,_=run(exe,source,root/"out")
        items={row["file"]:row for row in results["results"]}
        assert (items["legacy.html"]["status"],items["legacy.html"]["points"],items["legacy.html"]["max_points"])==("graded",50,50),items["legacy.html"]
        assert (items["revised.html"]["status"],items["revised.html"]["points"],items["revised.html"]["max_points"])==("graded",36,36),items["revised.html"]
        assert items["injected.html"]["status"]=="review",items["injected.html"]
        assert items["mismatch.html"]["status"]=="review",items["mismatch.html"]
        other=root/"wrong";other.mkdir()
        wrong=copy.deepcopy(revised)
        wrong["submission_id"]="ld2-2-wrong-answer"
        wrong["answers"][0]["raw"]="999999"
        write(other/"wrong.html",wrong)
        bad,_=run(exe,other,root/"bad")
        result=bad["results"][0]
        assert result["status"]=="graded" and (result["points"],result["max_points"])==(35,36),result
        print("PASS: LD2-1 50/50, LD2-2 36/36, injected fields rejected, wrong answer 35/36")

if __name__=="__main__":
    main(Path(sys.argv[1]))
