#!/usr/bin/env bash
set -euo pipefail

REPO="agentkyo/gunbound-on-linux"
SITE="https://gunbound.gg"
DLL_URL="https://github.com/$REPO/releases/latest/download/ncrypt.dll"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WINEPREFIX="${WINEPREFIX:-$HOME/Games/gunbound}"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"
wine="${WINE:-wine}"
game_win='C:\GunBound'
game_dir="$WINEPREFIX/drive_c/GunBound"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gunbound-linux"
desktop_file="${XDG_DATA_HOME:-$HOME/.local/share}/applications/gunbound-linux.desktop"

case "${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}" in
    pt*) lang=pt ;;
    es*) lang=es ;;
    *) lang=en ;;
esac

t() {
    local key="$1"
    shift
    local en pt es
    case "$key" in
        root) en="Do not run this script as root. It will ask for sudo when needed."
              pt="Não rode este script como root. Ele pede sudo quando precisar."
              es="No ejecutes este script como root. Pedirá sudo cuando sea necesario." ;;
        deps) en="Installing dependencies for %s"
              pt="Instalando dependências para %s"
              es="Instalando dependencias para %s" ;;
        sudo) en="Your password may be requested to install system packages."
              pt="Sua senha pode ser pedida para instalar pacotes do sistema."
              es="Es posible que se pida tu contraseña para instalar paquetes del sistema." ;;
        multilib) en="pacman failed. Enable the [multilib] repository in /etc/pacman.conf and try again."
                  pt="O pacman falhou. Habilite o repositório [multilib] em /etc/pacman.conf e tente de novo."
                  es="pacman falló. Habilita el repositorio [multilib] en /etc/pacman.conf e inténtalo de nuevo." ;;
        winehq) en="Adding the official WineHQ repository (Wine 10 or newer is required)"
                pt="Adicionando o repositório oficial do WineHQ (é preciso Wine 10 ou mais novo)"
                es="Agregando el repositorio oficial de WineHQ (se requiere Wine 10 o más reciente)" ;;
        unknown_distro) en="Unknown distribution. Install Wine 10 or newer and curl with your package manager, then run this script again."
                        pt="Distribuição não reconhecida. Instale o Wine 10 ou mais novo e o curl pelo seu gerenciador de pacotes e rode o script de novo."
                        es="Distribución no reconocida. Instala Wine 10 o más reciente y curl con tu gestor de paquetes y vuelve a ejecutar el script." ;;
        nowine) en="Wine was not found after installing dependencies."
                pt="O Wine não foi encontrado depois de instalar as dependências."
                es="No se encontró Wine después de instalar las dependencias." ;;
        oldwine) en="Wine %s detected. Wine 10 or newer is recommended; the game may not work."
                 pt="Wine %s detectado. O recomendado é Wine 10 ou mais novo; o jogo pode não funcionar."
                 es="Wine %s detectado. Se recomienda Wine 10 o más reciente; es posible que el juego no funcione." ;;
        wineok) en="Wine %s"
                pt="Wine %s"
                es="Wine %s" ;;
        found) en="Installer found: %s"
               pt="Instalador encontrado: %s"
               es="Instalador encontrado: %s" ;;
        notexe) en="%s is not a Windows executable."
                pt="%s não é um executável do Windows."
                es="%s no es un ejecutable de Windows." ;;
        noinstaller) en="GunBound installer (.exe) not found. Download it at %s"
                     pt="Instalador do GunBound (.exe) não encontrado. Baixe em %s"
                     es="No se encontró el instalador de GunBound (.exe). Descárgalo en %s" ;;
        waiting) en="Waiting for the download... (or type the path to the .exe and press Enter)"
                 pt="Aguardando o download... (ou digite o caminho do .exe e aperte Enter)"
                 es="Esperando la descarga... (o escribe la ruta del .exe y presiona Enter)" ;;
        prefix) en="Wine prefix: %s"
                pt="Prefixo do Wine: %s"
                es="Prefijo de Wine: %s" ;;
        zdrive) en="Removing the Z: drive from the prefix (the installer rejects it)"
                pt="Removendo o drive Z: do prefixo (o instalador recusa esse drive)"
                es="Eliminando la unidad Z: del prefijo (el instalador la rechaza)" ;;
        exists) en="%s already exists, skipping extraction"
                pt="%s já existe, pulando a extração"
                es="%s ya existe, se omite la extracción" ;;
        extract) en="Extracting the game into %s (this can take a few minutes)"
                 pt="Extraindo o jogo em %s (isso pode levar alguns minutos)"
                 es="Extrayendo el juego en %s (puede tardar unos minutos)" ;;
        extractfail) en="Extraction failed."
                     pt="A extração falhou."
                     es="La extracción falló." ;;
        nolauncher) en="launcher.exe was not found in %s"
                    pt="launcher.exe não foi encontrado em %s"
                    es="No se encontró launcher.exe en %s" ;;
        download) en="Downloading ncrypt.dll from the latest release"
                  pt="Baixando o ncrypt.dll do último release"
                  es="Descargando ncrypt.dll de la última versión" ;;
        nodll) en="Could not get ncrypt.dll. Check your internet connection, or set NCRYPT_DLL=/path/to/ncrypt.dll"
               pt="Não foi possível obter o ncrypt.dll. Verifique sua conexão com a internet, ou defina NCRYPT_DLL=/caminho/ncrypt.dll"
               es="No se pudo obtener ncrypt.dll. Revisa tu conexión a internet, o define NCRYPT_DLL=/ruta/ncrypt.dll" ;;
        ncrypt) en="Installing ncrypt.dll for launcher.exe only"
                pt="Instalando o ncrypt.dll apenas para o launcher.exe"
                es="Instalando ncrypt.dll solo para launcher.exe" ;;
        menu) en="Menu shortcut: %s"
              pt="Atalho no menu: %s"
              es="Acceso directo en el menú: %s" ;;
        notinstalled) en="The game is not installed. Run: %s"
                      pt="O jogo não está instalado. Rode: %s"
                      es="El juego no está instalado. Ejecuta: %s" ;;
        launch) en="Opening the GunBound launcher. Have fun!"
                pt="Abrindo o launcher do GunBound. Divirta-se!"
                es="Abriendo el launcher de GunBound. ¡Diviértete!" ;;
        finished) en="Installation complete. Next time use the \"GunBound\" menu shortcut or: %s run"
              pt="Instalação concluída. Da próxima vez use o atalho \"GunBound\" no menu ou: %s run"
              es="Instalación completa. La próxima vez usa el acceso directo \"GunBound\" del menú o: %s run" ;;
        confirm) en="This deletes %s and everything inside it, including the game. Type 'yes' to confirm:"
                 pt="Isto apaga %s e tudo dentro dele, inclusive o jogo. Digite 'sim' para confirmar:"
                 es="Esto borra %s y todo su contenido, incluido el juego. Escribe 'si' para confirmar:" ;;
        removed) en="Removed."
                 pt="Removido."
                 es="Eliminado." ;;
        cancelled) en="Cancelled."
                   pt="Cancelado."
                   es="Cancelado." ;;
        ok) en="ok"
            pt="ok"
            es="ok" ;;
    esac
    local text
    case "$lang" in
        pt) text="$pt" ;;
        es) text="$es" ;;
        *) text="$en" ;;
    esac
    # shellcheck disable=SC2059 # translated strings are the format
    printf "$text" "$@"
}

log() { printf '\033[1;32m==>\033[0m %s\n' "$(t "$@")"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$(t "$@")" >&2; }
die() { printf '\033[1;31m==>\033[0m %s\n' "$(t "$@")" >&2; exit 1; }

usage() {
    cat <<EOF
GunBound on Linux - https://github.com/$REPO

  $0                       install (if needed) and open the launcher
  $0 install [setup.exe]   install the game
  $0 run                   open the launcher
  $0 repair                reinstall ncrypt.dll and the Wine override
  $0 uninstall             remove the prefix, the shortcut and the files

  WINEPREFIX=$WINEPREFIX
  WINE=$wine
  NCRYPT_DLL=/path/to/ncrypt.dll
EOF
}

has() { command -v "$1" >/dev/null 2>&1; }

wait_server() {
    local server=wineserver
    [[ "$wine" == */* && -x "${wine%/*}/wineserver" ]] && server="${wine%/*}/wineserver"
    has "$server" || return 0
    "$server" "${1:--w}" >/dev/null 2>&1 || true
}

wine_major() {
    "$wine" --version 2>/dev/null | sed -n 's/^wine-\([0-9]*\).*/\1/p'
}

wine_ok() {
    has "$wine" || return 1
    local major
    major="$(wine_major)"
    [[ -n "$major" && "$major" -ge 10 ]]
}

os_field() {
    [[ -r /etc/os-release ]] || return 0
    (. /etc/os-release && eval "printf '%s' \"\${$1:-}\"")
}

install_arch() {
    local pkgs=(wine gnutls libpulse alsa-lib alsa-plugins mesa curl) missing
    missing="$(pacman -T "${pkgs[@]}" || true)"
    [[ -z "$missing" ]] && return 0
    log sudo
    sudo pacman -S --needed "${pkgs[@]}" || die multilib
}

install_apt() {
    local distro="$1" code="$2"
    sudo apt-get update
    sudo apt-get install -y curl ca-certificates gpg
    wine_ok && return 0
    local sources="https://dl.winehq.org/wine-builds/$distro/dists/$code/winehq-$code.sources"
    if [[ -n "$code" ]] && curl -fsIL "$sources" >/dev/null 2>&1; then
        log winehq
        sudo dpkg --add-architecture i386
        sudo mkdir -pm755 /etc/apt/keyrings
        curl -fsSL https://dl.winehq.org/wine-builds/winehq.key |
            sudo gpg --yes --dearmor -o /etc/apt/keyrings/winehq-archive.key
        sudo curl -fsSL -o "/etc/apt/sources.list.d/winehq-$code.sources" "$sources"
        sudo apt-get update
        sudo apt-get install -y --install-recommends winehq-stable
    else
        sudo dpkg --add-architecture i386
        sudo apt-get update
        sudo apt-get install -y wine wine64 wine32
    fi
}

install_deps() {
    local id like
    like="$(os_field ID_LIKE)"
    id="$(os_field ID)"
    if wine_ok && has curl && [[ " $id $like " != *" arch "* ]]; then
        log wineok "$(wine_major)"
        return 0
    fi
    log deps "$(os_field PRETTY_NAME)"
    case " $id $like " in
        *" arch "*)
            install_arch ;;
        *" ubuntu "*)
            log sudo
            local code
            code="$(os_field UBUNTU_CODENAME)"
            install_apt ubuntu "${code:-$(os_field VERSION_CODENAME)}" ;;
        *" debian "*)
            log sudo
            install_apt debian "$(os_field VERSION_CODENAME)" ;;
        *" fedora "*|*" rhel "*)
            log sudo
            sudo dnf install -y wine curl ;;
        *" suse "*|*" opensuse "*)
            log sudo
            sudo zypper install -y wine curl ;;
        *)
            { has "$wine" && has curl; } || die unknown_distro ;;
    esac
    has "$wine" || die nowine
    if wine_ok; then
        log wineok "$(wine_major)"
    else
        warn oldwine "$(wine_major)"
    fi
}

is_pe() {
    [[ -f "$1" ]] && [[ "$(head -c 2 "$1" 2>/dev/null)" == "MZ" ]]
}

search_dirs() {
    local d
    has xdg-user-dir && d="$(xdg-user-dir DOWNLOAD 2>/dev/null)" && [[ -n "$d" ]] && printf '%s\n' "$d"
    printf '%s\n' "$HOME/Downloads" "$HOME/Transferências" "$HOME/Descargas" \
        "$HOME/Desktop" "$HOME/Área de Trabalho" "$HOME/Escritorio" "$PWD" "$here" "$HOME"
}

scan_installer() {
    local dir
    while IFS= read -r dir; do
        [[ -d "$dir" ]] || continue
        find "$dir" -maxdepth 2 -type f -iname '*gunbound*.exe' -printf '%T@\t%p\n' 2>/dev/null || true
    done < <(search_dirs | awk '!seen[$0]++') |
        sort -rn | cut -f2- | while IFS= read -r file; do
            is_pe "$file" && { printf '%s\n' "$file"; break; }
        done || true
}

open_url() {
    if has xdg-open; then
        xdg-open "$1" >/dev/null 2>&1 &
    fi
}

find_installer() {
    local setup="${1:-}"
    if [[ -n "$setup" ]]; then
        is_pe "$setup" || die notexe "$setup"
        printf '%s\n' "$setup"
        return
    fi
    setup="$(scan_installer)"
    if [[ -n "$setup" ]]; then
        printf '%s\n' "$setup"
        return
    fi
    warn noinstaller "$SITE"
    [[ -t 0 ]] || exit 1
    open_url "$SITE"
    warn waiting
    local typed
    while :; do
        if read -r -t 3 typed; then
            typed="${typed/#\~/$HOME}"
            typed="${typed%\'}"
            typed="${typed#\'}"
            if is_pe "$typed"; then
                printf '%s\n' "$typed"
                return
            fi
            warn notexe "$typed"
        fi
        setup="$(scan_installer)"
        if [[ -n "$setup" ]]; then
            sleep 2
            printf '%s\n' "$setup"
            return
        fi
    done
}

get_dll() {
    if [[ -n "${NCRYPT_DLL:-}" ]]; then
        is_pe "$NCRYPT_DLL" || die notexe "$NCRYPT_DLL"
        printf '%s\n' "$NCRYPT_DLL"
        return
    fi
    local candidate
    for candidate in "$here/ncrypt.dll" "$data_dir/ncrypt.dll"; do
        if is_pe "$candidate"; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    log download >&2
    mkdir -p "$data_dir"
    if curl -fL --retry 3 -o "$data_dir/ncrypt.dll.part" "$DLL_URL" >&2 && is_pe "$data_dir/ncrypt.dll.part"; then
        mv -f "$data_dir/ncrypt.dll.part" "$data_dir/ncrypt.dll"
        printf '%s\n' "$data_dir/ncrypt.dll"
        return
    fi
    rm -f "$data_dir/ncrypt.dll.part"
    die nodll
}

install_ncrypt() {
    [[ -f "$game_dir/launcher.exe" ]] || die notinstalled "$0 install"
    local dll
    dll="$(get_dll)"
    log ncrypt
    mkdir -p "$data_dir"
    [[ "$dll" -ef "$data_dir/ncrypt.dll" ]] || install -m 0644 "$dll" "$data_dir/ncrypt.dll"
    install -m 0644 "$dll" "$game_dir/ncrypt.dll"
    "$wine" reg add 'HKCU\Software\Wine\AppDefaults\launcher.exe\DllOverrides' \
        /v ncrypt /d native,builtin /f >/dev/null 2>&1
}

install_runtime() {
    mkdir -p "$data_dir" "$(dirname "$desktop_file")"
    [[ "$here/gunbound-linux.sh" -ef "$data_dir/gunbound-linux.sh" ]] ||
        install -m 0755 "$here/gunbound-linux.sh" "$data_dir/gunbound-linux.sh"
    cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=GunBound
Comment=GunBound on Linux (Wine)
Exec=env WINEPREFIX="$WINEPREFIX" "$data_dir/gunbound-linux.sh" run
Icon=applications-games
Categories=Game;
Terminal=false
EOF
    has update-desktop-database && update-desktop-database "$(dirname "$desktop_file")" >/dev/null 2>&1 || true
    log menu "$desktop_file"
}

cmd_install() {
    install_deps
    local setup
    setup="$(find_installer "${1:-}")"
    log found "$setup"
    log prefix "$WINEPREFIX"
    mkdir -p "$WINEPREFIX"
    [[ -f "$WINEPREFIX/system.reg" ]] || "$wine" wineboot -i >/dev/null 2>&1 || true
    wait_server
    if [[ -L "$WINEPREFIX/dosdevices/z:" ]]; then
        log zdrive
        rm -f "$WINEPREFIX/dosdevices/z:"
    fi
    if [[ -f "$game_dir/launcher.exe" ]]; then
        log exists "$game_win"
    else
        rm -rf "$game_dir"
        mkdir -p "$WINEPREFIX/drive_c/installers"
        cp -f "$setup" "$WINEPREFIX/drive_c/installers/GunBound-Setup.exe"
        log extract "$game_win"
        (cd "$WINEPREFIX/drive_c/installers" &&
            "$wine" 'C:\installers\GunBound-Setup.exe' --extract-only "$game_win") || die extractfail
        [[ -f "$game_dir/launcher.exe" ]] || die nolauncher "$game_win"
    fi
    install_ncrypt
    install_runtime
    log finished "$data_dir/gunbound-linux.sh"
}

cmd_run() {
    [[ -f "$game_dir/launcher.exe" ]] || die notinstalled "$0"
    [[ -f "$game_dir/ncrypt.dll" ]] || install_ncrypt
    log launch
    cd "$game_dir"
    if [[ "${1:-}" == "--foreground" ]]; then
        exec "$wine" 'C:\GunBound\launcher.exe'
    fi
    setsid -f "$wine" 'C:\GunBound\launcher.exe' </dev/null >/dev/null 2>&1
}

cmd_uninstall() {
    local word answer
    case "$lang" in
        pt) word=sim ;;
        es) word=si ;;
        *) word=yes ;;
    esac
    printf '%s ' "$(t confirm "$WINEPREFIX")"
    read -r answer
    [[ "$answer" == "$word" ]] || die cancelled
    wait_server -k
    rm -rf "$WINEPREFIX" "$data_dir" "$desktop_file"
    log removed
}

[[ "$(id -u)" -ne 0 ]] || die root

case "${1:-}" in
    "")
        [[ -f "$game_dir/launcher.exe" ]] || cmd_install
        cmd_run ;;
    install) shift; cmd_install "$@"; cmd_run ;;
    run) shift; cmd_run "$@" ;;
    repair) install_ncrypt; log ok ;;
    uninstall) cmd_uninstall ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
esac
