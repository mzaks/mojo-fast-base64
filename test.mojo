from fast_base64 import encode, decode
from base64 import b64encode
from testing import assert_equal
from samples import mobi_dick_plain, mobi_dick_base64

fn b64(s: String) raises:
    let b = encode(s)
    assert_equal(b, b64encode(s))
    let p: DTypePointer[DType.uint8]
    let length: Int
    p, length = decode[zero_terminated=True](b)
    if len(s) == 0 and length == 0:
        return
    let decoded_s = String(p.bitcast[DType.int8](), length)
    assert_equal(s, decoded_s)

fn main() raises:
    b64("hello world")
    b64("")
    b64("h")
    b64("ha")
    b64("hal")
    b64("halo")

    let b_chromium = encode(mobi_dick_plain)
    let b_std = b64encode(mobi_dick_plain)
    assert_equal(b_chromium, mobi_dick_base64)
    assert_equal(b_std, mobi_dick_base64)

    let p: DTypePointer[DType.uint8]
    let l: Int
    p, l = decode[True](mobi_dick_base64)
    assert_equal(mobi_dick_plain, String(p.bitcast[DType.int8](), l))
