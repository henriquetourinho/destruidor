# Destruidor 💀🇧🇷

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Destruidor** é um script Bash de emergência para eliminação irreversível de dados sensíveis e inutilização completa do sistema. Projetado como ferramenta de **último recurso** para proteger pessoas antes de proteger máquinas — em risco de busca, apreensão ou invasão.

---

## 🎯 Casos de Uso Reais

### 📰 Jornalista em zona de conflito
Um correspondente investigativo em região hostil mantém fontes confidenciais, documentos vazados e comunicações criptografadas. Se soldados ou milícias invadirem o local, cada segundo conta. **Duas teclas e o sistema inteiro vira lixo ilegível.**

### ✊ Ativista sob regime repressivo
Defensora de direitos humanos monitora abusos estatais e armazena provas digitais, listas de contatos seguros e rotas de fuga. Durante uma batida policial sem mandado, **a destruição instantânea protege toda a rede de apoio.**

### 🔐 Fonte anônima com dados sensíveis
Whistleblower possui evidências contra corporação criminosa. Se o dispositivo for apreendido, a criptografia do disco impede acesso — mas com tempo e recursos, adversários tentam quebrar senhas. **Sem o cabeçalho LUKS, nem com supercomputador quântico os dados voltam.**

### 💻 Profissional de segurança em campo
Analista carrega chaves de acesso a infraestruturas críticas. Em caso de sequestro relâmpago ou roubo do laptop, **acionar o Destruidor garante que credenciais não sejam extraídas.**

### 🏠 Pessoa politicamente exposta em casa
Candidatura, liderança comunitária ou cargo público atrai ameaças. Invasão domiciliar para confiscar dispositivos: **um botão físico escondido aciona o protocolo de silêncio digital permanente.**

---

## 📦 Funcionamento Técnico Detalhado

O Destruidor opera em **5 camadas sequenciais de destruição**, priorizando velocidade e eficácia:

### Camada 1: 🔑 Crypto-Shredding de Cabeçalhos LUKS

**Ataque mais eficiente do script.**

Volumes criptografados com LUKS armazenam as chaves de descriptografia nos primeiros 2MB do disco (keyslots). O script:
1. Varre todos os dispositivos com assinatura `crypto_LUKS` usando `blkid`
2. Executa `cryptsetup luksErase` em cada volume detectado
3. Como redundância, sobrescreve os primeiros 4096 setores com `/dev/urandom` via `dd`

**Resultado:** Os dados continuam fisicamente no disco, mas são matematicamente irrecuperáveis. Destruir 2MB equivale a destruir 2TB. Tempo de execução: **milissegundos por volume**.

### Camada 2: 🔥 Sobrescrita de Arquivos Críticos

Antes que o sistema pare, elimina arquivos que revelam identidade:
- `~/.ssh/id_*` — Chaves privadas SSH
- `~/.gnupg/private-keys*` e `secring*` — Chaves GPG
- `*.db` em `/var/lib` — Bancos SQLite de aplicações (navegadores, mensageiros, tokens de sessão)
- `~/.bash_history` — Histórico de comandos

Cada arquivo recebe **3 passadas de dados aleatórios + 1 passada de zeros + remoção** via `shred -n 3 -z -u -f`.

### Camada 3: 💣 Corrupção de Tabelas de Partição

Torna o sistema não inicializável:
- Sobrescreve **primeiros 10MB** do disco: MBR, GPT primário, estágio 1 do GRUB
- Sobrescreve **últimos 10MB** do disco: backup do GPT
- Alcança tanto discos SATA (`/dev/sda`) quanto NVMe (`/dev/nvme0n1`)

**Resultado:** BIOS/UEFI não encontra sistema operacional. Recuperar tabela de partição exige análise forense avançada — e os dados ainda estão criptografados sem cabeçalho.

### Camada 4: 🧠 Limpeza de RAM (Anti-Cold Boot Attack)

O ataque Cold Boot consiste em resfriar módulos de RAM, removê-los fisicamente e ler dados que persistiram por segundos ou minutos após o desligamento.

O script contra-ataca:
1. Executa `sync && echo 3 > /proc/sys/vm/drop_caches` para liberar caches
2. Compacta memória com `echo 1 > /proc/sys/vm/compact_memory`
3. Sobrescreve memória livre com `sdmem -f -ll` (dados aleatórios, 1 passada)
4. Se `sdmem` não existir, faz fallback com `dd if=/dev/zero`

**Resultado:** Chaves de criptografia que estavam em RAM são sobrescritas. Janela de ataque Cold Boot reduzida de minutos para segundos.

### Camada 5: 📜 Desligamento Forçado via Kernel

Ignora completamente o userspace:
- Mata agentes de chaves (`gpg-agent`, `ssh-agent`, `gnome-keyring-daemon`)
- Para serviços de logging (`rsyslog`, `auditd`, `systemd-journald`)
- Desabilita histórico do bash (`unset HISTFILE`)
- Executa Magic SysRq `o` (poweroff imediato pelo kernel)
- Fallback com `poweroff -f -f` caso SysRq falhe

**Resultado:** Desligamento em fração de segundo. Sem tempo para processos de contenção, scripts forenses ou malware interceptarem a destruição.

### 🔒 Autoexclusão

A última linha antes do desligamento executa `rm -f "$0"`. O próprio script desaparece do disco após cumprir sua função. Zero vestígios da ferramenta.

---

## 🛡️ Arquitetura de Destruição: Por que funciona

A eficácia do Destruidor vem da **pirâmide de destruição em camadas**:

```
        ┌─────────────────┐
        │  Desligamento   │ ← Kernel, não userspace
        │    Forçado      │
       ─┼─────────────────┼─
      │  Limpeza de RAM   │ ← Anti-forense física
     ──┼─────────────────┼──
    │  Corrupção de GPT   │ ← Sistema não inicializa
   ───┼─────────────────┼───
  │  Shred de Chaves     │ ← Identidades apagadas
 ────┼─────────────────┼────
│  Crypto-Shred LUKS     │ ← Dados matematicamente mortos
 ─────────────────────────
```

**Princípio fundamental:** Melhor destruir cabeçalhos de criptografia em 2 milissegundos do que tentar sobrescrever discos inteiros por horas. SSDs modernos com wear leveling tornam sobrescrita completa inútil — mas sem a chave, os dados são lixo.

---

## ⚠️ AVISO CRÍTICO DE SEGURANÇA

Este script é **IRREVERSÍVEL** e causa **PERDA PERMANENTE DE DADOS**.

- ❌ **Não há desfazer.** Dados não poderão ser recuperados por ninguém, incluindo você.
- ⚡ **Uso exclusivo em emergências.** Projetado para situações onde destruição total é preferível à captura.
- 🧪 **Teste antes em VM.** Snapshots permitem entender o comportamento sem riscos.
- 👤 **Conhecimento técnico requerido.** Entenda LUKS, tabelas de partição e sistemas Linux.
- 🧠 **Backups estratégicos.** Mantenha cópias offline em local seguro, preparadas para reconstrução pós-evento.
- 💀 **SSDs com controladores proprietários podem reter dados.** Para ameaças estatais, considere destruição física complementar.

**Use este script apenas quando integridade física ou liberdade dependerem da eliminação dos dados.**

---

## ⚙️ Requisitos

- Sistema Linux (Debian, Ubuntu, Arch, Fedora e derivados)
- Acesso root/sudo
- Dependências:
  - `cryptsetup` — crypto-shredding LUKS
  - `secure-delete` — sdmem para RAM
  - `coreutils` — shred, dd

---

## 🚀 Como Usar

**1. Clone o repositório:**
```bash
git clone https://github.com/henriquetourinho/destruidor.git
cd destruidor
```

**2. Dê permissão de execução:**
```bash
chmod +x destruidor.sh
```

**3. Execute em emergência:**
```bash
sudo ./destruidor.sh
```

Sem confirmação, sem espera. O sistema desliga em segundos e nunca mais inicializa.

---

## 📍 Local Estratégico

- **`/tmp/destruidor.sh`** — Diretório temporário, não é alvo no início da destruição
- **Ramdisk (tmpfs)** — Carregue em RAM para zero vestígios em disco
- **Pendrive dedicado** — Removível fisicamente após acionamento

---

## 🔍 Gatilhos de Emergência

**Atalho de teclado (GNOME, i3, dwm):**
```bash
gnome-terminal -- sudo /tmp/destruidor.sh
```

**USBKill (remoção de dispositivo):**
```bash
sudo usbkill --sh-command "sudo /tmp/destruidor.sh"
```

**Botão físico GPIO (Raspberry Pi/servidores):**
```bash
echo "17" > /sys/class/gpio/export
# Script monitora pino e aciona destruidor
```

---

## 📜 Licença

MIT License. Veja o arquivo [LICENSE](LICENSE).

---

## 🌐 Contato

- **Autor:** Carlos Henrique Tourinho Santana
- **Website:** [henriquetourinho.com.br](https://henriquetourinho.com.br)
- **Instagram:** [@henrique_ntxa](https://instagram.com/henrique_ntxa)
- **Threads:** [@henrique_ntxa](https://threads.net/@henrique_ntxa)
- **GitHub:** [github.com/henriquetourinho](https://github.com/henriquetourinho)
- **Debian Wiki:** [wiki.debian.org/henriquetourinho](https://wiki.debian.org/henriquetourinho)

