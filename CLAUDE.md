# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `expo-share-extension`, an Expo config plugin that creates iOS share extensions with custom views. The project consists of two main parts:
1. **Native Module** (`src/`): TypeScript/React Native module providing the runtime API
2. **Config Plugin** (`plugin/src/`): TypeScript plugin that modifies Expo/iOS projects during build

## Development Commands

### Core Commands
- `npm run build` - Build the native module (uses expo-module build)
- `npm run clean` - Clean build artifacts
- `npm run lint` - Run linting (uses expo-module lint)
- `npm run test` - Run tests (uses expo-module test)
- `npm run prepare` - Prepare for publishing
- `npm run prepublishOnly` - Pre-publish checks

### Development Workflow
1. `npm run build` - Start expo module build in watch mode
2. `npm run build plugin` - Start config plugin build in watch mode
3. `cd example && npm run prebuild` - Generate iOS project for testing
4. `cd example && npm run ios` - Run the example app

### XCode Integration
- `npm run open:ios` - Open example iOS project in Xcode
- `npm run open:android` - Open example Android project in Android Studio

## Architecture

### Native Module (`src/`)
- **`index.ts`**: Main API exports (`close`, `openHostApp`, `clearAppGroupContainer`)
- **`ExpoShareExtensionModule.ts`**: Native module bridge using expo-modules-core
- **`ui/`**: Custom React Native components (Text, TextInput, View) that work in share extensions

### Config Plugin (`plugin/src/`)
The plugin modifies iOS projects by:
- **`withShareExtensionTarget.ts`**: Adds iOS share extension target to Xcode project
- **`withShareExtensionInfoPlist.ts`**: Configures share extension Info.plist and activation rules
- **`withShareExtensionEntitlements.ts`**: Sets up app group entitlements
- **`withAppEntitlements.ts`** & **`withAppInfoPlist.ts`**: Modifies main app configuration
- **`withPodfile.ts`**: Updates Podfile to exclude unnecessary modules from share extension
- **`xcode/`**: Low-level Xcode project manipulation utilities

### Key Concepts
- **App Groups**: Enable data sharing between main app and share extension
- **Bundle Identifiers**: Share extension uses `{mainBundleId}.ShareExtension`
- **Activation Rules**: Define what content types trigger the share extension (text, URLs, images, etc.)
- **Metro Configuration**: `metro.js` handles bundling for both main app and share extension

## Example App Structure
The `example/` directory contains a complete Expo app demonstrating the plugin usage, including:
- Main app entry point (`index.js`)
- Share extension entry point (`index.share.js`)
- Metro configuration with `withShareExtension`

## Plugin Configuration Schema
The plugin accepts configuration for:
- `activationRules`: Content types that trigger the extension
- `backgroundColor`: Custom background color (RGBA)
- `height`: Custom extension height (50-1000px)
- `excludedPackages`: Expo modules to exclude from share extension bundle
- `googleServicesFile`: Firebase configuration for share extension
- `preprocessingFile`: JavaScript file for webpage preprocessing