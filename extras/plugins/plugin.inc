# All plugins require this inc

# Needed to work with aliases
core_dir=$(cd $(dirname $0); pwd | sed 's#/extras/plugins##')

# Include config
source $core_dir/config/base.conf
