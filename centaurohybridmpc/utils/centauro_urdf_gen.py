from mpc_viz.utils.xrdf_gen import UrdfGenerator

class CentauroUrdfGen(UrdfGenerator):

    def __init__(self, 
            robotname: str,
            descr_path: str,
            big_wheels: bool = True,
            name: str = "CentauroUrdfMPCViz"):
        
        super().__init__(
            robotname = robotname,
            descr_path = descr_path,
            name = name)

        self._big_wheels = big_wheels

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

        cmds.append("legs:=true")
        cmds.append("upper_body:=true")
        cmds.append("velodyne:=false")
        cmds.append("realsense:=false")
        cmds.append("floating_joint:=false")
        cmds.append("use_abs_mesh_paths:=true")
        cmds.append("use_local_filesys_for_meshes:=true")

        return cmds
