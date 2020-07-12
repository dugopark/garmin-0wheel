using Toybox.System as Sys;

using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Lang as Lang;

class Utils {
    // Converts hex string representation to a ByteArray.
    // Params:
    //     hex: String, should be hex string in all CAPS, with no spaces,
    //         hyphens or separators in between bytes.
    static function stringToByteArray(hex) {
        if (hex.length() % 2 == 1) {
            return null;
        }

        var outSize = hex.length() >> 1;
        var out = []b;
        var charArray = hex.toCharArray();
        var currentByte = []b;
        for (var i = 0; i < outSize; ++i) {
            var val = getHexVal(charArray[i << 1]) << 4 +
                getHexVal(charArray[(i << 1) + 1]);
            out.add(val);
        }
        return out;
    }

    static function getHexVal(char) {
        var val = char.toNumber();
        return val - (val < 58 ? 48 : 55);
    }

    static function getTimestamp() {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$:$2$:$3$",
                                    [today.hour.format("%02d"),
                                     today.min.format("%02d"),
                                     today.sec.format("%02d")]);
        return dateString;
    }

    static function log(msg) {
        Sys.println(getTimestamp() + ": " + msg);
    }
}