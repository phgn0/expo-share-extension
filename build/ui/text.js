import { forwardRef } from "react";
// @ts-ignore
import { NativeText } from "react-native/Libraries/Text/TextNativeComponent";
const Text = forwardRef((props, ref) => {
    return <NativeText {...props} ref={ref} allowFontScaling={false}/>;
});
Text.displayName = "RCTText";
export { Text };
//# sourceMappingURL=text.js.map