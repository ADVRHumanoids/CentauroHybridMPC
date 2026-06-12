from mpc_viz.utils.xrdf_gen import UrdfGenerator


class CentauroUrdfGen(UrdfGenerator):

    def __init__(self, 
            robotname: str,
            descr_path: str,
            big_wheels: bool = True,
            descr_path_dagana: str = None,
            end_eff_left: str = "ball",
            end_eff_right: str = "ball",
            custom_args_xacro = None,
            name: str = "CentauroUrdfMPCViz"):
        
        super().__init__(
            robotname = robotname,
            descr_path = descr_path,
            name = name)

        self._big_wheels = big_wheels
        self._end_eff_left=end_eff_left
        self._end_eff_right=end_eff_right
    
        self._descr_path_dagana=descr_path_dagana
        self._custom_args_xacro = custom_args_xacro or []

        self.generate_urdf() # actually generated urdf

    def _xrdf_cmds(self):
        
        # implements parent method 

        cmds = {} 
        
        cmds[self.robotname] = self._get_xrdf_cmds_centauro(root=self.descr_path)
        
        return cmds
    
    def _get_xrdf_cmds_centauro(self,
                root: str):
        
        cmds = []
        
        cmds.append("root:=" + root)
        if self._big_wheels:
            cmds.append("big_wheel:=true")
        else:
            cmds.append("big_wheel:=false")

        cmds.append("dagana_root:="+ self._descr_path_dagana)
        cmds.append("end_effector_left:="+ self._end_eff_left)
        cmds.append("end_effector_right:="+ self._end_eff_right)

        cmds.append("legs:=true")
        cmds.append("upper_body:=true")
        cmds.append("velodyne:=false")
        cmds.append("realsense:=false")
        cmds.append("floating_joint:=false")
        cmds.append("use_abs_mesh_paths:=true")
        cmds.append("use_local_filesys_for_meshes:=true")
        cmds += self._custom_args_xacro

        return cmds
