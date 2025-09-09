import ExpoShareExtensionModule from "./ExpoShareExtensionModule";
export function close() {
    return ExpoShareExtensionModule.close();
}
export function openHostApp(path) {
    return ExpoShareExtensionModule.openHostApp(path);
}
export async function clearAppGroupContainer(args) {
    return await ExpoShareExtensionModule.clearAppGroupContainer(args?.cleanUpBefore?.toISOString());
}
export { Text } from "./ui/text";
export { TextInput } from "./ui/text-input";
export { View } from "./ui/view";
//# sourceMappingURL=index.js.map