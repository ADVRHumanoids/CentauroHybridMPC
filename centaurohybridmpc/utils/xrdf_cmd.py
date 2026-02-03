from typing import List
from EigenIPC.PyEigenIPC import VLevel
from EigenIPC.PyEigenIPC import Journal, LogType
           
def get_xrdf_cmds_horizon(urdf_descr_root_path : str = None, custom_args_xacro: List = []):

        return get_xrdf_cmds_horizon_centauro(urdf_descr_root_path=urdf_descr_root_path, custom_args_xacro=custom_args_xacro)  

def get_xrdf_cmds_horizon_centauro(urdf_descr_root_path: str = None, custom_args_xacro: List = []):

        cmds = []
        
        xrdf_cmd_vals = [True, True, True, False, False, True] # horizon needs 
        # the floating base
        legs = "true" if xrdf_cmd_vals[0] else "false"
        big_wheel = "true" if xrdf_cmd_vals[1] else "false"
        upper_body ="true" if xrdf_cmd_vals[2] else "false"
        velodyne = "true" if xrdf_cmd_vals[3] else "false"
        realsense = "true" if xrdf_cmd_vals[4] else "false"
        floating_joint = "true" if xrdf_cmd_vals[5] else "false"
                
        cmds.append("legs:=" + legs)
        cmds.append("big_wheel:=" + big_wheel)
        cmds.append("upper_body:=" + upper_body)
        cmds.append("velodyne:=" + velodyne)
        cmds.append("realsense:=" + realsense)
        cmds.append("floating_joint:=" + floating_joint)
        cmds.append("use_abs_mesh_paths:=true") # use absolute paths for meshes             \       

        cmds.append("end_effector_left:=ball")
        cmds.append("end_effector_right:=ball")

        if urdf_descr_root_path is not None:
                cmds.append("root:=" + urdf_descr_root_path)
        
        cmds+=custom_args_xacro
 
        return cmds