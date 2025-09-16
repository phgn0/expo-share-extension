import { type ConfigPlugin } from "expo/config-plugins";
import { type ActivationRule, type BackgroundColor, type Height } from "./index";
export declare const withShareExtensionInfoPlist: ConfigPlugin<{
    fonts: string[];
    activationRules?: ActivationRule[];
    backgroundColor?: BackgroundColor;
    height?: Height;
    preprocessingFile?: string;
    googleServicesFile?: string;
}>;
