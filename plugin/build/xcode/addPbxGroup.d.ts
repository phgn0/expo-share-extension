import { XcodeProject } from "expo/config-plugins";
export declare function addPbxGroup(xcodeProject: XcodeProject, { targetName, platformProjectRoot, fonts, googleServicesFilePath, preprocessingFilePath, }: {
    targetName: string;
    platformProjectRoot: string;
    fonts: string[];
    googleServicesFilePath?: string;
    preprocessingFilePath?: string;
}): void;
