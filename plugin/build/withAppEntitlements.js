"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.withAppEntitlements = void 0;
const config_plugins_1 = require("@expo/config-plugins");
const index_1 = require("./index");
const withAppEntitlements = (config) => {
    return (0, config_plugins_1.withEntitlementsPlist)(config, (config) => {
        const bundleIdentifier = (0, index_1.getAppBundleIdentifier)(config);
        if (config.ios?.entitlements?.["com.apple.security.application-groups"]) {
            return config;
        }
        config.modResults["com.apple.security.application-groups"] = [
            (0, index_1.getAppGroup)(bundleIdentifier),
        ];
        return config;
    });
};
exports.withAppEntitlements = withAppEntitlements;
