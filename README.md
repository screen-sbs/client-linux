# screen.sbs
## Linux CLI Client
### Self-hosted Screenshot, Video & Code/Text Sharing
Requires access to a (self-)hosted instance of the [screen.sbs server](https://github.com/screen-sbs/server)
<br>

### [Preview Video](https://screen.sbs/vcogk49hp5j)

### Features
- Capture fullscreen screenshot & upload
  - area can be limited to only capture one screen
- Capture area screenshot from selection & upload
  - (Drag for area, click for window)
- Capture video (predefined area/fullscreen)
- Upload clipboard (Ctrl+C clipboard)

#### Requirements
- curl
- xclip
- scrot
- ffmpeg

#### Installation
- For Debian/Ubuntu and RHEL/Fedora packages are available
- For everything else use the .sh bash script
  - Make sure you meet the requirements listed above
  - Symlink to /usr/local/bin/screen-sbs or similiar
- Always download from the [releases page](https://github.com/screen-sbs/client-linux/releases/latest)

#### Usage
- Setup config file
  - ```screen-sbs config```
- Take fullscreen screenshot & upload
  - ```screen-sbs full``` or
  - ```screen-sbs fullscreen```
- Take selection screenshot & upload
  - ```screen-sbs area```
- Record video (fullscreen/area defined in config)
  - ```screen-sbs video```
- Upload clipboard
  - ```screen-sbs text```
- ~~Interactive menu~~ (not implemented yet)
  - ```screen-sbs``` 


#### Keybinds
Create keybinds in your DE for the commands above.
On xfce you can use ```xfce4-keyboard-settings```
