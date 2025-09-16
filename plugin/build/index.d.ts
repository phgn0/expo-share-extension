import { type ExpoConfig } from "@expo/config-types";
import { ConfigPlugin } from "expo/config-plugins";
import * as v from "valibot";
export declare const getAppGroup: (identifier: string) => string;
export declare const getAppBundleIdentifier: (config: ExpoConfig) => string;
export declare const getShareExtensionBundleIdentifier: (config: ExpoConfig) => string;
export declare const getShareExtensionName: (config: ExpoConfig) => string;
export declare const getShareExtensionEntitlementsFileName: (config: ExpoConfig) => string;
declare const rgbaSchema: v.ObjectSchema<{
    readonly red: v.SchemaWithPipe<readonly [v.NumberSchema<undefined>, v.MinValueAction<number, 0, undefined>, v.MaxValueAction<number, 255, undefined>]>;
    readonly green: v.SchemaWithPipe<readonly [v.NumberSchema<undefined>, v.MinValueAction<number, 0, undefined>, v.MaxValueAction<number, 255, undefined>]>;
    readonly blue: v.SchemaWithPipe<readonly [v.NumberSchema<undefined>, v.MinValueAction<number, 0, undefined>, v.MaxValueAction<number, 255, undefined>]>;
    readonly alpha: v.SchemaWithPipe<readonly [v.NumberSchema<undefined>, v.MinValueAction<number, 0, undefined>, v.MaxValueAction<number, 255, undefined>]>;
}, undefined>;
export type BackgroundColor = v.InferOutput<typeof rgbaSchema>;
declare const heightSchema: v.SchemaWithPipe<readonly [v.NumberSchema<undefined>, v.MinValueAction<number, 50, undefined>, v.MaxValueAction<number, 1000, undefined>]>;
export type Height = v.InferOutput<typeof heightSchema>;
type ActivationType = "image" | "video" | "text" | "url" | "file";
export type ActivationRule = {
    type: ActivationType;
    max?: number;
} | {
    type: "custom-query";
    query: string;
};
declare const withShareExtension: ConfigPlugin<{
    activationRules?: ActivationRule[];
    backgroundColor?: BackgroundColor;
    height?: Height;
    excludedPackages?: string[];
    googleServicesFile?: string;
    preprocessingFile?: string;
}>;
export default withShareExtension;
