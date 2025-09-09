import { forwardRef } from "react";
import { TextInput as RNTextInput } from "react-native";
const TextInput = forwardRef((props, ref) => {
    return <RNTextInput {...props} ref={ref} allowFontScaling={false}/>;
});
export { TextInput };
//# sourceMappingURL=text-input.js.map