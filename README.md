# screen.sbs
## Linux CLI Client

#### Requirements
- curl
- xclip
- scrot

#### Installation
##### Option 1: Install package
- Debian/Ubuntu: ```apt install ./screen-sbs*.deb```
- Fedora: ```dnf install ./screen-sbs*.rpm```
- Edit config file ```~/.config/screen-sbs.conf```
- Client will be available as ```screen-sbs```

##### Option 2: Manual
- Install requirements
  - Debian/Ubuntu: ```apt install curl xclip scrot```
  - Fedora: ```dnf install curl xclip scrot```
- Download ```screen-sbs.sh``` from [latest release](https://github.com/screen-sbs/client-linux/releases/latest)
  - Preferrably place it in ```/opt/screen-sbs/``` or similiar
- make ```screen-sbs.sh``` executable
  - ```chmod +x screen-sbs.sh```
- make ```screen-sbs.sh``` globally available
  - ```ln -s screen-sbs.sh /usr/local/bin/screen-sbs```
- Edit config file ```~/.config/screen-sbs.conf```
- Client will be available as ```screen-sbs```


#### Usage
- Take fullscreen screenshot & upload
  - ```screen-sbs``` or
  - ```screen-sbs full``` or
  - ```screen-sbs fullscreen```
- Take selection screenshot & upload
  - ```screen-sbs area```
- Upload clipboard
  - ```screen-sbs text```


#### Keybinds
Create keybinds in your DE for the commands above.
On xfce you can use ```xfce4-keyboard-settings```
