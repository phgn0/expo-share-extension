import { XcodeProject } from "expo/config-plugins";
export declare function addBuildPhases(xcodeProject: XcodeProject, { targetUuid, groupName, productFile, resources, }: {
    targetUuid: string;
    groupName: string;
    productFile: {
        uuid: string;
        target: string;
        basename: string;
        group: string;
    };
    resources: string[];
}): void;
