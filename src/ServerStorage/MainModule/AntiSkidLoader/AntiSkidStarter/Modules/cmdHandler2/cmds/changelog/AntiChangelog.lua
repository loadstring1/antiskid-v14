return [[10.08.2026 (DD:MM:YYYY) V14.5.24 patch
- doesn't call require in bsre anymore (i refuse to share the bypass so thats the only thing i can do)
- gexe and exe commands are both disabled only in bsre
- no longer checks for bsre bans in bsre places because bsre server script already does that by default
- fixed shiftlock locking your character orientation to your camera orientation after resetserver
- added some missing properties to SetProperties module that resets properties during resetserver
- touchgui wont be destroyed anymore (false positive fix in generic screen blocker detection)
- fixed network bandwith waste due to textchatservice loops]]