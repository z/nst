# All plugins require this inc

# Needed to work with aliases
core_dir=$(cd $(dirname $0); pwd | sed 's#/extraz/pluginz##')

# Include config
source $core_dir/config/base.conf
