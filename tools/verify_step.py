import sys, Part

shape = Part.Shape()
shape.read([a for a in sys.argv if a.endswith(".step")][0])
print("solids:", len(shape.Solids))
for i, s in enumerate(shape.Solids):
    b = s.BoundBox
    print(f"solid {i}: vol={s.Volume:9.1f}  faces={len(s.Faces):3d}  "
          f"bbox X[{b.XMin:.1f},{b.XMax:.1f}] Y[{b.YMin:.1f},{b.YMax:.1f}] Z[{b.ZMin:.1f},{b.ZMax:.1f}]")
