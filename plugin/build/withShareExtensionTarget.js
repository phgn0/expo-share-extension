"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.withShareExtensionTarget = void 0;
const config_plugins_1 = require("expo/config-plugins");
const path_1 = __importDefault(require("path"));
const index_1 = require("./index");
const addBuildPhases_1 = require("./xcode/addBuildPhases");
const addPbxGroup_1 = require("./xcode/addPbxGroup");
const addProductFile_1 = require("./xcode/addProductFile");
const addTargetDependency_1 = require("./xcode/addTargetDependency");
const addToPbxNativeTargetSection_1 = require("./xcode/addToPbxNativeTargetSection");
const addToPbxProjectSection_1 = require("./xcode/addToPbxProjectSection");
const addToXCConfigurationList_1 = require("./xcode/addToXCConfigurationList");
const withShareExtensionTarget = (config, { fonts = [], googleServicesFile, preprocessingFile }) => {
    return (0, config_plugins_1.withXcodeProject)(config, async (config) => {
        const xcodeProject = config.modResults;
        const targetName = (0, index_1.getShareExtensionName)(config);
        const bundleIdentifier = (0, index_1.getShareExtensionBundleIdentifier)(config);
        const marketingVersion = config.version;
        const targetUuid = xcodeProject.generateUuid();
        const groupName = "Embed Foundation Extensions";
        const { platformProjectRoot, projectRoot } = config.modRequest;
        if (config.ios?.googleServicesFile && !googleServicesFile) {
            console.warn("Warning: No Google Services file specified for Share Extension");
        }
        const resources = fonts.map((font) => path_1.default.basename(font));
        const googleServicesFilePath = googleServicesFile
            ? path_1.default.resolve(projectRoot, googleServicesFile)
            : undefined;
        if (googleServicesFile) {
            resources.push("GoogleService-Info.plist");
        }
        const preprocessingFilePath = preprocessingFile
            ? path_1.default.resolve(projectRoot, preprocessingFile)
            : undefined;
        if (preprocessingFile) {
            resources.push(path_1.default.basename(preprocessingFile));
        }
        const xCConfigurationList = (0, addToXCConfigurationList_1.addXCConfigurationList)(xcodeProject, {
            targetName,
            currentProjectVersion: config.ios?.buildNumber || "1",
            bundleIdentifier,
            marketingVersion,
        });
        const productFile = (0, addProductFile_1.addProductFile)(xcodeProject, {
            targetName,
            groupName,
        });
        const target = (0, addToPbxNativeTargetSection_1.addToPbxNativeTargetSection)(xcodeProject, {
            targetName,
            targetUuid,
            productFile,
            xCConfigurationList,
        });
        (0, addToPbxProjectSection_1.addToPbxProjectSection)(xcodeProject, target);
        (0, addTargetDependency_1.addTargetDependency)(xcodeProject, target);
        (0, addPbxGroup_1.addPbxGroup)(xcodeProject, {
            targetName,
            platformProjectRoot,
            fonts,
            googleServicesFilePath,
            preprocessingFilePath,
        });
        (0, addBuildPhases_1.addBuildPhases)(xcodeProject, {
            targetUuid,
            groupName,
            productFile,
            resources,
        });
        return config;
    });
};
exports.withShareExtensionTarget = withShareExtensionTarget;
