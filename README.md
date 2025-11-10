# CodeLab IDE

A cross-platform IDE built with Flutter for educational coding labs and development. Built with a modular monorepo architecture using Melos for package management.

## Features

### ✅ MVP Features
- **File Tree Navigation** - Browse and navigate project structure
- **Code Editor** - Edit files with syntax highlighting for multiple languages
- **Built-in Terminal** - Execute commands and run scripts
- **Cross-platform** - Runs on Windows, Linux, and macOS
- **Modular Architecture** - Clean separation of concerns with dedicated packages

### 🎯 Core Functionality
- Open and browse project directories
- Edit files with real-time syntax highlighting
- Save files with keyboard shortcuts
- Execute commands in integrated terminal
- Resizable panels for optimal workflow
- BLoC state management for predictable state updates
- Dependency injection with CherryPick
- Functional programming patterns with FPDart

## Supported Languages

The IDE supports syntax highlighting for:
- **Dart** -  support
- **Python** -  support  
- **JavaScript/TypeScript** -  support
- **Java** -  support
- **C/C++** -  support
- **HTML/CSS** -  support
- **JSON/YAML** -  support
- **Markdown** -  support
- **And more...**

## Getting Started

### Prerequisites
- Flutter SDK (version 3.9.0 or higher)
- Dart SDK
- Melos (for monorepo management)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd codelab_ide
```

2. Install Melos globally:
```bash
dart pub global activate melos
```

3. Bootstrap the workspace:
```bash
melos bootstrap
```

4. Run the application:
```bash
melos run:codelab_ide
```

### Development Commands

```bash
# Run code generation
melos generate

# Run tests for all packages
melos test

# Run the main IDE application
melos run:codelab_ide

# Run individual package examples
melos run:uikit_example
```

### Building for Distribution

#### macOS
```bash
flutter build macos
```

#### Windows
```bash
flutter build windows
```

#### Linux
```bash
flutter build linux
```

## Project Structure

This project uses a monorepo architecture managed by Melos:

```
codelab_ide/
├── apps/
│   └── codelab_ide/                 # Main Flutter application
│       ├── lib/
│       │   ├── main.dart            # Application entry point
│       │   ├── codelab_app.dart     # Root widget with DI setup
│       │   ├── pages/               # Application pages
│       │   └── widgets/             # Application-specific widgets
│       └── pubspec.yaml             # App dependencies
├── packages/
│   ├── codelab_core/                # Core services and models
│   │   ├── lib/src/
│   │   │   ├── services/            # FileService, ProjectService, RunService
│   │   │   ├── models/              # FileNode, ProjectConfig
│   │   │   ├── errors/              # AppError, FileError
│   │   │   └── utils/               # Logger, ProjectContext
│   │   └── pubspec.yaml
│   ├── codelab_engine/              # Business logic and UI widgets
│   │   ├── lib/src/
│   │   │   ├── project_bloc.dart    # Main project state management
│   │   │   └── widgets/             # Editor, FileTree, Terminal, etc.
│   │   └── pubspec.yaml
│   ├── codelab_terminal/            # Terminal implementation
│   │   ├── lib/src/widgets/         # Terminal widget and bloc
│   │   └── pubspec.yaml
│   ├── codelab_uikit/               # UI components and theming
│   │   ├── lib/src/                 # Base UI components
│   │   ├── example/                 # Example app with Fluent UI
│   │   └── pubspec.yaml
│   ├── codelab_ai_assistant/        # AI assistant integration
│   │   ├── lib/src/                 # AI assistant implementation
│   │   └── pubspec.yaml
│   └── codelab_version_control/     # Git integration
│       ├── lib/src/                 # Version control services
│       └── pubspec.yaml
├── pubspec.yaml                     # Workspace configuration
└── melos.yaml                       # Melos monorepo configuration
```

## Usage

1. **Open a Project**: Click the folder icon in the toolbar to open a project directory
2. **Navigate Files**: Use the file tree panel to browse and open files
3. **Edit Code**: Write and edit code in the editor with syntax highlighting
4. **Save Files**: Use Ctrl+S (Cmd+S on macOS) or the save button
5. **Run Commands**: Use the terminal panel to execute commands and scripts
6. **Run Current File**: Click the play button to execute the currently open file

## Example Project

Check the `example_project/` directory for sample files demonstrating the IDE's capabilities:
- `hello.dart` - Dart example
- `example.py` - Python example  
- `README.md` - Project documentation

## Architecture & Technology Stack

### Core Technologies
- **Flutter/Dart** - Cross-platform UI framework
- **Melos** - Monorepo management and tooling
- **BLoC** - State management with predictable state transitions
- **CherryPick** - Dependency injection for testable code
- **FPDart** - Functional programming utilities (Either, TaskEither)
- **Freezed** - Code generation for immutable data classes

### Key Dependencies

#### Core Packages
- `flutter_bloc` & `bloc` - State management
- `fpdart` - Functional programming patterns
- `cherrypick` - Dependency injection
- `freezed_annotation` & `freezed` - Immutable data classes

#### File System & UI
- `file_picker` - File and directory selection
- `file` & `path` - File system operations
- `fluent_ui` - Windows-style UI components (in codelab_uikit)

#### Code Editing
- `flutter_code_editor` - Advanced code editing with syntax highlighting
- `code_text_field` - Code editor widgets
- `highlight` & `flutter_highlight` - Syntax highlighting

#### Terminal & Execution
- `xterm` - Terminal emulation
- `process_run` - Command execution
- `logger` - Structured logging

### Development Dependencies
- `build_runner` - Code generation
- `melos` - Monorepo tooling
- `cherrypick_generator` - DI code generation

## Development

### Current Status
This project is actively developed with a modular architecture that enables easy extension and maintenance. The core IDE functionality is implemented with clean separation of concerns.

### ✅ Implemented Features
- **Modular Architecture** - Clean separation with dedicated packages
- **File Management** - Project loading, file tree navigation, file operations
- **Code Editor** - Syntax highlighting for multiple languages
- **Terminal Integration** - Command execution and script running
- **State Management** - BLoC pattern with immutable states
- **Dependency Injection** - CherryPick for testable code
- **Cross-platform** - Windows, Linux, macOS support
- **UI Components** - Fluent UI integration for Windows-style interface

### 🚧 In Development
- **AI Assistant** - Intelligent code suggestions and assistance
- **Version Control** - Git integration and repository management
- **Advanced Editing** - Code completion and refactoring tools

### 🔮 Future Enhancements
- **Debugging Support** - Integrated debugger with breakpoints
- **Plugin System** - Extensible architecture for third-party plugins
- **Multi-tab Editing** - Tabbed interface for multiple files
- **Theme Customization** - Custom color schemes and themes
- **Package Management** - Integrated pub.dev package management
- **Collaboration Tools** - Real-time collaboration features

### Contributing
The project uses conventional commits and follows clean code practices. Each package is independently testable and can be developed in isolation.

## License

```
MIT License

Copyright (c) 2025 CodeLab IDE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
