# Montagem Automatizada de Samba (Santa Maria)

Script robusto para montar compartilhamento Samba que funciona em boot, relação de energia e múltiplos Linux.

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

## 🚀 Instalação Rápida

### 1️⃣ Em cada máquina (como root)

```bash
cd ~/Code/utils/santamaria
sudo bash install.sh
```

O script vai:
- Verificar `cifs-utils` instalado
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

Pronto! Acesso em:
```bash
cd ~/santamaria
ls -la
```

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

## 📤 Distribuir para outras máquinas

Se tiver acesso SSH:

```bash
# Na máquina com os scripts
scp -r ~/Code/utils/santamaria user@outro-linux:~/Code/utils/santamaria

# Na outra máquina
cd ~/Code/utils/santamaria
sudo bash install.sh
bash user-setup.sh
```

Ou copie manualmente a pasta `santamaria` entre as máquinas.

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
