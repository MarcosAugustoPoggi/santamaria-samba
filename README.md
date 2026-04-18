# Montagem Automatizada de Samba (Santa Maria)

Script simples para montar compartilhamento Samba como disco de rede. Funciona em **qualquer Linux** (Ubuntu, Debian, Mint, CentOS, etc), em boot automático e após relação de energia.

## ✨ Características

- ✅ **Montagem automática no boot** — não precisa de intervenção
- ✅ **Tolerância a falha de rede** — aguarda servidor ficar online (até 150s)
- ✅ **Funciona após relação de energia** — systemd trata tudo automaticamente
- ✅ **Idempotente** — pode rodar quantas vezes quiser sem problemas
- ✅ **Logs centralizados** — journalctl integrado
- ✅ **Fácil de compartilhar** — copia em qualquer Linux, roda `install.sh`

## 📦 Arquivos

| Arquivo | Propósito |
|---------|-----------|
| `samba-mount.sh` | Script principal de montagem/desmontagem |
| `samba-mount.service` | Unit systemd (inicializa no boot) |
| `samba-mount-retry.service` | Unit systemd (tenta remontagem se falhar) |
| `install.sh` | Instalador (roda uma vez como root) |
| `user-setup.sh` | Setup por usuário (cria symlink em `~/santamaria`) |

## 📋 Pré-requisitos

**Obrigatório:** instalar `cifs-utils` — driver CIFS para Linux montar compartilhamentos Samba

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install cifs-utils

# RHEL/CentOS
sudo yum install cifs-utils

# Fedora
sudo dnf install cifs-utils
```

**Quer saber mais sobre cifs-utils?** Veja `PREREQUISITES.md`

Depois de instalar, continue com a instalação abaixo.

## 🚀 Instalação Rápida

### 1️⃣ Em cada máquina (como root)

```bash
cd ~/Code/utils/santamaria
sudo bash install.sh
```

O script vai:
- Verificar `cifs-utils` instalado ✅
- Copiar script para `/usr/local/bin/samba-mount.sh`
- Instalar serviços systemd
- Criar `/mnt/santamaria`
- Habilitar para iniciar no boot
- Tentar montar imediatamente

### 2️⃣ Cada usuário executa (primeira vez apenas)

```bash
bash ~/Code/utils/santamaria/user-setup.sh
```

Isso cria um symlink: `~/santamaria` → `/mnt/santamaria`

### 3️⃣ Acessar pelo terminal

```bash
cd ~/santamaria
ls -la
cp ~/santamaria/arquivo.txt ~
vim ~/santamaria/documento.md
```

Pronto! Funciona como qualquer pasta normal.

## 🔄 Como funciona no boot + relação de energia

```
┌─────────────────────────────────────────────────────┐
│          Sistema iniciando / relação de poder       │
└──────────────────┬──────────────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │ systemd inicia     │
         │ samba-mount.service│
         └─────────┬──────────┘
                   │
         ┌─────────▼───────────────────┐
         │ samba-mount.sh monta        │
         │ • Aguarda rede (até 150s)   │
         │ • Tenta conectar ao servidor│
         └─────────┬───────────────────┘
                   │
          ┌────────▼────────┐
          │   Montado OK?   │
          └────┬─────────┬──┘
         Sim  │         │  Não
             ✓          │
        Continua       └──→ OnFailure=samba-mount-retry.service
                           (tenta novamente em 10s)
```

## 🛠️ Comandos Úteis

### Ver status
```bash
systemctl status samba-mount
systemctl is-active samba-mount
```

### Ver logs
```bash
journalctl -u samba-mount -n 20              # Últimas 20 linhas
journalctl -u samba-mount -f                 # Em tempo real
journalctl -u samba-mount --since "10 min ago" # Últimos 10 min
```

### Verificar montagem
```bash
/usr/local/bin/samba-mount.sh status
mount | grep santamaria
df -h /mnt/santamaria
```

### Remontagem manual (se precisar)
```bash
sudo /usr/local/bin/samba-mount.sh remount
```

### Desmontar
```bash
sudo /usr/local/bin/samba-mount.sh unmount
```

## 🔐 Credenciais

As credenciais são armazenadas em `/root/.smbcredentials`:
```
username=santamaria
password=santamaria
```

Arquivo é protegido: `chmod 600` (apenas root pode ler)

## 📤 Usar em outra máquina (ex: Mint)

Script funciona **igual em qualquer Linux**. Basta copiar e rodar:

```bash
# Na máquina com os scripts
~/Code/utils/santamaria/sync-to-host.sh user@mint-machine

# Ou manualmente:
scp -r ~/Code/utils/santamaria user@mint-machine:~/Code/utils/santamaria
```

Na outra máquina (Mint ou qualquer Linux):
```bash
cd ~/Code/utils/santamaria
sudo apt-get install cifs-utils  # Se não tiver
sudo bash install.sh
bash user-setup.sh
```

Pronto! Funciona igual lá também. Sem diferenças.

## 🐛 Troubleshooting

### "Servidor não alcançável após 30 tentativas"
- Verifique se o servidor Samba está online: `ping 192.168.15.212`
- Verifique firewall/rede entre as máquinas
- Verifique logs com: `journalctl -u samba-mount -n 50`

### "Falha de permissão ao montar"
- Verifique credenciais em `/root/.smbcredentials`
- Verifique se user `santamaria` existe no servidor Samba
- Teste manualmente:
  ```bash
  mount -t cifs //192.168.15.212/santamaria /mnt/test \
    -o credentials=/root/.smbcredentials
  ```

### Montagem aparece, mas não consegue acessar
- Verifique permissões:
  ```bash
  ls -la /mnt/santamaria
  ```
- Se precisar ajustar permissões, edite `samba-mount.sh` e procure por `file_mode=0755,dir_mode=0755`

### Desmantelamento durante desligamento não funciona
- Isso é normal em algumas situações. O systemd tenta desmontar com `-l` (lazy umount)
- Verifique status com `mount | grep santamaria` após boot

## 📝 Customizações

Se precisar mudar algo, edite `samba-mount.sh`:

```bash
SAMBA_SERVER="192.168.15.212"  # IP do servidor
SAMBA_SHARE="santamaria"       # Nome do compartilhamento
SAMBA_USER="santamaria"        # Usuário
SAMBA_PASS="santamaria"        # Senha
MOUNT_POINT="/mnt/santamaria"  # Onde montar
```

Depois reinstale:
```bash
sudo bash install.sh
```

## ✅ Checklist pós-instalação

- [ ] `sudo bash install.sh` executado com sucesso
- [ ] `bash ~/Code/utils/santamaria/user-setup.sh` executado
- [ ] `cd ~/santamaria && ls -la` mostra arquivos do servidor
- [ ] `systemctl status samba-mount` mostra "active (exited)"
- [ ] Após reboot: compartilhamento ainda está acessível

## 📚 Referência

- [systemd.service(5)](https://man7.org/linux/man-pages/man5/systemd.service.5.html)
- [mount.cifs(8)](https://man7.org/linux/man-pages/man8/mount.cifs.8.html)
- [systemctl(1)](https://man7.org/linux/man-pages/man1/systemctl.1.html)
