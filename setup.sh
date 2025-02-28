#! /usr/bin/with-contenv bashio

set -ex

function change_shell() {
    apk add shadow
    local new_shell="$1"
    chsh -s "$new_shell"
}

function link_dir_data_home() {
    local relative_path="$1"
    mkdir -p "/data/$relative_path"
    if bashio::fs.directory_exists "$HOME/$relative_path" && [ -n "$(ls -A /root/.config 2>/dev/null)" ]; then
        mv -n "$HOME/$relative_path/"* "/data/$relative_path/"
        mv "$HOME/$relative_path" "$HOME/$relative_path.bak"
    fi
    ln -s "/data/$relative_path" "$HOME/$relative_path"
}

function main() {
    local ssh_user
    ssh_user=$(bashio::config 'ssh.username')

    echo "Current user is $(whoami) and home $HOME. Config user is $(ssh_user)"

    # If fish is present, use it
    if type fish &> /dev/null; then
        change_shell "$(which fish)"
    fi

    # Fix regression to make sure we will switch to root if auth user uses zsh
    echo "exec sudo -i" > "/home/$ssh_user/.zprofile"

    # Link persistent home dir folders
    link_dir_data_home workspace
    link_dir_data_home .config
    link_dir_data_home .local
    link_dir_data_home .docker
    link_dir_data_home .terminfo

    # Link .terminfo to login user so installing terminfos over ssh works
    ln -s /data/.terminfo "/home/$ssh_user/.terminfo"

    # Move default tmux conf so bootstrap will replace it
    mv ~/.tmux.conf ~/.tmux.conf.bak
    # Copy tmuxline config
    ln -s /data/.tmuxline.conf "$HOME/.tmuxline.conf"

    # Bootstrap user
    /data/workspace/shoestrap/hass

    # Bootstrap vim and nvim
    /data/workspace/vim-settings/install-helpers.py --no-debuggers bash python json yaml docker
    /data/workspace/vim-settings/vim-sync-append.sh
}

main
