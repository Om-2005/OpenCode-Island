<div align="center">
  <img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" alt="Logo" width="100" height="100">
  <h3 align="center">OpenCode Island</h3>
  <p align="center">
    A macOS menu bar app that brings a Dynamic Island-style interface for interacting with OpenCode.
    <br />
    <br />
    <a href="https://github.com/ryanvog/OpenCode-Island/releases/latest" target="_blank" rel="noopener noreferrer">
      <img src="https://img.shields.io/github/v/release/ryanvog/OpenCode-Island?style=rounded&color=white&labelColor=000000&label=release" alt="Release Version" />
    </a>
    <a href="#" target="_blank" rel="noopener noreferrer">
      <img alt="GitHub Downloads" src="https://img.shields.io/github/downloads/ryanvog/OpenCode-Island/total?style=rounded&color=white&labelColor=000000">
    </a>
  </p>
</div>

> **Note:** This project is inspired by [Claude Island](https://github.com/farouqaldori/claude-island) by [@farouqaldori](https://github.com/farouqaldori). It is **not affiliated with** [OpenCode](https://opencode.ai) or the OpenCode team.

## Features

- **Notch UI** — Animated overlay that expands from the MacBook notch
- **Summon with Hotkey** — Double-tap Command (or customize) to summon the prompt interface
- **Agent Selection** — Choose from available OpenCode agents with `/` prefix
- **Model Selection** — Pick from 40+ AI models across multiple providers
- **Image Support** — Paste images (Cmd+V) to include in your prompts
- **Expandable Results** — View responses in a compact or expanded view
- **Auto-Start Server** — Optionally auto-start OpenCode server on launch
- **Working Directory** — Configure which directory OpenCode operates in

## Requirements

- macOS 15.6+
- [OpenCode CLI](https://opencode.ai) installed and configured

## Install

Download the latest release or build from source:

```bash
xcodebuild -scheme ClaudeIsland -configuration Release build
```

## How It Works

OpenCode Island connects to a local OpenCode server (default: `http://localhost:19191`). When you summon the island with your hotkey:

1. Type your prompt in the text field
2. Optionally select an agent by typing `/` or using the picker
3. Press Enter to submit
4. View the response in the expandable result view

The app can auto-start the OpenCode server if it's not running, or you can manage it manually.

## Configuration

Access settings by clicking the gear icon in the island:

- **Server URL** — Custom server URL (default: localhost:19191)
- **Auto-Start Server** — Automatically start OpenCode when app launches
- **Working Directory** — Directory for OpenCode to operate in
- **Default Agent** — Your preferred agent for new prompts
- **Default Model** — Your preferred AI model

## Credits

- Original [Claude Island](https://github.com/farouqaldori/claude-island) by [@farouqaldori](https://github.com/farouqaldori)
- [OpenCode](https://opencode.ai) by the SST team

## License

Apache 2.0
