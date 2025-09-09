export declare function close(): void;
export declare function openHostApp(path: string): void;
export declare function clearAppGroupContainer(args?: {
    cleanUpBefore?: Date;
}): Promise<void>;
export interface IExtensionPreprocessingJS {
    run: (args: {
        completionFunction: (data: unknown) => void;
    }) => void;
    finalize: (args: unknown) => void;
}
export type InitialProps = {
    files?: string[];
    images?: string[];
    videos?: string[];
    text?: string;
    url?: string;
    preprocessingResults?: unknown;
};
export { Text } from "./ui/text";
export { TextInput } from "./ui/text-input";
export { View } from "./ui/view";
//# sourceMappingURL=index.d.ts.map