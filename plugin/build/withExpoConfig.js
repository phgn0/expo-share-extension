"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.withExpoConfig = void 0;
const index_1 = require("./index");
// extend expo app config with app extension config for our share extension
const withExpoConfig = (config) => {
    if (!config.ios?.bundleIdentifier) {
        throw new Error("You need to specify ios.bundleIdentifier in app.json.");
    }
    const extensionName = (0, index_1.getShareExtensionName)(config);
    const extensionBundleIdentifier = (0, index_1.getShareExtensionBundleIdentifier)(config);
    const appBundleIdentifier = (0, index_1.getAppBundleIdentifier)(config);
    const iosExtensions = config.extra?.eas?.build?.experimental?.ios?.appExtensions;
    const shareExtensionConfig = iosExtensions?.find((extension) => extension.targetName === extensionName);
    return {
        ...config,
        extra: {
            ...(config.extra ?? {}),
            eas: {
                ...(config.extra?.eas ?? {}),
                build: {
                    ...(config.extra?.eas?.build ?? {}),
                    experimental: {
                        ...(config.extra?.eas?.build?.experimental ?? {}),
                        ios: {
                            ...(config.extra?.eas?.build?.experimental?.ios ?? {}),
                            appExtensions: [
                                {
                                    ...(shareExtensionConfig ?? {
                                        targetName: extensionName,
                                        bundleIdentifier: extensionBundleIdentifier,
                                    }),
                                    entitlements: {
                                        ...shareExtensionConfig?.entitlements,
                                        "com.apple.security.application-groups": [
                                            (0, index_1.getAppGroup)(config.ios?.bundleIdentifier),
                                        ],
                                        ...(config.ios.usesAppleSignIn && {
                                            "com.apple.developer.applesignin": ["Default"],
                                        }),
                                    },
                                },
                                ...(iosExtensions?.filter((extension) => extension.targetName !== extensionName) ?? []),
                            ],
                        },
                    },
                },
            },
            appleApplicationGroup: (0, index_1.getAppGroup)(appBundleIdentifier),
        },
    };
};
exports.withExpoConfig = withExpoConfig;
