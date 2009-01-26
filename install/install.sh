#!/bin/bash
# This is a quick start installation file, it chmod's the core and the core
# handles the rest

cd ..
latest_core=$(ls nst_core* |tail -n1)
chmod +x $latest_core
./$latest_core --install_nst
