import sys, FreeCAD, importCSG, Import

args = [a for a in sys.argv if a.endswith(".csg") or a.endswith(".step")]
csg  = [a for a in args if a.endswith(".csg")][0]
step = [a for a in args if a.endswith(".step")][0]

importCSG.open(csg)
doc = FreeCAD.ActiveDocument
doc.recompute()

# Report any objects that failed to build a shape
bad = [o.Name for o in doc.Objects
       if hasattr(o, "Shape") and (o.Shape is None or o.Shape.isNull())]
print("FAILED objects:", bad if bad else "none")

# Top-level results = valid shapes nothing else depends on
tops = [o for o in doc.Objects
        if hasattr(o, "Shape") and o.Shape and not o.Shape.isNull() and not o.InList]
print("Top-level solids:", [o.Name for o in tops])
for o in tops:
    s = o.Shape
    print(f"  {o.Name}: solids={len(s.Solids)} volume={s.Volume:.1f} valid={s.isValid()}")

if tops:
    Import.export(tops, step)
    print("Exported ->", step)
else:
    print("Nothing to export")
