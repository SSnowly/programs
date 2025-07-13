# SnowyOS

A beautiful operating system for ComputerCraft: Tweaked with pixel art boot screen and modern features.

## Features

- 🎨 **Pixel Art Boot Screen** - Beautiful snowgolem pixel art on advanced monitors
- 🖥️ **Multi-Screen Support** - Choose which monitor to use during installation
- 🔐 **User Authentication** - Secure login system with username/password
- 📁 **File Management** - Organized system structure
- 🎯 **Easy Installation** - One-command web installer

## Quick Installation

Run this single command in any ComputerCraft computer:

```bash
wget run https://raw.githubusercontent.com/snowylol/snowyos/main/installer.lua
```

That's it! The installer will:
1. Download all SnowyOS files
2. Restart the computer
3. Launch the installation wizard
4. Set up your user account
5. Configure your display preferences

## Requirements

- ComputerCraft: Tweaked
- HTTP enabled in config (usually enabled by default)
- Optional: Advanced Monitor for pixel art display

## Manual Installation

If you prefer to install manually:

1. Download all files from this repository
2. Place `startup.lua` in the computer's root directory
3. Create a `snowyos/` folder and place the other files there
4. Restart the computer

## First Boot

After installation:
1. You'll see the beautiful snowgolem boot screen
2. Press any key to continue
3. Log in with the credentials you created
4. Enjoy SnowyOS!

## System Structure

```
/
├── startup.lua           # Main boot file
└── snowyos/
    ├── boot.lua         # Boot screen with pixel art
    ├── install.lua      # Installation wizard
    ├── login.lua        # Authentication system
    ├── config.dat       # System configuration
    ├── screen.cfg       # Display preferences
    ├── session.dat      # Current session data
    └── users/           # User account data
        └── [username].dat
```

## Contributing

Feel free to contribute to SnowyOS! This is an open-source project built for the ComputerCraft community.

## License

MIT License - Feel free to use and modify! 