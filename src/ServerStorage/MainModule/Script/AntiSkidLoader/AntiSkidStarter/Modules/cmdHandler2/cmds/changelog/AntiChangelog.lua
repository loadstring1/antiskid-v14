return [[13.10.2025 (DD:MM:YY) V14.4.16 small_changes, patch
- nfc chat now gets killed even if its already running
- removed lune from rokit.toml file
- bumped rojo version
- updated bans call to "userids" so the banlist doesn't make a warning anymore
- breakasset bypass now attempts to clone antiskid module if its possible
- fix: antiskid's remotes no longer trigger skid squasher 3 remote defense kicks (this also fixes antiskid triggering anti backdoor and whitelist systems such as invoking vecko remote blindly which triggers kick)
- fix: ParticleEmitter detection is now less strict and shouldn't delete every ParticleEmitter (nerfed completely so i will have to rewrite that detection later)]]