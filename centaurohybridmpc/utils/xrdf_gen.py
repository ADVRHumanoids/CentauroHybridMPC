def get_xrdf_cmds_isaac():

        cmds = []
        
        xrdf_cmd_vals = [True, True, True, False, False, False]

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

        return cmds

def get_xrdf_cmds_horizon():

        cmds = []
        
        xrdf_cmd_vals = [True, True, True, False, False, True]

        legs = "true" if xrdf_cmd_vals[0] else "false"
        big_wheel = "true" if xrdf_cmd_vals[1] else "false"
        upper_body ="true" if xrdf_cmd_vals[2] else "false"
        velodyne = "true" if xrdf_cmd_vals[3] else "false"
        realsense = "true" if xrdf_cmd_vals[4] else "false"
        floating_joint = "true" if xrdf_cmd_vals[5] else "false" # horizon needs a floating joint

        cmds.append("legs:=" + legs)
        cmds.append("big_wheel:=" + big_wheel)
        cmds.append("upper_body:=" + upper_body)
        cmds.append("velodyne:=" + velodyne)
        cmds.append("realsense:=" + realsense)
        cmds.append("floating_joint:=" + floating_joint)

        return cmds