sshr() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: sshr user@hostname"
        return 1
    fi
    param="$1"
    host=${param#*@}
    echo "Removing known hosts entry for: $host"
    ssh-keygen -R "$host"
}
