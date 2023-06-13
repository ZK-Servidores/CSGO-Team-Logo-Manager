# CSGO Team Logo Manager
Add teams logo on the server scoreboard.
- **SVG Logos** have to be added into **`materials/panorama/images/tournaments/teams`** directory;
- **PNG Logos** may be added into any of **`materials/panorama/images/tournaments/teams`** or **`resource/flash/econ/tournaments/teams`** directories;

## Cvars
- **`teamlogo_randomlogos "1"`** - Enables selection of random team logos on map load;
- **`teamlogo_defaultlogos "1"`** - Adds the Valve default logos to the team logo list if **`teamlogo_randomlogo`** is set to 1;
- **`teamlogo_teamnames "1"`** - Team names will be loaded from **.cfg** files with the same name and location as the logo file;
- **`teamlogo_halftime_teamswitch "0"`** - Plugin will switch team logos and names at half time;
- **`teamlogo_autologos "0"`** - Plugin will auto-select team logos based on player clan tags;

To change cvars values just add to **`server.cfg`** and make the changes you would like.

## Credits 
- [Neuro Toxin](https://github.com/ntoxin66) for his [original plugin](https://github.com/ntoxin66/CSGO-Team-Logo-Manager);
- [uspeek](https://github.com/uspeek) updated version of [Team Logo Manager](https://github.com/uspeek/CSGO-Team-Logo-Manager) with Panorama UI directory and default logos;
- [crashzk](https://github.com/crashzk) updated Teams & Logos;
