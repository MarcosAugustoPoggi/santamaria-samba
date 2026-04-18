# Pré-requisitos — Santa Maria Samba Mount

## 📦 cifs-utils (OBRIGATÓRIO)

### O que é?

**CIFS** = *Common Internet File System* — protocolo de rede que Samba usa para compartilhar pastas.

**cifs-utils** é um pacote Linux que fornece:
- `mount.cifs` — comando para montar compartilhamentos Samba/SMB
- Driver kernel `cifs.ko` — permite comunicação com servidores Samba
- Utilitários de suporte

### Por que é necessário?

Sem `cifs-utils`, Linux **não consegue montar** compartilhamentos Samba. É como um carro sem pneus.

O script tenta montar assim:
```bash
mount -t cifs //192.168.15.212/santamaria /mnt/santamaria
```

Se `cifs-utils` não estiver instalado, esse comando falha com:
```
mount.cifs: command not found
```

### Como instalar

Escolha seu sistema operacional:

#### 🐧 Debian / Ubuntu / Linux Mint

```bash
sudo apt-get update
sudo apt-get install cifs-utils
```

#### 🎩 RHEL / CentOS / Rocky Linux / AlmaLinux

```bash
sudo yum install cifs-utils
```

#### 🔥 Fedora

```bash
sudo dnf install cifs-utils
```

#### 📦 Arch / Manjaro

```bash
sudo pacman -S cifs-utils
```

### Verificar instalação

```bash
# Se instalado corretamente, mostra a versão
mount.cifs --version

# Ou confirma que existe
which mount.cifs
```

Saída esperada:
```
mount.cifs version: 6.15
```

---

## 🔗 Outras dependências (geralmente já instaladas)

- `mount` — utilitário padrão do Linux (sempre pré-instalado)
- `ping` — verificar conectividade (geralmente pré-instalado)
- `systemd` — gerenciador de serviços (padrão em distros modernas)

---

## ✅ Checklist antes de instalar

```bash
# 1. Verificar se cifs-utils está instalado
dpkg -l | grep cifs-utils    # Debian/Ubuntu
rpm -q cifs-utils             # RHEL/CentOS

# 2. Se não tiver, instalar (veja acima)

# 3. Confirmar instalação
mount.cifs --version

# 4. Agora pode rodar o install.sh
sudo bash install.sh
```

---

## 🆘 Troubleshooting

### "Comando mount.cifs não encontrado"
→ `cifs-utils` não está instalado. Execute os comandos de instalação acima.

### "Falha ao montar: Permission denied"
→ `cifs-utils` instalado, mas problema de credenciais/permissões. Verifique `/root/.smbcredentials`

### "mount: unknown filesystem type 'cifs'"
→ Kernel não tem módulo CIFS. Instale `cifs-utils` novamente (inclui driver)

---

## 📚 Mais informações

- [man mount.cifs](https://man7.org/linux/man-pages/man8/mount.cifs.8.html)
- [Samba Wiki — Linux CIFS Client](https://wiki.samba.org/index.php/LinuxCIFSClientSide)
