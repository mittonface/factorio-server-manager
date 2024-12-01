import factorio_rcon

client = factorio_rcon.RCONClient("factorio.brent.click", 27015, "aimae6Iibej1ooV")
response = client.send_command("/p o")