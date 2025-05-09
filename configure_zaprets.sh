#!/bin/sh

URL="https://raw.githubusercontent.com/basek-diell/xia3000t./refs/heads/main"
DIR="/etc/config"
DIR_BACKUP="/root/backup"
config_files="dhcp
youtubeUnblock
https-dns-proxy"

# ===== НАЧАЛО функций =====

# Ищем нужную секцию dnsmasq
find_dnsmasq_section() {
  uci show dhcp | grep "=dnsmasq" | head -n1 | cut -d. -f2 | cut -d= -f1
}

checkAndAddDomainPermanentName() {
  nameRule="option name '$1'"
  str=$(grep -i "$nameRule" /etc/config/dhcp)
  if [ -z "$str" ]; then
    uci add dhcp domain
    uci set dhcp.@domain[-1].name="$1"
    uci set dhcp.@domain[-1].ip="$2"
    uci commit dhcp
  fi
}

manage_package() {
  local name="$1"
  local autostart="$2"
  local process="$3"

  if opkg list-installed | grep -q "^$name"; then
    if /etc/init.d/$name enabled; then
      [ "$autostart" = "disable" ] && /etc/init.d/$name disable
    else
      [ "$autostart" = "enable" ] && /etc/init.d/$name enable
    fi

    if pidof $name > /dev/null; then
      [ "$process" = "stop" ] && /etc/init.d/$name stop
    else
      [ "$process" = "start" ] && /etc/init.d/$name start
    fi
  fi
}

install_youtubeunblock_packages() {
  PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')
  BASE_URL="https://github.com/Waujito/youtubeUnblock/releases/download/v1.0.0/"
  AWG_DIR="/tmp/youtubeUnblock"
  mkdir -p "$AWG_DIR"

  if ! opkg list-installed | grep -q youtubeUnblock; then
    PACKAGES="kmod-nfnetlink-queue kmod-nft-queue kmod-nf-conntrack"
    for pkg in $PACKAGES; do
      opkg list-installed | grep -q "^$pkg " || opkg install $pkg || exit 1
    done

    YOUTUBEUNBLOCK_FILENAME="youtubeUnblock-1.0.0-10-f37c3dd-${PKGARCH}-openwrt-23.05.ipk"
    wget -O "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME" "$BASE_URL$YOUTUBEUNBLOCK_FILENAME" || exit 1
    opkg install "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME" || exit 1
  fi

  if ! opkg list-installed | grep -q luci-app-youtubeUnblock; then
    YOUTUBEUNBLOCK_GUI="luci-app-youtubeUnblock-1.0.0-10-f37c3dd.ipk"
    wget -O "$AWG_DIR/$YOUTUBEUNBLOCK_GUI" "$BASE_URL$YOUTUBEUNBLOCK_GUI" || exit 1
    opkg install "$AWG_DIR/$YOUTUBEUNBLOCK_GUI" || exit 1
  fi

  rm -rf "$AWG_DIR"
}

checkPackageAndInstall() {
  local name="$1"
  local isRequired="$2"

  if ! opkg list-installed | grep -q "$name"; then
    opkg install "$name"
    [ "$isRequired" = "1" ] && [ $? -ne 0 ] && exit 1
  fi
}

# ===== КОНЕЦ функций =====

# Основной код

echo "Update list packages..."
opkg update

checkPackageAndInstall "https-dns-proxy" "1"
checkPackageAndInstall "luci-app-https-dns-proxy" "0"
checkPackageAndInstall "luci-i18n-https-dns-proxy-ru" "0"

install_youtubeunblock_packages

opkg upgrade youtubeUnblock
opkg upgrade luci-app-youtubeUnblock

if [ ! -d "$DIR_BACKUP" ]; then
  echo "Backup files..."
  mkdir -p "$DIR_BACKUP"
  for file in $config_files; do
    cp -f "$DIR/$file" "$DIR_BACKUP/$file"
  done

  echo "Replace configs..."
  for file in $config_files; do
    [ "$file" != "dhcp" ] && wget -O "$DIR/$file" "$URL/config_files/$file"
  done
fi

echo "Configure dhcp..."

dnsmasq_section=$(find_dnsmasq_section)

uci set dhcp.${dnsmasq_section}.strictorder='1'
uci set dhcp.${dnsmasq_section}.filter_aaaa='1'
uci add_list dhcp.${dnsmasq_section}.server='127.0.0.1#5053'
uci add_list dhcp.${dnsmasq_section}.server='127.0.0.1#5054'
uci add_list dhcp.${dnsmasq_section}.server='127.0.0.1#5055'
uci add_list dhcp.${dnsmasq_section}.server='127.0.0.1#5056'

# Добавляем домены для этого сервера
uci add_list dhcp.${dnsmasq_section}.server='/*.chatgpt.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.oaistatic.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.oaiusercontent.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.openai.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.microsoft.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.windowsupdate.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.bing.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.supercell.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.seeurlpcl.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.supercellid.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.supercellgames.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.clashroyale.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.brawlstars.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.clash.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.clashofclans.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.x.ai/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.grok.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.github.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.forzamotorsport.net/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.forzaracingchampionship.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.forzarc.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.gamepass.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.orithegame.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.renovacionxboxlive.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.tellmewhygame.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox.co/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox.eu/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox.org/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox360.co/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox360.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox360.eu/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbox360.org/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxab.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxgamepass.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxgamestudios.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxlive.cn/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxlive.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxone.co/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxone.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxone.eu/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxplayanywhere.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxservices.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xboxstudios.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.xbx.lv/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.sentry.io/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.usercentrics.eu/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.recaptcha.net/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.gstatic.com/127.0.0.1#5056'
uci add_list dhcp.${dnsmasq_section}.server='/*.brawlstarsgame.com/127.0.0.1#5056'

# Дополнительные add_list можно сюда вставить
uci commit dhcp

echo "Add unblock"

# ChatGPT (веб, Android, iPhone, Windows, Mac)
checkAndAddDomainPermanentName "chatgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "openai.com" "94.131.119.85"
checkAndAddDomainPermanentName "webrtc.chatgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "ios.chat.openai.com" "94.131.119.85"
checkAndAddDomainPermanentName "searchgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "desktop.chatgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "app.chatgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "windows.chatgpt.com" "94.131.119.85"
checkAndAddDomainPermanentName "mac.chatgpt.com" "94.131.119.85"


# Google Gemini (веб)
checkAndAddDomainPermanentName "gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "web.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "api.gemini.google.com" "94.131.119.85"

# Google Gemini для Android
checkAndAddDomainPermanentName "android.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "play.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "app.gemini.google.com" "94.131.119.85"

# Google Gemini в Chrome
checkAndAddDomainPermanentName "chrome.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "chrome.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "gemini.chrome.google.com" "94.131.119.85"

# xAI Grok
checkAndAddDomainPermanentName "xai.com" "94.131.119.85"
checkAndAddDomainPermanentName "grok.com" "94.131.119.85"
checkAndAddDomainPermanentName "api.xai.com" "94.131.119.85"
checkAndAddDomainPermanentName "grok.ai" "94.131.119.85"
checkAndAddDomainPermanentName "chat.grok.ai" "94.131.119.85"

# Google AI Studio (Gemini 1.5 Pro)
checkAndAddDomainPermanentName "makersuite.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "studio.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "aistudio.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "gemini1p5pro.google.com" "94.131.119.85"

# Google Gemini 2.0 Flash (Experimental)
checkAndAddDomainPermanentName "flash.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "gemini2flash.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "experimental.gemini.google.com" "94.131.119.85"

# Google Gemini 2.5 Pro Experimental
checkAndAddDomainPermanentName "gemini2p5pro.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "experimental2p5.gemini.google.com" "94.131.119.85"
checkAndAddDomainPermanentName "pro.gemini.google.com" "94.131.119.85"

# GitHub Copilot
checkAndAddDomainPermanentName "copilot.github.com" "94.131.119.85"
checkAndAddDomainPermanentName "copilot-proxy.githubusercontent.com" "94.131.119.85"
checkAndAddDomainPermanentName "copilot.githubusercontent.com" "94.131.119.85"

# и т.д.

if ! grep -q "option name 'Block_UDP_443'" /etc/config/firewall; then
  echo "Add block QUIC..."
  uci add firewall rule
  uci set firewall.@rule[-1].name='Block_UDP_80'
  uci add_list firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].src='lan'
  uci set firewall.@rule[-1].dest='wan'
  uci set firewall.@rule[-1].dest_port='80'
  uci set firewall.@rule[-1].target='REJECT'

  uci add firewall rule
  uci set firewall.@rule[-1].name='Block_UDP_443'
  uci add_list firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].src='lan'
  uci set firewall.@rule[-1].dest='wan'
  uci set firewall.@rule[-1].dest_port='443'
  uci set firewall.@rule[-1].target='REJECT'

  uci commit firewall
  service firewall restart
fi

manage_package "podkop" "disable" "stop"
manage_package "ruantiblock" "disable" "stop"
manage_package "https-dns-proxy" "enable" "start"
manage_package "youtubeUnblock" "enable" "start"

echo "Restart services..."
service youtubeUnblock restart
service https-dns-proxy restart
service dnsmasq restart
service odhcpd restart

echo "\033[32;1mConfigured completed...\033[0m"
