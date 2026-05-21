check_gui() {
    log_info "Checking system requirements..."

    local has_gui=false

    if systemctl is-active --quiet xrdp 2>/dev/null; then
        log_info "xrdp service detected"
        has_gui=true
    fi

    if pgrep -E "^(weston|sway|wayfire|labwc|river|hyprland)$" >/dev/null 2>&1; then
        log_info "Wayland compositor detected"
        has_gui=true
    fi

    if [[ "$has_gui" == "false" ]]; then
        log_warn "No GUI session detected (xrdp or Wayland required)"
        log_warn "{{ . }}"
        exit 0
    fi
}
