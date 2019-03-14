IS_WIN=""
IS_MAC=""
IS_LINUX=""

if [ ! -z "$WINDIR" ]; then
    IS_WIN=true
elif [[ "$OSTYPE" =~ ^darwin ]]; then
    IS_MAC=true
else
    IS_LINUX=true
fi

export IS_WIN
export IS_MAC
export IS_LINUX
