#!/bin/bash
# /*********************************************************************************
# * Projeto: Destruidor v2.0 - Revisão Técnica Aprimorada
# * Foco: Anti-forense, resistência a adversário sofisticado
# *********************************************************************************/

# === CONFIGURAÇÕES DE SEGURANÇA ===
# Desabilita histórico do bash imediatamente
unset HISTFILE
set +o history

# Mata processos de logging e auditoria ANTES de agir
systemctl stop rsyslog auditd systemd-journald 2>/dev/null
killall -9 rsyslogd auditd 2>/dev/null

echo "[!] PROTOCOLO DE DESTRUIÇÃO - VARIANTE ANTI-FORENSE"

# === 1. DESTRUIÇÃO DE CHAVES EM MEMÓRIA (RAM) ===
# Mata agentes que mantém chaves descriptografadas em RAM
echo "Eliminando agentes de chaves..."
killall -9 gpg-agent ssh-agent gnome-keyring-daemon 2>/dev/null
pkill -f "keyring" 2>/dev/null

# === 2. CRYPTO-SHREDDING LUKS (CABEÇALHOS) ===
# PRIORIDADE MÁXIMA - 2MB destrói terabytes
echo "Destruindo cabeçalhos LUKS..."
for luks_dev in $(dmsetup ls --target crypt | awk '{print $1}' | while read dm; do
    # Resolve dispositivo real (inclui LVM sobre LUKS)
    cryptsetup status "$dm" 2>/dev/null | grep device | awk '{print $2}'
done | sort -u); do
    # Sobrescreve cabeçalho + keyslots múltiplas vezes
    dd if=/dev/urandom of="$luks_dev" bs=512 count=4096 conv=notrunc 2>/dev/null &
    cryptsetup luksErase -q "$luks_dev" 2>/dev/null &
done

# Backup: varre todos os dispositivos blocos por assinatura LUKS
for dev in $(blkid -t TYPE=crypto_LUKS -o device); do
    cryptsetup luksErase -q "$dev" 2>/dev/null &
done

# === 3. DESTRUIÇÃO DE ARQUIVOS COM RESISTÊNCIA A JOURNALING ===
echo "Eliminando artefatos forenses..."
# Lista de alvos críticos (expanda conforme necessidade)
TARGETS=(
    # Chaves e identidades
    "/home/*/.ssh/id_*"
    "/home/*/.gnupg/private-keys*"
    "/home/*/.gnupg/secring*"
    "/root/.ssh/id_*"
    # Bancos de dados locais
    "/home/*/.mozilla/firefox/*/places.sqlite"
    "/home/*/.mozilla/firefox/*/cookies.sqlite"
    "/home/*/.config/chromium/Default/Cookies"
    "/home/*/.config/chromium/Default/History"
    # Configurações que revelam hábitos
    "/home/*/.bash_history"
    "/home/*/.zsh_history"
    "/root/.bash_history"
)

for target in "${TARGETS[@]}"; do
    # -n 3: 3 passadas (além de 2 anteriores fúteis)
    # -z: última passada com zeros para esconder que houve shred
    # -u: remove após sobrescrever
    # -f: força se permissões permitirem
    shred -n 3 -z -u -f $target 2>/dev/null
done

# === 4. CORRUPÇÃO DE PARTIÇÕES E BOOT ===
echo "Inutilizando tabelas de partição..."
for disk in $(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'); do
    # Destrói MBR (primeiros 512 bytes) + GPT primária (próximos 33 setores)
    dd if=/dev/urandom of="$disk" bs=512 count=20480 conv=notrunc 2>/dev/null &
    
    # Destrói GPT backup no final do disco
    size=$(blockdev --getsz "$disk" 2>/dev/null)
    if [ -n "$size" ]; then
        dd if=/dev/urandom of="$disk" bs=512 seek=$((size - 20480)) count=20480 conv=notrunc 2>/dev/null &
    fi
done

# === 5. ELIMINAÇÃO DE FIRMWARE EFI ===
# Remove variáveis EFI que podem conter informações
echo "Limpando variáveis EFI..."
if [ -d /sys/firmware/efi/efivars ]; then
    # Remove entradas de boot personalizadas
    for entry in /sys/firmware/efi/efivars/Boot0*; do
        chattr -i "$entry" 2>/dev/null
        echo "" > "$entry" 2>/dev/null
    done
fi

# === 6. ANTI-FORENSE DE MEMÓRIA ===
echo "Limpando memória RAM..."
# Múltiplas estratégias:
sync; echo 3 > /proc/sys/vm/drop_caches  # Limpa page cache
echo 1 > /proc/sys/vm/compact_memory     # Compacta memória antes de limpar
sdmem -f -ll 2>/dev/null || true         # Sobrescreve memória livre
# Alternativa se sdmem não existir:
if ! command -v sdmem &>/dev/null; then
    # Aloca e preenche memória (não tão eficaz, mas ajuda)
    dd if=/dev/zero of=/dev/null bs=1M count=$(free -m | awk '/Mem:/{print $4}') 2>/dev/null
fi

# === 7. DESLIGAMENTO FORÇADO IRRECUPERÁVEL ===
echo "Executando desligamento de emergência..."
sync  # Último sync (provavelmente inútil, mas tenta)
# Desabilita todos os watchdog timers
echo 'V' > /dev/watchdog 2>/dev/null
echo 'V' > /dev/watchdog0 2>/dev/null
# Poweroff imediato via kernel (ignora systemd completamente)
echo 1 > /proc/sys/kernel/sysrq
echo o > /proc/sysrq-trigger

# Fallback: se sysrq falhar, tenta via ACPI
sleep 1
poweroff -f -f 2>/dev/null

exit 0
