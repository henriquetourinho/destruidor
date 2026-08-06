#!/bin/bash

# /*********************************************************************************
# * Projeto:   Destruidor (Revisão de Segurança Forense)
# * Autor:     Carlos Henrique Tourinho Santana
# *
# * Descrição:
# * Ferramenta de eliminação emergencial focada na destruição de cabeçalhos
# * criptográficos (LUKS), limpeza de RAM e sobrescrita de arquivos vitais.
# *********************************************************************************/

echo "[!] INICIANDO PROTOCOLO DE DESTRUIÇÃO DE EMERGÊNCIA"

# 1. Eliminação Direcionada de Arquivos Críticos (shred)
# Alvo: Chaves SSH, GPG, tokens de sessão e bancos de dados SQLite locais.
# O 'shred -uz -n 2' sobrescreve o arquivo 2 vezes com dados aleatórios, depois com zeros, e o remove.
echo "Sobrescrevendo chaves criptográficas e identidades..."
find /home /root -name ".ssh" -type d -exec shred -uz -n 2 {}/* 2>/dev/null \;
find /home /root -name ".gnupg" -type d -exec shred -uz -n 2 {}/* 2>/dev/null \;
find /var/lib -name "*.db" -type f -exec shred -uz -n 2 {} 2>/dev/null \;

# 2. Destruição Criptográfica (Crypto-Shredding) - O PASSO MAIS IMPORTANTE
# Localiza todas as partições LUKS (criptografadas) e destrói irreversivelmente os cabeçalhos (keyslots).
# Isso transforma todo o disco em dados ilegíveis quase instantaneamente.
echo "Inutilizando volumes criptografados..."
for luks_dev in $(blkid | grep crypto_LUKS | awk -F ':' '{print $1}'); do
    # O comando luksErase remove todas as chaves de descriptografia.
    # Sem backup do cabeçalho, os dados são perdidos para sempre.
    cryptsetup luksErase -q "$luks_dev" 2>/dev/null &
done

# 3. Corrupção da Tabela de Partições (MBR/GPT) e Bootloader
# Torna o sistema não inicializável sobrescrevendo os primeiros e últimos megabytes dos discos físicos.
echo "Destruindo tabelas de partição e boot..."
for disk in $(lsblk -ndpo NAME,TYPE | awk '$2=="disk" {print $1}'); do
    # Sobrescreve os primeiros 10MB (MBR, GPT primária, partes do bootloader)
    dd if=/dev/urandom of="$disk" bs=1M count=10 status=none conv=notrunc 2>/dev/null &
    
    # Busca o tamanho do disco e sobrescreve o final (onde fica o backup do GPT)
    size=$(blockdev --getsz "$disk" 2>/dev/null)
    if [ -n "$size" ]; then
        seek_point=$((size - 20480)) # Volta 10MB do final
        dd if=/dev/urandom of="$disk" bs=512 seek="$seek_point" count=20480 status=none 2>/dev/null &
    fi
done

# Aguarda 2 segundos para garantir que os processos em background (dd e cryptsetup) enviem os comandos ao disco.
sleep 2

# 4. Prevenção contra Cold Boot Attack (Wipe RAM)
# Tenta sobrescrever a memória livre para eliminar resquícios de chaves de criptografia e processos.
# Requer o pacote 'secure-delete' (comando sdmem). Se não existir, ignora.
echo "Limpando memória RAM residual..."
sdmem -f -ll 2>/dev/null

# 5. Desligamento Súbito pelo Kernel (Magic SysRq)
# Ignora o systemd, mata todos os processos instantaneamente sem salvar estado e corta a energia.
echo "Executando parada forçada pelo Kernel..."
echo 1 > /proc/sys/kernel/sysrq
echo o > /proc/sysrq-trigger # 'o' = poweroff imediato (use 'b' para reboot instantâneo)

exit 0
