#!/usr/bin/env bash
set -euo pipefail

REPO="agentkyo/gunbound-on-linux"
SITE="https://gunbound.gg"
DLL_URL="https://github.com/$REPO/releases/latest/download/ncrypt.dll"
# Portable Wine used when the system can't provide Wine 10+ (immutable distros
# such as Bazzite, Silverblue, SteamOS, or unknown package managers).
PORTABLE_WINE_VERSION="11.21"
PORTABLE_WINE_FILE="wine-$PORTABLE_WINE_VERSION-amd64-wow64.tar.xz"
PORTABLE_WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/$PORTABLE_WINE_VERSION/$PORTABLE_WINE_FILE"
PORTABLE_WINE_SHA256="33f3c5b56b1deb8f6725539ea006f27b5d781b3b4ae6a8a1f492d8af4fb9dc83"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WINEPREFIX="${WINEPREFIX:-$HOME/Games/gunbound}"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"
game_win='C:\GunBound'
game_dir="$WINEPREFIX/drive_c/GunBound"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gunbound-linux"
portable_dir="$data_dir/wine"
if [[ -n "${WINE:-}" ]]; then
    wine="$WINE"
elif [[ -x "$portable_dir/bin/wine" ]]; then
    wine="$portable_dir/bin/wine"
else
    wine=wine
fi
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
        immutable) en="Immutable system detected (%s). System packages will not be changed; using a portable Wine instead."
                   pt="Sistema imutável detectado (%s). Os pacotes do sistema não serão alterados; será usado um Wine portátil."
                   es="Sistema inmutable detectado (%s). No se modificarán los paquetes del sistema; se usará un Wine portátil." ;;
        pkgfail) en="Could not install Wine 10 or newer with the package manager. Using a portable Wine instead."
                 pt="Não foi possível instalar o Wine 10 ou mais novo pelo gerenciador de pacotes. Será usado um Wine portátil."
                 es="No se pudo instalar Wine 10 o más reciente con el gestor de paquetes. Se usará un Wine portátil." ;;
        portable) en="Downloading portable Wine %s (about 100 MB) into %s"
                  pt="Baixando o Wine portátil %s (cerca de 100 MB) em %s"
                  es="Descargando Wine portátil %s (unos 100 MB) en %s" ;;
        portablefail) en="Could not download or verify the portable Wine. Check your internet connection, or install Wine 10 or newer and run again with WINE=/path/to/wine"
                      pt="Não foi possível baixar ou verificar o Wine portátil. Verifique sua conexão, ou instale o Wine 10 ou mais novo e rode de novo com WINE=/caminho/do/wine"
                      es="No se pudo descargar o verificar el Wine portátil. Revisa tu conexión, o instala Wine 10 o más reciente y vuelve a ejecutar con WINE=/ruta/a/wine" ;;
        portablebroken) en="The portable Wine does not start on this system. Install Wine 10 or newer (e.g. via Flatpak, Distrobox or your package manager) and run again with WINE=/path/to/wine"
                        pt="O Wine portátil não abre neste sistema. Instale o Wine 10 ou mais novo (por exemplo via Flatpak, Distrobox ou gerenciador de pacotes) e rode de novo com WINE=/caminho/do/wine"
                        es="El Wine portátil no se inicia en este sistema. Instala Wine 10 o más reciente (por ejemplo con Flatpak, Distrobox o tu gestor de paquetes) y vuelve a ejecutar con WINE=/ruta/a/wine" ;;
        needtool) en="'%s' is required but was not found. Install it and run again."
                  pt="'%s' é necessário mas não foi encontrado. Instale e rode de novo."
                  es="Se necesita '%s' pero no se encontró. Instálalo y vuelve a ejecutar." ;;
        badarch) en="Only x86_64 (64-bit Intel/AMD) is supported; this machine is %s."
                 pt="Só x86_64 (Intel/AMD 64 bits) é suportado; esta máquina é %s."
                 es="Solo se admite x86_64 (Intel/AMD de 64 bits); esta máquina es %s." ;;
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
  PORTABLE_WINE=1          always use the portable Wine (no system packages)
EOF
}

has() { command -v "$1" >/dev/null 2>&1; }

# fetch URL DEST: download with curl, or wget when curl is missing.
fetch() {
    if has curl; then
        curl -fL --retry 3 -o "$2" "$1" >&2
    elif has wget; then
        wget -O "$2" "$1" >&2
    else
        die needtool curl
    fi
}

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
    sudo pacman -S --needed "${pkgs[@]}" || { warn multilib; return 1; }
}

install_apt() {
    local distro="$1" code="$2"
    sudo apt-get update || return 1
    sudo apt-get install -y curl ca-certificates gpg xz-utils || return 1
    wine_ok && return 0
    local sources="https://dl.winehq.org/wine-builds/$distro/dists/$code/winehq-$code.sources"
    if [[ -n "$code" ]] && curl -fsIL "$sources" >/dev/null 2>&1; then
        log winehq
        sudo dpkg --add-architecture i386 || return 1
        sudo mkdir -pm755 /etc/apt/keyrings || return 1
        curl -fsSL https://dl.winehq.org/wine-builds/winehq.key |
            sudo gpg --yes --dearmor -o /etc/apt/keyrings/winehq-archive.key || return 1
        sudo curl -fsSL -o "/etc/apt/sources.list.d/winehq-$code.sources" "$sources" || return 1
        sudo apt-get update || return 1
        sudo apt-get install -y --install-recommends winehq-stable
    else
        sudo dpkg --add-architecture i386 || return 1
        sudo apt-get update || return 1
        sudo apt-get install -y wine wine64 wine32
    fi
}

# Prints a reason and succeeds when system packages can't (or shouldn't) be
# installed: image-based/read-only systems.
immutable_reason() {
    local id variant
    id="$(os_field ID)"
    variant="$(os_field VARIANT_ID)"
    if [[ -e /run/ostree-booted ]]; then
        printf '%s' "${variant:-${id:-ostree}}"
    elif [[ "$id" == steamos || "$id" == nixos || "$id" == opensuse-microos ||
            "$id" == opensuse-aeon || "$id" == opensuse-kalpa || "$id" == endless ]]; then
        printf '%s' "$id"
    elif has abroot; then
        printf '%s' "${id:-ABRoot}"
    elif has transactional-update; then
        printf '%s' "${id:-transactional-update}"
    else
        return 1
    fi
}

install_portable_wine() {
    local arch
    arch="$(uname -m)"
    [[ "$arch" == x86_64 ]] || die badarch "$arch"
    has tar || die needtool tar
    has xz || die needtool xz
    has sha256sum || die needtool sha256sum
    wine="$portable_dir/bin/wine"
    if wine_ok; then
        log wineok "$(wine_major)"
        return 0
    fi
    log portable "$PORTABLE_WINE_VERSION" "$portable_dir"
    mkdir -p "$data_dir"
    local archive="$data_dir/$PORTABLE_WINE_FILE.part" tmp="$data_dir/wine.tmp"
    if ! fetch "$PORTABLE_WINE_URL" "$archive" ||
        ! printf '%s  %s\n' "$PORTABLE_WINE_SHA256" "$archive" | sha256sum -c --status; then
        rm -f "$archive"
        die portablefail
    fi
    rm -rf "$tmp"
    mkdir -p "$tmp"
    if ! tar -xJf "$archive" -C "$tmp" --strip-components=1; then
        rm -rf "$tmp" "$archive"
        die portablefail
    fi
    rm -f "$archive"
    rm -rf "$portable_dir"
    mv "$tmp" "$portable_dir"
    wine_ok || die portablebroken
    log wineok "$(wine_major)"
}

install_system_wine() {
    local id like
    like="$(os_field ID_LIKE)"
    id="$(os_field ID)"
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
            sudo dnf install -y wine curl xz ;;
        *" suse "*|*" opensuse "*)
            log sudo
            sudo zypper install -y wine curl xz ;;
        *)
            return 1 ;;
    esac
}

install_deps() {
    local id like reason
    like="$(os_field ID_LIKE)"
    id="$(os_field ID)"
    # A portable Wine installed earlier is reused as is.
    if [[ "$wine" == "$portable_dir/bin/wine" ]] && wine_ok; then
        log wineok "$(wine_major)"
        return 0
    fi
    if [[ -n "${PORTABLE_WINE:-}" && "${PORTABLE_WINE}" != 0 ]]; then
        install_portable_wine
        return
    fi
    if reason="$(immutable_reason)"; then
        if wine_ok; then
            log wineok "$(wine_major)"
        else
            log immutable "$reason"
            install_portable_wine
        fi
        return
    fi
    if wine_ok && has curl && [[ " $id $like " != *" arch "* ]]; then
        log wineok "$(wine_major)"
        return 0
    fi
    install_system_wine || true
    if wine_ok; then
        log wineok "$(wine_major)"
        return 0
    fi
    # Wine is missing, too old, or the package manager failed: if the user
    # pointed WINE at a specific binary, respect it; otherwise go portable.
    if [[ -n "${WINE:-}" ]]; then
        has "$wine" || die nowine
        warn oldwine "$(wine_major)"
        return 0
    fi
    warn pkgfail
    install_portable_wine
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
    if fetch "$DLL_URL" "$data_dir/ncrypt.dll.part" && is_pe "$data_dir/ncrypt.dll.part"; then
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
    local env_wine=""
    # Keep a custom WINE in the shortcut; the portable Wine is found on its own.
    [[ -n "${WINE:-}" && "$wine" == */* ]] && env_wine=" WINE=\"$wine\""
    [[ "$here/gunbound-linux.sh" -ef "$data_dir/gunbound-linux.sh" ]] ||
        install -m 0755 "$here/gunbound-linux.sh" "$data_dir/gunbound-linux.sh"
    cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=GunBound
Comment=GunBound on Linux (Wine)
Exec=env WINEPREFIX="$WINEPREFIX"$env_wine "$data_dir/gunbound-linux.sh" run
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
