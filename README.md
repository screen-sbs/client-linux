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
- Upload stdin (pipe) text
- Upload file (.txt, .mp4, .png)

#### Requirements
- curl
- xclip
- scrot
- xdg-utils
- bash
- jq
- Optional: ffmpeg (required for video recording)
- Optional: notify-send (libnotify)
- Optional: dialog

#### Installation
- For Debian/Ubuntu and RHEL/Fedora packages are available
  - Optional requirements not installed automatically:
    - ```apt install ffmpeg dialog libnotify-bin```
    - ```dnf install ffmpeg dialog libnotify```
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
- Upload pipe
  - ```echo "upload deez nuts" | screen-sbs text```
- Upload file (.png, .mp4, .txt)
  - ```screen-sbs file <filepath>```
- Interactive menu
  - ```screen-sbs``` 


#### Keybinds
Create keybinds in your DE for the commands above.
On xfce you can use ```xfce4-keyboard-settings```
