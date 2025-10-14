#!/usr/bin/env python
from mpcviz.MPCViz import MPCViz
from centaurohybridmpc.utils.centauro_urdf_gen import CentauroUrdfGen

import argparse

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Multi Robot Visualizer")
    parser.add_argument('--dpath', type=str, help="Path where the descr. files will be dumped")
    args = parser.parse_args()
    
    # generating description files for Kyon
    
    robot_type = "centauro"
    kyon_urdf_gen = CentauroUrdfGen(descr_path=args.dpath, 
            robotname=robot_type,
            big_wheels=True,
            name=robot_type+"Urdf")