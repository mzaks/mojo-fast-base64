from base64 import b64encode
from fast_base64 import encode, decode
from time import now
from testing import assert_equal
from samples import mobi_dick_plain


fn main() raises:
    # var text = Path("/usr/share/dict/words").read_text()
    var text = String(mobi_dick_plain)
    var std_min_d_enc = 10000000
    var h0 = String("")
    for _ in range(10):
        var tik = now()
        h0 = b64encode(text)
        var tok = now()
        if std_min_d_enc > tok - tik:
            std_min_d_enc = tok - tik
    print("Std b64 encode:", (std_min_d_enc) / len(text), len(text))

    var h1 = String("")
    var fast_min_d_enc = 10000000
    for _ in range(10):
        var tik = now()
        h1 = encode(text)
        var tok = now()
        if fast_min_d_enc > tok - tik:
            fast_min_d_enc = tok - tik

    print("Fast b64 encode:", (fast_min_d_enc) / len(text), len(h1), len(text))
    print("Encoding speedup:", Float64(std_min_d_enc) / (fast_min_d_enc))
    
    for i in range(len(h0)):
        if h0[i] != h1[i]:
            print("std Error:", h0[i], "chrome:", h1[i], "on", i)
            break
    
    var fast_min_d_dec = 1000000
    for _ in range(10):
        var p: DTypePointer[DType.uint8]
        var l: Int
        var tik = now()
        p, l = decode[zero_terminated=True](h1)
        var tok = now()
        assert_equal(text, String(p.bitcast[DType.int8](), l))
        if fast_min_d_dec > tok - tik:
            fast_min_d_dec = tok - tik
    
    print("Decode:", fast_min_d_dec / len(h1))
    _ = text
