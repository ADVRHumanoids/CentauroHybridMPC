#!/usr/bin/env python
from mpc_viz.MPCViz import MPCViz
from mpc_viz.utils.sys_utils import PathsGetter

from centaurohybridmpc.utils.centauro_urdf_gen import CentauroUrdfGen

import os
import argparse

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Multi Robot Visualizer")
    parser.add_argument('--ns', type=str, help='Namespace to be used for cluster shared memory',default="centauro0")
    parser.add_argument('--dpath', type=str,default="/root/ibrido_ws/src/iit-centauro-ros-pkg/centauro_urdf")
    parser.add_argument('--nodes_perc', type=int, default=30)
    parser.add_argument('--comment', type=str, help='Any useful comment associated with this run',default="")

    args = parser.parse_args()

    syspaths = PathsGetter()
        
    urdf_generator = CentauroUrdfGen(robotname="centauro", 
                big_wheels=True,
                descr_path=args.dpath,
                name="centauroUrdf")
    
    mpc_viz= MPCViz(urdf_file_path=urdf_generator.urdf_path, 
        rviz_config_path=syspaths.DEFAULT_RVIZ_CONFIG_PATH,
        namespace=args.ns, 
        basename="MPCViz", 
        rate = 100,
        use_only_collisions=False,
        nodes_perc = args.nodes_perc       
        )
    
    mpc_viz.run()
