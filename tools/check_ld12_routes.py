#!/usr/bin/env python3
"""Check actual rendered LD12 wire rectangles against controls and components.

Terminal contacts are checked by layoutcheck. Source/component lead strokes are
intentional and have their own tags; this guard checks student wires only.
"""
import json
from pathlib import Path
import re
import sys


def check_routes(path):
    groups={}
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        row=line.split('\t')
        assert len(row)==13,(path,row)
        groups.setdefault(row[0],[]).append(row)
    failures=[];segments=0
    for scenario,rows in groups.items():
        wires=[r for r in rows if r[3]=='wire']
        obstacles=[r for r in rows if r[3].startswith('component:') or
                   (r[2]=='pushbutton' and not re.fullmatch(r'T\d{2}',r[3]))]
        segments+=len(wires)
        for wire in wires:
            x,y,w,h=map(float,wire[4:8])
            for obstacle in obstacles:
                ox,oy,ow,oh=map(float,obstacle[4:8])
                dx=min(x+w,ox+ow)-max(x,ox);dy=min(y+h,oy+oh)-max(y,oy)
                # A subpixel edge rounding is not a line through a control.
                if dx>.5 and dy>.5:
                    failures.append(dict(scenario=scenario,wire=wire[1],obstacle=obstacle[3] or obstacle[1],overlap_px=[round(dx,3),round(dy,3)]))
    result=dict(status='PASS' if not failures else 'FAIL',scenarios=len(groups),student_wire_segments=segments,
                wire_control_or_component_intersections=len(failures),examples=failures[:8])
    return result


if __name__=='__main__':
    result=check_routes(sys.argv[1]);print(json.dumps(result,ensure_ascii=False))
    sys.exit(0 if result['status']=='PASS' else 1)
