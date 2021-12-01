# screen.sbs
## Linux CLI Client

#### Requirements
- curl
- xclip
- scrot

#### Installation
##### Option 1: Install .deb
- ```apt install ./screen-sbs_version-rev_all.deb```
- Edit config file ```~/.config/screen.conf```
- Client will be available as ```screen```

##### Option 2: Manual
- Install requirements
  - ```apt install curl xclip scrot``` for debian (based)
- Clone/download to /opt/screen-sbs
  - ```git clone git@github.com:screen-sbs/client-linux.git /opt/screen-sbs```
- make screen.sh executable
  - ```chmod +x /opt/screen-sbs/screen.sh```
- make screen.sh globally available
  - ```ln -s /opt/screen-sbs/screen.sh /usr/local/bin/screen```
- Edit config file ```~/.config/screen.conf```
- Client will be available as ```screen```


#### Usage
- Take fullscreen screenshot & upload
  - ```screen``` or
  - ```screen full``` or
  - ```screen fullscreen```
- Take selection screenshot & upload
  - ```screen area```
- Upload clipboard
  - ```screen text```


#### Keybinds
Create keybinds in your DE for the commands above.
On xfce you can use ```xfce4-keyboard-settings```