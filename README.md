# 💀🇧🇷 Destruidor

O **Destruidor** é um script Bash extremamente perigoso e irreversível, projetado para destruir completamente um sistema Linux e apagar dados em dispositivos conectados, sem intervenção ou confirmação. É destinado a usuários que necessitam de ação imediata para segurança e entendem exatamente as consequências de sua execução.

---

### ⚠️ AVISO CRÍTICO DE SEGURANÇA ⚠️

* **ESTE SCRIPT É LETAL E IRREVERSÍVEL.**
* **EXECUTÁ-LO CAUSA PERDA TOTAL DE DADOS E DANOS PERMANENTES AO SISTEMA.**
* **APENAS USUÁRIOS QUE SABEM EXATAMENTE O QUE ESTÃO FAZENDO DEVEM EXECUTÁ-LO.**
* **USE EM AMBIENTES CONTROLADOS, COMO MÁQUINAS VIRTUAIS, PARA MINIMIZAR RISCOS.**

---

### 📦 O que o Destruidor faz

O Destruidor executa uma sequência de ações destrutivas automatizadas, projetadas para maximizar a eliminação de dados e tornar o sistema inoperante:

* **Preparação do Ambiente:**
    * Identifica e remonta todas as partições detectadas em modo de escrita (`rw`) usando `mount` para garantir acesso total aos arquivos.
    * Desmonta partições temporariamente (`umount`) para evitar bloqueios do sistema durante a destruição.
* **Desativação de Proteções:**
    * Remove atributos de imutabilidade (`chattr -i`) em arquivos críticos, como configurações do sistema ou logs, que poderiam impedir exclusão.
    * Força permissões de escrita em todos os arquivos e diretórios usando `chmod -R`.
* **Destruição Abrangente de Dados:**
    * **Sobrescrita de Dispositivos**: Detecta dispositivos de bloco (HDs, SSDs, pendrives) via `/dev` (ex.: `/dev/sda`, `/dev/nvme0n1`) e tenta sobrescrever seus dados brutos com `/dev/zero` ou `/dev/urandom` usando `dd`. **Nota**: Este comando está comentado no script por segurança, mas pode ser ativado manualmente.
    * **Remoção de Diretórios Críticos**: Apaga diretórios essenciais do sistema Linux em uma ordem estratégica para inutilizar o sistema rapidamente:
        * `/tmp` e `/var/log`: Remove arquivos temporários e logs para eliminar rastros de atividades.
        * `/home` e `/root`: Apaga dados de usuários, incluindo documentos, configurações e chaves.
        * `/usr`, `/bin`, `/sbin`, `/lib`: Exclui programas e bibliotecas essenciais, tornando o sistema inoperante.
        * `/etc`: Remove configurações do sistema, como redes, usuários e serviços.
        * `/boot`: Apaga o kernel e o bootloader (ex.: GRUB), impedindo a inicialização.
        * `/`: Tenta apagar o diretório raiz como ação final, eliminando qualquer resquício.
    * Usa `rm -rf --no-preserve-root` para exclusão agressiva, ignorando proteções do sistema.
    * **Sobrescrita de Espaço Livre**: Preenche o espaço livre em disco com dados aleatórios usando ferramentas como `shred` ou `dd` para dificultar recuperação de dados.
    * **Desativação de Serviços**: Para processos ativos (ex.: `systemd`, `cron`) usando `systemctl` ou `killall` para evitar interferências durante a destruição.
    * **Reinicialização Forçada**: Executa `reboot -f` ou `echo b > /proc/sysrq-trigger` para forçar a reinicialização imediata, consolidando a destruição, caso o sistema ainda esteja funcional.

---

### 🚨 Por que ele precisa ser usado e motivos em situações de risco

O Destruidor é uma ferramenta para usuários que precisam de ação imediata em situações críticas onde a segurança de dados é prioridade máxima. Ele é projetado para cenários onde informações sensíveis devem ser eliminadas rapidamente para evitar acesso não autorizado. Motivos para uso incluem:

* **Jornalistas e Ativistas**: Em contextos de ameaça (ex.: regimes repressivos, buscas policiais), o script elimina evidências digitais, como documentos, contatos ou comunicações, protegendo fontes e investigações.
* **Profissionais de Segurança**: Permite destruir dados em dispositivos comprometidos, como laptops ou servidores, antes que sejam confiscados ou invadidos.
* **Emergências de Privacidade**: Em situações de risco iminente (ex.: invasão física ou vigilância), garante que dados sensíveis (chaves criptográficas, arquivos pessoais) sejam apagados permanentemente.
* **Cenários de Alto Risco**: Ideal para quem opera em ambientes hostis (ex.: zonas de conflito, repressão política), onde a captura de um dispositivo pode comprometer pessoas ou operações.

**Nota**: O uso requer planejamento prévio, como backups seguros de dados críticos em locais separados. Execute apenas quando a destruição total for a única opção para proteger informações.

---

### ⚙️ Requisitos para Execução

* Sistema Linux com terminal Bash.
* Acesso `root` (superusuário), necessário para comandos de baixo nível (`dd`, `chattr`, `rm`).
* Máquina virtual (ex: VirtualBox, VMware) ou dispositivo físico dedicado, dependendo da intenção do usuário.
* Conhecimento técnico avançado para entender e gerenciar as consequências da execução.

---

### 📍 Onde Executar e Melhor Local para o Script

Pode ser executado em qualquer lugar por quem sabe o que está fazendo. Para garantir que o script funcione de forma completa sem ser excluído prematuramente, é recomendável que ele esteja em um local que não seja dos primeiros a ser alvo de exclusão ou que seja um diretório temporário, mas que não seja limpado no início.

**Melhor Local Recomendado:**

* **`/tmp`**: Embora seja um diretório temporário, arquivos lá geralmente não são removidos imediatamente ao início da execução de scripts destrutivos que visam o sistema de arquivos principal. Colocar o script diretamente em `/tmp` (ex: `/tmp/destruidor.sh`) e executá-lo de lá é uma boa prática.
* **Diretório de montagem de um ramdisk (temporário na RAM)**: Para o cenário mais crítico, você poderia criar um ramdisk, copiar o script para ele e executar. Isso garante que o script esteja na RAM e não em um disco que será apagado, mas é uma configuração mais avançada.

**Onde Executar:**

* Máquinas virtuais isoladas (ex: VirtualBox, VMware) com sistemas Linux (Ubuntu, Debian, AlmaLinux) para testes controlados.
* Dispositivos físicos que necessitem de ação para segurança, como laptops ou servidores em cenários de risco.
* Configure snapshots em VMs ou backups externos, se necessário, para restaurar sistemas após testes.

---

### 🛠️ Como Utilizar

1.  **Prepare o Ambiente:**
    * Transfira o arquivo `destruidor.sh` para o dispositivo ou máquina virtual. **Recomendação:** Salve-o em `/tmp/destruidor.sh` ou outro local similar.
    * Verifique se o sistema está isolado (sem conexão com redes externas, se possível).
2.  **Dê Permissão de Execução:**
    ```bash
    chmod +x /tmp/destruidor.sh # Ou o caminho onde você salvou
    ```
3.  **Execute como Root:**
    ```bash
    sudo /tmp/destruidor.sh # Ou o caminho onde você salvou
    ```
4.  **Aviso Inicial**: O script exibe um aviso de 5 segundos, permitindo cancelamento com `Ctrl+C`. Após isso, a destruição começa sem pausas.
5.  **Monitoramento (Opcional)**:
    * Use `tail -f /var/log/syslog` ou `dmesg` em outra sessão (se possível) para acompanhar ações em tempo real.
    * A execução pode levar de segundos a minutos, dependendo do tamanho dos discos e do hardware.
6.  **Pós-Execução**:
    * O sistema ficará inoperante, sem possibilidade de inicialização.
    * Descarte o dispositivo ou restaure o snapshot da VM, se aplicável.

**Dica**: Teste primeiro em uma VM para entender o comportamento antes de usar em cenários reais.

---

### ♻️ Como se Autoexcluir (Garantindo que o Processo Termine Primeiro)

Para evitar rastros, o script pode se autoexcluir **APÓS** a tentativa de conclusão das ações de destruição. O comando de autoexclusão deve ser uma das últimas linhas do script, **antes da reinicialização forçada (se o sistema ainda permitir)**, garantindo que ele não se remova antes de completar suas tarefas destrutivas.

Adicione esta linha ao **final do seu script `destruidor.sh`**, pouco antes do `reboot -f &` (se presente) ou da última mensagem de saída:

bash
rm -f "$0" # Remove o próprio script após a execução das ações destrutivas.

---

## 📜 Licença

Este projeto está licenciado sob a **MIT License**. Veja o arquivo `LICENSE` no repositório para mais detalhes.