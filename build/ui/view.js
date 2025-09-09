import { forwardRef } from "react";
// @ts-ignore
import NativeView from "react-native/Libraries/Components/View/ViewNativeComponent";
const View = forwardRef((props, ref) => {
    return <NativeView {...props} ref={ref}/>;
});
View.displayName = "RCTView";
export { View };
//# sourceMappingURL=view.js.map