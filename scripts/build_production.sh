#!/bin/bash

# Finlytic Production Build Script
# Usage: ./scripts/build_production.sh [platform]
# Platforms: android, ios, web, linux, windows, macos, all

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    log_info "Flutter version: $(flutter --version | head -n 1)"
}

# Setup environment
setup_environment() {
    log_info "Setting up production environment..."
    
    if [ ! -f ".env" ]; then
        log_warning ".env file not found. Using .env.template..."
        if [ -f ".env.template" ]; then
            cp .env.template .env
            log_warning "Please update .env with your production configuration"
        else
            log_error ".env.template not found. Cannot continue."
            exit 1
        fi
    fi
    
    # Install dependencies
    log_info "Installing dependencies..."
    flutter pub get
    
    # Generate code
    log_info "Generating code..."
    dart run build_runner build --delete-conflicting-outputs
    
    log_success "Environment setup complete"
}

# Pre-build checks
pre_build_checks() {
    log_info "Running pre-build checks..."
    
    # Analyze code
    log_info "Analyzing code..."
    flutter analyze
    
    # Run tests
    log_info "Running tests..."
    flutter test
    
    log_success "Pre-build checks passed"
}

# Build Android
build_android() {
    log_info "Building Android..."
    
    # Check for keystore
    if [ ! -f "android/keystore.properties" ]; then
        log_warning "keystore.properties not found. Building with debug signing."
        flutter build apk --release
    else
        log_info "Building signed APK..."
        flutter build apk --release
        
        log_info "Building App Bundle..."
        flutter build appbundle --release
        
        log_success "Android builds completed:"
        log_success "  APK: build/app/outputs/flutter-apk/app-release.apk"
        log_success "  AAB: build/app/outputs/bundle/release/app-release.aab"
    fi
}

# Build iOS
build_ios() {
    log_info "Building iOS..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS builds are only supported on macOS"
        return 1
    fi
    
    flutter build ios --release
    
    log_success "iOS build completed: build/ios/iphoneos/Runner.app"
    
    # Archive for App Store (requires proper signing)
    if [ -f "ios/Runner/ExportOptions.plist" ]; then
        log_info "Creating App Store archive..."
        cd ios
        xcodebuild -workspace Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination 'generic/platform=iOS' \
                   -archivePath Runner.xcarchive \
                   archive
        
        xcodebuild -exportArchive \
                   -archivePath Runner.xcarchive \
                   -exportPath ../build/ios/ipa \
                   -exportOptionsPlist Runner/ExportOptions.plist
        cd ..
        
        log_success "iOS IPA created: build/ios/ipa/"
    fi
}

# Build Web
build_web() {
    log_info "Building Web..."
    
    flutter build web --release --web-renderer html
    
    log_success "Web build completed: build/web/"
}

# Build Linux
build_linux() {
    log_info "Building Linux..."
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_warning "Linux builds are recommended on Linux systems"
    fi
    
    # Enable Linux desktop
    flutter config --enable-linux-desktop
    
    # Install Linux dependencies (Ubuntu/Debian)
    if command -v apt-get &> /dev/null; then
        log_info "Installing Linux dependencies..."
        sudo apt-get update
        sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
    fi
    
    flutter build linux --release
    
    # Create tarball
    cd build/linux/x64/release/bundle/
    tar -czf ../finlytic-linux-x64.tar.gz *
    cd - > /dev/null
    
    log_success "Linux build completed: build/linux/x64/release/bundle/"
    log_success "Archive created: build/linux/x64/release/finlytic-linux-x64.tar.gz"
}

# Build Windows
build_windows() {
    log_info "Building Windows..."
    
    if [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "cygwin" ]]; then
        log_warning "Windows builds are recommended on Windows systems"
    fi
    
    # Enable Windows desktop
    flutter config --enable-windows-desktop
    
    flutter build windows --release
    
    log_success "Windows build completed: build/windows/x64/runner/Release/"
}

# Build macOS
build_macos() {
    log_info "Building macOS..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "macOS builds are only supported on macOS"
        return 1
    fi
    
    # Enable macOS desktop
    flutter config --enable-macos-desktop
    
    flutter build macos --release
    
    # Create ZIP archive
    cd build/macos/Build/Products/Release/
    zip -r ../finlytic-macos-x64.zip finlytic.app
    cd - > /dev/null
    
    log_success "macOS build completed: build/macos/Build/Products/Release/finlytic.app"
    log_success "Archive created: build/macos/Build/Products/finlytic-macos-x64.zip"
}

# Build all platforms
build_all() {
    log_info "Building for all platforms..."
    
    case "$OSTYPE" in
        darwin*)
            build_android
            build_ios
            build_web
            build_macos
            ;;
        linux-gnu*)
            build_android
            build_web
            build_linux
            ;;
        msys*|cygwin*)
            build_android
            build_web
            build_windows
            ;;
        *)
            log_warning "Unknown OS type: $OSTYPE"
            build_android
            build_web
            ;;
    esac
}

# Clean builds
clean_builds() {
    log_info "Cleaning previous builds..."
    flutter clean
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    log_success "Clean completed"
}

# Main script
main() {
    local platform="${1:-all}"
    
    log_info "Finlytic Production Build Script"
    log_info "Platform: $platform"
    log_info "==============================="
    
    # Check prerequisites
    check_flutter
    
    # Setup environment
    setup_environment
    
    # Run pre-build checks
    if [ "$2" != "--skip-checks" ]; then
        pre_build_checks
    fi
    
    # Build based on platform
    case "$platform" in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        web)
            build_web
            ;;
        linux)
            build_linux
            ;;
        windows)
            build_windows
            ;;
        macos)
            build_macos
            ;;
        all)
            build_all
            ;;
        clean)
            clean_builds
            ;;
        *)
            log_error "Unknown platform: $platform"
            log_info "Available platforms: android, ios, web, linux, windows, macos, all, clean"
            exit 1
            ;;
    esac
    
    log_success "Build script completed successfully!"
}

# Run main function with all arguments
main "$@"