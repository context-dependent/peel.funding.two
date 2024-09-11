from arcgis import GIS
from arcgis.features import FeatureSet, FeatureLayer
from arcgis.mapping import WebMap

gis = GIS()
wm_id = '98303ad33d3c4ffdad39a7da12d996ba'
wm = WebMap(gis.content.get(wm_id))
d = []

for l in wm.layers[:-1]:
  print(FeatureSet.from_dict(l))
  
fl_id = 'fe72a0d42bc64e5fae3a81481155c586'

fl = FeatureLayer.fromitem(gis.content.get(fl_id))