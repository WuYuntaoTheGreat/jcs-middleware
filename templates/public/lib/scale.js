/**
 * Created by wuyt on 14-9-9.
 */
(function() {
    // alert("ratio=" + window.devicePixelRatio + "; browser=" + window.navigator.appVersion);
    var scale = 1.0;
    if (window.devicePixelRatio === 2) {
        if (window.navigator.appVersion.match(/iphone/gi)) {
            scale = 0.5;
        } else if (window.navigator.appVersion.match(/XiaoMi/gi)) {
            scale = 0.56;
        } else {
            scale = 0.6;
        }
    } else if (window.devicePixelRatio === 3){
        scale = 0.56;
    } else if (window.devicePixelRatio === 1.5){
        scale = 0.4;
    }

    var text = '<meta name="viewport" content="width=640, ' +
        ' initial-scale=' + scale +',' +
        ' maximum-scale=' + scale +',' +
        ' minimum-scale=' + scale + '" />';
    document.write(text);
})();
