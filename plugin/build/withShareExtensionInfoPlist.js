"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.withShareExtensionInfoPlist = void 0;
const plist_1 = __importDefault(require("@expo/plist"));
const config_plugins_1 = require("expo/config-plugins");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const index_1 = require("./index");
const withShareExtensionInfoPlist = (config, { fonts = [], activationRules = [{ type: "text" }, { type: "url" }], backgroundColor, height, preprocessingFile, googleServicesFile, }) => {
    return (0, config_plugins_1.withInfoPlist)(config, (config) => {
        const targetName = (0, index_1.getShareExtensionName)(config);
        const targetPath = path_1.default.join(config.modRequest.platformProjectRoot, targetName);
        const filePath = path_1.default.join(targetPath, "Info.plist");
        const bundleIdentifier = (0, index_1.getAppBundleIdentifier)(config);
        const appGroup = (0, index_1.getAppGroup)(bundleIdentifier);
        let infoPlist = {
            CFBundleDevelopmentRegion: "$(DEVELOPMENT_LANGUAGE)",
            CFBundleDisplayName: "$(PRODUCT_NAME) Share Extension",
            CFBundleExecutable: "$(EXECUTABLE_NAME)",
            CFBundleIdentifier: "$(PRODUCT_BUNDLE_IDENTIFIER)",
            CFBundleInfoDictionaryVersion: "6.0",
            CFBundleName: "$(PRODUCT_NAME)",
            CFBundlePackageType: "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
            CFBundleShortVersionString: "$(MARKETING_VERSION)",
            CFBundleVersion: "$(CURRENT_PROJECT_VERSION)",
            LSRequiresIPhoneOS: true,
            NSAppTransportSecurity: {
                NSExceptionDomains: {
                    localhost: {
                        NSExceptionAllowsInsecureHTTPLoads: true,
                    },
                },
            },
            UIRequiredDeviceCapabilities: ["armv7"],
            UIStatusBarStyle: "UIStatusBarStyleDefault",
            UISupportedInterfaceOrientations: [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationPortraitUpsideDown",
            ],
            UIUserInterfaceStyle: "Automatic",
            UIViewControllerBasedStatusBarAppearance: false,
            UIApplicationSceneManifest: {
                UIApplicationSupportsMultipleScenes: true,
                UISceneConfigurations: {},
            },
            UIAppFonts: fonts.map((font) => path_1.default.basename(font)) ?? [],
            // we need to add an AppGroup key for compatibility with react-native-mmkv https://github.com/mrousavy/react-native-mmkv
            AppGroup: appGroup,
            NSExtension: {
                NSExtensionAttributes: {
                    NSExtensionActivationRule: activationRules.reduce((acc, current) => {
                        switch (current.type) {
                            case "image":
                                return {
                                    ...acc,
                                    NSExtensionActivationSupportsImageWithMaxCount: current.max ?? 1,
                                };
                            case "video":
                                return {
                                    ...acc,
                                    NSExtensionActivationSupportsMovieWithMaxCount: current.max ?? 1,
                                };
                            case "text":
                                return {
                                    ...acc,
                                    NSExtensionActivationSupportsText: true,
                                };
                            case "url":
                                return preprocessingFile
                                    ? {
                                        ...acc,
                                        NSExtensionActivationSupportsWebPageWithMaxCount: current.max ?? 1,
                                        NSExtensionActivationSupportsWebURLWithMaxCount: current.max ?? 1,
                                    }
                                    : {
                                        ...acc,
                                        NSExtensionActivationSupportsWebURLWithMaxCount: current.max ?? 1,
                                    };
                            case "file":
                                return {
                                    ...acc,
                                    NSExtensionActivationSupportsFileWithMaxCount: current.max ?? 1,
                                };
                            case "custom-query":
                                return current.query;
                            default:
                                return acc;
                        }
                    }, {}),
                    ...(preprocessingFile && {
                        NSExtensionJavaScriptPreprocessingFile: path_1.default.basename(preprocessingFile, path_1.default.extname(preprocessingFile)),
                    }),
                },
                NSExtensionPrincipalClass: "$(PRODUCT_MODULE_NAME).ShareExtensionViewController",
                NSExtensionPointIdentifier: "com.apple.share-services",
            },
            ShareExtensionBackgroundColor: backgroundColor,
            ShareExtensionHeight: height,
            HostAppScheme: config.scheme,
            WithFirebase: !!googleServicesFile,
        };
        // see https://github.com/expo/expo/blob/main/packages/expo-apple-authentication/plugin/src/withAppleAuthIOS.ts#L3-L17
        if (config.ios?.usesAppleSignIn) {
            infoPlist = {
                ...infoPlist,
                CFBundleAllowedMixedLocalizations: config.modResults.CFBundleAllowMixedLocalizations ?? true,
            };
        }
        fs_1.default.mkdirSync(path_1.default.dirname(filePath), {
            recursive: true,
        });
        fs_1.default.writeFileSync(filePath, plist_1.default.build(infoPlist));
        return config;
    });
};
exports.withShareExtensionInfoPlist = withShareExtensionInfoPlist;
