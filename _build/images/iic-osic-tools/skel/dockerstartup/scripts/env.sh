# shellcheck shell=bash

function _path_add_tool_bin() {
    tool_name=$1
    for d in $TOOLS/$tool_name ; do
        if [ -d "${d}bin" ]; then
            export PATH=$PATH:${d}bin
        fi
    done
}

function _path_add_tool() {
    tool_name=$1
    for d in $TOOLS/$tool_name ; do
        if [ -d "${d}" ]; then
            export PATH=$PATH:${d%/}
        fi
    done
}

function _path_add_tool_custom() {
    custom_path=$1
    for d in $TOOLS/$custom_path/ ; do
        if [ -d "${d}" ]; then
            export PATH=$PATH:${d%/}
        fi
    done
}

function _path_add_tool_python() {
    tool_name=$1
    for d in "$TOOLS/$tool_name"/local/lib/python3*/dist-packages ; do
        if [ -d "${d}" ]; then
            export PYTHONPATH=$PYTHONPATH:${d}
        fi
    done
}

function _add_resolution () {
    # $1=X, $2=Y
    # do only in VNC mode
    if [ -v VNCDESKTOP ]; then
        # and only when resolution not yet available
        # shellcheck disable=SC2143 disable=SC2086
        if [ -z "$(xrandr 2> /dev/null | awk '{print $1}' | grep $1x$2)" ]; then
            #echo "[INFO] Set VNC mode $1x$2"
            MLINE=$(cvt $1 $2 60  | grep -oP '(?<=Modeline ).*')
            # shellcheck disable=SC2001
            MLINE_TRIM=$(echo "$MLINE" | sed 's/^[^"]*"[^"]*"//')
            xrandr --newmode $1x$2 $MLINE_TRIM
            xrandr --addmode VNC-0 $1x$2
        fi
    fi
}

if [ -z ${FOSS_INIT_DONE+x} ]; then
    _path_add_tool_bin      "covered"
    _path_add_tool_bin      "cvc_rv"
    _path_add_tool_bin      "gaw3-xschem"
    _path_add_tool_bin      "gds3d"
    _path_add_tool_bin      "ghdl"
    _path_add_tool_bin      "gtkwave"
    _path_add_tool_bin      "irsim"
    _path_add_tool_bin      "iverilog"
    _path_add_tool          "klayout"
    _path_add_tool_custom   "libman"
    _path_add_tool_bin      "magic"
    _path_add_tool_bin      "netgen"
    _path_add_tool_bin      "ngspice"
    _path_add_tool_bin      "nvc"
    _path_add_tool_bin      "openroad"
    _path_add_tool_bin      "opensta"
	_path_add_tool_bin	    "openvaf"
    _path_add_tool_custom   "osic-multitool"
    _path_add_tool_bin      "padring"
    _path_add_tool_bin      "pyopus"
    _path_add_tool_bin      "qflow"
    _path_add_tool_bin      "qucs-s"
    _path_add_tool_custom   "rftoolkit/bin"
    _path_add_tool_bin      "slang"
    _path_add_tool_bin      "surfer"
    _path_add_tool_bin      "verilator"
    _path_add_tool_bin      "xschem"
    _path_add_tool_bin      "xyce"
    _path_add_tool_bin      "yosys"
    _path_add_tool_custom   "yosys/bin"
	
    export SAK=$TOOLS/sak/
    export PATH=$TOOLS/bin:$SAK:/usr/local/sbin:$PATH

    # OpenROAD in Ubuntu 22.04 does not find the PIP modules, so use PYTHONPATH
    PYTHONPATH=$(python -c "import sys; print(':'.join(x for x in sys.path if x))") && export PYTHONPATH 
    _path_add_tool_python "ngspyce"
    _path_add_tool_python "pyopus"
    export PYTHONPATH=$PYTHONPATH:$TOOLS/yosys/share/yosys/python3
    KLAYOUT_PYTHON=("$TOOLS"/klayout/pymod)
    export PYTHONPATH=$PYTHONPATH:${KLAYOUT_PYTHON[*]}
    
    echo "[INFO] Final PATH variable: $PATH"
    echo "[INFO] Final PYTHONPATH variable: $PYTHONPATH"

    export FOSS_INIT_DONE=1
fi

# add additional display resolutions (for VNC mode)
_add_resolution 2048 1152
_add_resolution 2560 1080
_add_resolution 2560 1440
_add_resolution 2560 1600
_add_resolution 3440 1440
_add_resolution 3840 2160

# shellcheck disable=SC2086
LD_LIBRARY_PATH="$(realpath ${TOOLS}/klayout ):${TOOLS}/ngspice/lib" && export LD_LIBRARY_PATH
export XDG_RUNTIME_DIR=/tmp/runtime-default
export EDITOR="gedit"
export PYTHONPYCACHEPREFIX="/tmp/pycache"
export KLAYOUT_HOME="/headless/.klayout"

# setting default PDK
export PDK=sky130A
export PDKPATH=$PDK_ROOT/$PDK
export STD_CELL_LIBRARY=sky130_fd_sc_hd
export SPICE_USERINIT_DIR=$PDK_ROOT/$PDK/libs.tech/ngspice
export KLAYOUT_PATH="$PDKPATH/libs.tech/klayout:$PDKPATH/libs.tech/klayout/tech"

# this gets rid of a few libGL errors
# https://unix.stackexchange.com/questions/589236/libgl-error-no-matching-fbconfigs-or-visuals-found-glxgears-error-docker-cu
export LIBGL_ALWAYS_INDIRECT=1

# this gets rid of the DBUS warning
# https://unix.stackexchange.com/questions/230238/x-applications-warn-couldnt-connect-to-accessibility-bus-on-stderr/230442#230442
export NO_AT_BRIDGE=1

if [ ! -d $XDG_RUNTIME_DIR ]; then
    mkdir -p $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR
fi

# add local directories in $HOME to the path so that the user can upgrade PIP packages
export PATH=$HOME/.local/bin:$PATH
export PYTHONPATH=$HOME/.local/lib/python3.10/site-packages:$PYTHONPATH

#----------------------------------------
# tool aliases
#----------------------------------------

alias mmagic='MAGTYPE=mag magic'
alias lmagic='MAGTYPE=maglef magic'

alias k='klayout'
alias ke='klayout -e'

alias openlane='openlane --manual-pdk'
alias surfer='LIBGL_ALWAYS_INDIRECT=0 surfer'
# IHP-SG13G2 needs this plugin, using an alias seems to the the only proper solution for now
alias xyce='xyce -plugin $PDK_ROOT/ihp-sg13g2/libs.tech/xyce/plugins/Xyce_Plugin_PSP103_VA.so'
alias Xyce='Xyce -plugin $PDK_ROOT/ihp-sg13g2/libs.tech/xyce/plugins/Xyce_Plugin_PSP103_VA.so'

# Show hint that OpenLane(1) has been removed
alias flow.tcl='printf "[INFO] OpenLane(1) has been depreciated.\n[INFO] Please use OpenLane2 (start with <openlane>).\n"'

alias iic-pdk='source iic-pdk-script.sh'
alias tt='cd $TOOLS'
alias dd='cd $DESIGNS'
alias pp='cd $PDK_ROOT'
alias destroy='sudo \rm -rf'
alias cp='cp -i'
alias egrep='egrep '
alias fgrep='fgrep '
alias grep='grep '
alias ls='ls --color=auto'
alias l.='ls -d .* '
alias ll='ls -l'
alias la='ls -al '
alias llt='ls -lt'
alias llta='ls -alt'
alias du='du -skh'
alias mv='mv -i'
alias rm='rm -i'
alias vrc='vi ~/.bashrc'
alias dux='du -sh* | sort -h'
alias shs='md5sum'
alias h='history'
alias hh='history | grep'
alias rc='source ~/.bashrc'
alias m='less'
alias term='xfce4-terminal'

#----------------------------------------
# git
#----------------------------------------

alias gcl='git clone'
alias gcll='git clone --single-branch --depth=1'
alias ga='git add'
alias gc='git commit -a'
alias gps='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gss='git status'
alias gr='git remote -v'
alias gl='git log'
alias gln='git log --name-status'
alias gsss='git submodule status'

#----------------------------------------
# user functions
#----------------------------------------

function mdview() {
    if [ $# -eq 0 ]; then
        echo "Usage: mdview <file.md>"
    else
        pandoc "$1" > "/tmp/$1.html"
        xdg-open "/tmp/$1.html"
  fi
}

#----------------------------------------
# adapt user prompt
#----------------------------------------

export PS1='\[\033[0;32m\]\w >\[\033[0;38m\] '

#----------------------------------------
# source user configs from $DESIGNS
#----------------------------------------

if [ -f "$DESIGNS/.designinit" ]; then
    # shellcheck source=/dev/null
    source "$DESIGNS/.designinit"
fi
