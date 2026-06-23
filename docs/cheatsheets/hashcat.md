# hashcat Cheatsheet

## Modi

| Hash       | -m    | Beispiel                                                       |
|------------|-------|----------------------------------------------------------------|
| MD5        | 0     | `5f4dcc3b5aa765d61d8327deb882cf99`                              |
| SHA1       | 100   |                                                                 |
| SHA256     | 1400  |                                                                 |
| NTLM       | 1000  | `aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0` |
| NTLMv2     | 5600  | Responder-Capture                                              |
| bcrypt     | 3200  | `$2a$05$...`                                                    |
| WPA2 EAPOL | 22000 | hcxpcapngtool output                                            |
| Kerberos AS-REP | 13100 | impacket GetUserSPNs                                       |
| ZIP        | 13600 | zip2john                                                        |

## Attack-Modi

```bash
# Wordlist
hashcat -m 0 -a 0 hashes.txt rockyou.txt

# Wordlist + Rules
hashcat -m 0 -a 0 hashes.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule

# Mask
hashcat -m 0 -a 3 hashes.txt ?l?l?l?l?d?d?d?d

# Combination
hashcat -m 0 -a 1 hashes.txt list1.txt list2.txt

# Hybrid wordlist + mask
hashcat -m 0 -a 6 hashes.txt rockyou.txt ?d?d?d?d
```

## Performance

```bash
hashcat -I                          # show devices
hashcat -b -m 22000                 # benchmark mode
hashcat -m 22000 -w 4 hashes.txt    # max workload (Achtung Throttling)
```

## Restart / Resume

```bash
hashcat ... --session=run1          # named session
hashcat --session=run1 --restore    # resume
```

## Show

```bash
hashcat -m 22000 hashes.txt --show
hashcat -m 22000 hashes.txt --left  # noch nicht gecrackte
```

## Toolkit-Wrapper

Alle in `scripts/hashcrack/crack-*.sh` setzen die richtigen Modi und Outputs
automatisch. Nur die Hashdatei angeben.
