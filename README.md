# DigiByte Validator on Nix

[![NixOS](https://img.shields.io/badge/NixOS-24.05-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![DigiByte](https://img.shields.io/badge/DigiByte-7.17.3-blue.svg)](https://digibyte.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A Nix-based build configuration for the DigiByte validator node, supporting multiple architectures and deployment options.

## Features

- Cross-platform support (Linux and macOS)
- Multiple architecture support (x86_64/aarch64)
- Optional GUI support on Linux
- Architecture-specific optimizations
- Reproducible builds via Nix flakes

## Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled
- System requirements:
  - RAM: 2GB minimum (4GB recommended)
  - Storage: 50GB+ free space
  - CPU: 2 cores minimum

## Installation

1. **Clone the repository**
   ```
   git clone https://github.com/your-username/digibyte-validator-on-nix
   cd digibyte-validator-on-nix
   ```

2. **Enable Nix flakes** (if not already enabled)
   ```
   # Add to ~/.config/nix/nix.conf:
   experimental-features = nix-command flakes
   ```

3. **Build the node**
   ```
   # Daemon-only build (all platforms):
   nix build

   # Full node with GUI (Linux only):
   nix build .#digibyte
   ```

## Usage

### Running the Daemon
```
# Start the daemon
./result/bin/digibyted

# Check daemon status
./result/bin/digibyte-cli getinfo
```

### Running the GUI (Linux only)
```
./result/bin/digibyte-qt
```

### Configuration

Default data directory locations:
- Linux: `~/.digibyte/`
- macOS: `~/Library/Application Support/DigiByte/`

Create or modify `digibyte.conf`:
```
# Example configuration
rpcuser=your-rpc-user
rpcpassword=your-secure-password
server=1
daemon=1
txindex=1
```

## Development

Enter development shell:
```
nix develop
```

Build specific targets:
```
# Build daemon only
nix build .#digibyted

# Build with GUI (Linux)
nix build .#digibyte
```

## Architecture Support

This project supports the following architectures:
- x86_64-linux
- aarch64-linux
- x86_64-darwin
- aarch64-darwin

Each architecture has optimized build configurations defined in `pkgs/digibyte/systems.nix`.

## Troubleshooting

### Common Issues

1. **Build failures**
   ```
   # Clear build cache
   nix store gc
   
   # Clean build
   nix build --rebuild
   ```

2. **Missing dependencies**
   ```
   # Update flake inputs
   nix flake update
   ```

3. **Architecture-specific issues**
   - Check `pkgs/digibyte/systems.nix` for your platform configuration
   - Verify system requirements are met

### Debug Logging

Enable debug logging in `digibyte.conf`:
```
debug=1
printtoconsole=1
```

## Project Structure
```
.
├── flake.nix           # Nix flake configuration
├── flake.lock          # Flake dependencies lock file
├── default.nix         # Default Nix build configuration
└── pkgs
    └── digibyte
        ├── default.nix # DigiByte package configuration
        └── systems.nix # Architecture-specific settings
```

## Documentation

- [DigiByte Core Documentation](https://github.com/digibyte-core/digibyte/tree/master/doc)
- [Nix Package Manager Manual](https://nixos.org/manual/nix/stable/)
- [NixOS Wiki](https://nixos.wiki/)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [DigiByte Core Team](https://digibyte.org)
- [NixOS Community](https://nixos.org)
- All contributors who helped with testing and improvements

---

*For more information about DigiByte, visit [digibyte.org](https://digibyte.org)*