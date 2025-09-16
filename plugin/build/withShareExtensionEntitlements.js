"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.withShareExtensionEntitlements = void 0;
const plist_1 = __importDefault(require("@expo/plist"));
const config_plugins_1 = require("expo/config-plugins");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const index_1 = require("./index");
const withShareExtensionEntitlements = (config) => {
    return (0, config_plugins_1.withEntitlementsPlist)(config, (config) => {
        const targetName = (0, index_1.getShareExtensionName)(config);
        const targetPath = path_1.default.join(config.modRequest.platformProjectRoot, targetName);
        const filePath = path_1.default.join(targetPath, `${targetName}.entitlements`);
        const bundleIdentifier = (0, index_1.getAppBundleIdentifier)(config);
        const existingAppGroup = config.ios?.entitlements?.["com.apple.security.application-groups"];
        let shareExtensionEntitlements = {
            "com.apple.security.application-groups": existingAppGroup ?? [(0, index_1.getAppGroup)(bundleIdentifier)],
        };
        if (config.ios?.usesAppleSignIn) {
            shareExtensionEntitlements = {
                ...shareExtensionEntitlements,
                "com.apple.developer.applesignin": ["Default"],
            };
        }
        fs_1.default.mkdirSync(path_1.default.dirname(filePath), { recursive: true });
        fs_1.default.writeFileSync(filePath, plist_1.default.build(shareExtensionEntitlements));
        return config;
    });
};
exports.withShareExtensionEntitlements = withShareExtensionEntitlements;
