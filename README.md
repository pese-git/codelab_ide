# CodeLab IDE

A cross-platform IDE built with Flutter for educational coding labs and development.

## Features

### ✅ MVP Features
- **File Tree Navigation** - Browse and navigate project structure
- **Code Editor** - Edit files with syntax highlighting for multiple languages
- **Built-in Terminal** - Execute commands and run scripts
- **Cross-platform** - Runs on Windows, Linux, and macOS

### 🎯 Core Functionality
- Open and browse project directories
- Edit files with real-time syntax highlighting
- Save files with keyboard shortcuts
- Execute commands in integrated terminal
- Resizable panels for optimal workflow

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

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd codelab_ide
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
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

```
lib/
├── main.dart                 # Main application entry point
├── models/
│   └── project_model.dart    # Project state and file tree models
├── services/
│   ├── file_service.dart     # File operations and project loading
│   └── run_service.dart      # Command execution and script running
└── widgets/
    ├── editor_widget.dart    # Code editor with syntax highlighting
    ├── file_tree_widget.dart # Project file tree navigation
    └── terminal_widget.dart  # Integrated terminal
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

## Dependencies

- `code_text_field` - Advanced code editing
- `highlight` - Syntax highlighting
- `provider` - State management
- `file_picker` - File and directory selection
- `process_run` - Command execution
- `path` & `file` - File system operations

## Development

This is an MVP (Minimum Viable Product) focused on core IDE functionality. Future enhancements could include:

- Advanced code completion
- Git integration
- Debugging support
- Plugin system
- Theme customization
- Multi-tab editing

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
