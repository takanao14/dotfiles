sshr() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: sshr [user@]hostname" >&2
        return 1
    fi

    local param host
    param="$1"
    host="${param#*@}"

    if [[ -z "$host" ]]; then
        echo "sshr: hostname is empty" >&2
        return 1
    fi

    echo "Removing known hosts entry for: $host"
    command ssh-keygen -R "$host"
}
