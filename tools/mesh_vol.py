import sys, Mesh
m = Mesh.Mesh([a for a in sys.argv if a.endswith(".stl")][0])
print("MESH volume:", round(m.Volume,1))
