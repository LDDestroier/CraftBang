# Welcome to CraftBang!

CraftBang is a multitasking desktop environment for ComputerCraft's CraftOS, a program aiming for productivity and convenience. The name and color scheme are both based off of the wonderful CrunchBang linux, and CraftBang is compatible with both advanced and normal computers.

Any files placed in the /autorun directory will be run by craftbang automatically, each as its own task.

Want to contribute? Fork this project and make a pull request with whatever bit of code you'd like to be a part of CraftBang. All credits will be given where needed.


## Installation

Simply download the "updater" file from this page, or from pastebin:

    pastebin get reBqWcFr updater

and run it on your computer. It will download the installer, which will download craftbang files and prompt you for running on startup. You need to have HTTP enabled.


## The Panel

Create a new task by right-clicking the desktop and choosing "Run..", or by double-clicking a desktop shortcut. All tasks are sized to fit the panel.

Left-click to toggle a task.  
Left-click and drag to move a task around on the panel.  
Right-click or middle-click to close a task on the panel.

When a task ends, its name will have an [X] in front of it, and you are free to close it.


## The Desktop

Right-click the desktop to bring up the main menu. From there, you can run a program, create a new desktop shortcut, restart or shut down the computer, or exit CraftBang and return to the normal CraftOS shell.

Double-click an icon to run it.  
Left-click and drag to move it around.  
Right-click the icon to rename or remove it.


## Keyboard Shortcuts (for use on normal computers)

### Desktop

Ctrl - bring up the main menu. Use the arrow keys to navigate through menus.  
Arrow Keys - select a desktop shortcut.  
Enter - run the selected shortcut.  
WASD - move the shortcut around.  
Shift - open the dialog to rename or remove a shortcut.


### The Panel and Alt Mode

Pressing alt will bring you into "alt mode". While the alt mode notification is open, any keyboard commands will be sent to the panel. Pressing alt while under alt mode will send the alt key to the current task.

While under alt mode:

Up or Down arrow key - toggle a task.  
Left and Right - switch between tasks.  
A and D - move the selected task.  
X - close the current task.

### Misc

Ctrl - close an open menu.  
Ctrl - close a text dialog.


## Colors Reference
background: The desktop background color.

panel: The background for an inactive task, and for the panel when there are no active tasks.  
panelText: The text color for an inactive task.  
activePanel: The background for the active task.  
activePanelText: The text color for the active task.

icon: The color of desktop shortcuts, and for the information at the top of the desktop.

dialog: The background color of dialogs, such as the menu, the text input dialog, and notices.  
dialogBorder: The border color for dialogs (menus do not have a dialog).  
dialogText: The text color for dialogs.  
dialogButton: The background color for buttons on dialogs.  
dialogButtonText: The text color for buttons on dialogs.
