### CentauroHybridMPC package

The preferred way of using CentauroHybridMPC package is to employ the provided [mamba](https://mamba.readthedocs.io/en/latest/user_guide/mamba.html) environment. 

Installation instructions:
- First install Mamba by running ```curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"``` and then ```bash Mambaforge-$(uname)-$(uname -m).sh```.

- Create the mamba environment by running ```create_mamba_env.sh```. This will properly setup a Python 3.7 mamba environment named ```centaurohybridmpc``` with (almost) all necessary dependencies

- Activate the environment with ```mamba activate centaurohybridmpc```

- From the root folder install the package with ```pip install -e .```.

- Test the Lunar Lander example from StableBaselines3 v2.0 with ```python centaurohybridmpc/tests/test_lunar_lander_stable_bs3.py```.

- Download [Omniverse Launcer](https://www.nvidia.com/en-us/omniverse/download/), go to the "exchange" tab and install ``` Omniverse Cache``` and  ```Isaac Sim 2022.2.1```  (might take a while). You can then launch it from the Launcher GUI or by navigating to ```${HOME}/.local/share/ov/pkg/isaac_sim-2022.2.1``` and running the ```isaac-sim.sh``` script. When launching IsaacSim for the first time, compilation of ray tracing shaders will take place and may take a while. If the resources of the workstation/pc are limited (e.g. RAM < 16GB), the compilation may abort after a while. You can still manage to compile them by adding sufficient SWAP memory to the system. Before trying to recompile the shaders, remember however to first delete the cache at ```.cache/ov/Kit/*```.

- To be able to run any script with dependencies on Omniverse packages, it's necessary to first source ```${HOME}/.local/share/ov/pkg/isaac_sim-*/setup_conda_env.sh```..

- To be able to use the controllers, you need to install also the remaining external dependencies (ocs2, horizon, phase_manager).

External dependencies to be installed separately: 
<!-- - [horizon-casadi](https://github.com/ADVRHumanoids/horizon), T.O. tool tailored to robotics, based on [Casadi](https://web.casadi.org/). Branch to be used: ```add_nodes_py37```. Clone this repo at your preferred location and, from its root, run ```pip install --no-deps -e .```. This will install the package in editable mode without its dependencies (this is necessary to avoid circumvent current issues with horizon's pip distribution). -->
<!-- - [casadi_kin_dyn](https://github.com/ADVRHumanoids/horizon), generation of symbolic expressions for robot kinematics and dynamics, based on [http://wiki.ros.org/urdf](URDF) and [https://github.com/stack-of-tasks/pinocchio](Pinocchio). This library is automatically installed through mamba config file. -->
- [phase_manager](https://github.com/FrancescoRuscelli/phase_manager/tree/master). Currently stable branch: ```add_nodes```. Build this CMake package in you workspace (after activating the ```kyonrlstepping``` environment) and set the ```CMAKE_INSTALL_PREFIX``` to ```${HOME}/mambaforge/envs/kyonrlstepping```. 
<!-- - [Cartesian Interface](https://github.com/ADVRHumanoids/CartesianInterface/tree/2.0-devel) -->
- [Omniverse Isaac Sim](https://docs.omniverse.nvidia.com/app_isaacsim/app_isaacsim.html), photo-realistic GPU accelerated simulatorfrom NVIDIA.

### Short-term ToDo list:

- [x] Create package