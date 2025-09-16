"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getShareExtensionEntitlementsFileName = exports.getShareExtensionName = exports.getShareExtensionBundleIdentifier = exports.getAppBundleIdentifier = exports.getAppGroup = void 0;
const config_plugins_1 = require("expo/config-plugins");
const v = __importStar(require("valibot"));
const withAppEntitlements_1 = require("./withAppEntitlements");
const withAppInfoPlist_1 = require("./withAppInfoPlist");
const withExpoConfig_1 = require("./withExpoConfig");
const withPodfile_1 = require("./withPodfile");
const withShareExtensionEntitlements_1 = require("./withShareExtensionEntitlements");
const withShareExtensionInfoPlist_1 = require("./withShareExtensionInfoPlist");
const withShareExtensionTarget_1 = require("./withShareExtensionTarget");
const getAppGroup = (identifier) => `group.${identifier}`;
exports.getAppGroup = getAppGroup;
const getAppBundleIdentifier = (config) => {
    if (!config.ios?.bundleIdentifier) {
        throw new Error("No bundle identifier");
    }
    return config.ios?.bundleIdentifier;
};
exports.getAppBundleIdentifier = getAppBundleIdentifier;
const getShareExtensionBundleIdentifier = (config) => {
    return `${(0, exports.getAppBundleIdentifier)(config)}.ShareExtension`;
};
exports.getShareExtensionBundleIdentifier = getShareExtensionBundleIdentifier;
const getShareExtensionName = (config) => {
    return `${config_plugins_1.IOSConfig.XcodeUtils.sanitizedName(config.name)}ShareExtension`;
};
exports.getShareExtensionName = getShareExtensionName;
const getShareExtensionEntitlementsFileName = (config) => {
    const name = (0, exports.getShareExtensionName)(config);
    return `${name}.entitlements`;
};
exports.getShareExtensionEntitlementsFileName = getShareExtensionEntitlementsFileName;
const rgbaSchema = v.object({
    red: v.pipe(v.number(), v.minValue(0), v.maxValue(255)),
    green: v.pipe(v.number(), v.minValue(0), v.maxValue(255)),
    blue: v.pipe(v.number(), v.minValue(0), v.maxValue(255)),
    alpha: v.pipe(v.number(), v.minValue(0), v.maxValue(255)),
});
const heightSchema = v.pipe(v.number(), v.minValue(50), v.maxValue(1000));
const withShareExtension = (config, props) => {
    if (props?.backgroundColor) {
        v.parse(rgbaSchema, props.backgroundColor);
    }
    if (props?.height) {
        v.parse(heightSchema, props.height);
    }
    const expoFontPlugin = config.plugins?.find((p) => Array.isArray(p) && p.length && p.at(0) === "expo-font");
    const fonts = expoFontPlugin?.at(1).fonts ?? [];
    return (0, config_plugins_1.withPlugins)(config, [
        withExpoConfig_1.withExpoConfig,
        withAppEntitlements_1.withAppEntitlements,
        withAppInfoPlist_1.withAppInfoPlist,
        [withPodfile_1.withPodfile, { excludedPackages: props?.excludedPackages ?? [] }],
        [
            withShareExtensionInfoPlist_1.withShareExtensionInfoPlist,
            {
                fonts,
                activationRules: props?.activationRules,
                backgroundColor: props?.backgroundColor,
                height: props?.height,
                preprocessingFile: props?.preprocessingFile,
                googleServicesFile: props?.googleServicesFile,
            },
        ],
        withShareExtensionEntitlements_1.withShareExtensionEntitlements,
        [
            withShareExtensionTarget_1.withShareExtensionTarget,
            {
                fonts,
                googleServicesFile: props?.googleServicesFile,
                preprocessingFile: props?.preprocessingFile,
            },
        ],
    ]);
};
exports.default = withShareExtension;
