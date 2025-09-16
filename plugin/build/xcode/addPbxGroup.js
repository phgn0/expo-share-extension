"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPbxGroup = addPbxGroup;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
function addPbxGroup(xcodeProject, { targetName, platformProjectRoot, fonts = [], googleServicesFilePath, preprocessingFilePath, }) {
    const targetPath = path_1.default.join(platformProjectRoot, targetName);
    if (!fs_1.default.existsSync(targetPath)) {
        fs_1.default.mkdirSync(targetPath, { recursive: true });
    }
    copyFileSync(path_1.default.join(__dirname, "../../swift/ShareExtensionViewController.swift"), targetPath, "ShareExtensionViewController.swift");
    for (const font of fonts) {
        copyFileSync(font, targetPath);
    }
    const files = [
        "ShareExtensionViewController.swift",
        "Info.plist",
        `${targetName}.entitlements`,
        ...fonts.map((font) => path_1.default.basename(font)),
    ];
    if (googleServicesFilePath?.length) {
        copyFileSync(googleServicesFilePath, targetPath, "GoogleService-Info.plist");
        files.push("GoogleService-Info.plist");
    }
    if (preprocessingFilePath?.length) {
        copyFileSync(preprocessingFilePath, targetPath);
        files.push(path_1.default.basename(preprocessingFilePath));
    }
    // Add PBX group
    const { uuid: pbxGroupUuid } = xcodeProject.addPbxGroup(files, targetName, targetName);
    // Add PBXGroup to top level group
    const groups = xcodeProject.hash.project.objects["PBXGroup"];
    if (pbxGroupUuid) {
        Object.keys(groups).forEach(function (key) {
            if (groups[key].name === undefined && groups[key].path === undefined) {
                xcodeProject.addToPbxGroup(pbxGroupUuid, key);
            }
        });
    }
}
function copyFileSync(source, target, basename) {
    let targetFile = target;
    if (fs_1.default.existsSync(target) && fs_1.default.lstatSync(target).isDirectory()) {
        targetFile = path_1.default.join(target, basename ?? path_1.default.basename(source));
    }
    fs_1.default.writeFileSync(targetFile, fs_1.default.readFileSync(source));
}
