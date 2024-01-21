from .chromium import _encode
from math import bitcast
from math import rotate_bits_left

@always_inline
fn encode(input: StringLiteral) -> String:
    return encode(input.data().bitcast[DType.uint8](), len(input))

@always_inline
fn encode(input: String) -> String:
    return encode(input._as_ptr().bitcast[DType.uint8](), len(input))

@always_inline
fn encode(input: Tensor) -> String:
    return encode(input.data().bitcast[DType.uint8](), input.bytecount())

@always_inline
fn encode(input: DTypePointer[DType.uint8], length: Int) -> String:
    let data = input
    let result_size = (length + 2) // 3 * 4 + 1
    let result = DTypePointer[DType.int8].aligned_alloc(4, result_size)
    var offset = 0
    var cursor = result.bitcast[DType.uint8]()
    alias simd_width = 32
    while length - offset >= simd_width:
        let a = data.simd_load[simd_width](offset)
        # aaaaaabb bbbbcccc ccdddddd ________
        let b = a.shuffle[
            1, 0, 2, 1, 
            4, 3, 5, 4,
            7, 6, 8, 7,
            10, 9, 11, 10,
            13, 12, 14, 13, 
            16, 15, 17, 16,
            19, 18, 20, 19,
            22, 21, 23, 22,
        ]()
        # bbbbcccc aaaaaabb ccdddddd bbbbcccc
        
        offset += (simd_width >> 2) * 3

        let c = bitcast[DType.uint16, simd_width >> 1](b)

        let d = c.deinterleave()
        # d[0] = bbbbcccc aaaaaabb
        # d[1] = ccdddddd bbbbcccc

        # TODO: this implementaiton is for little endian only add big endian support

        let d1 = rotate_bits_left[6](d[0]).cast[DType.uint8]()
        # d1 = ccaaaaaa
        let d2 = rotate_bits_left[12](d[0]).cast[DType.uint8]()
        # d2 = aabbbbbb
        let d3 = rotate_bits_left[10](d[1]).cast[DType.uint8]()
        # d3 = bbcccccc
        let d4 = d[1].cast[DType.uint8]()
        # d4 = ccdddddd

        let e1 = d1.interleave(d3)
        # e1 = ccaaaaaa bbcccccc
        let e2 = d2.interleave(d4)
        # e2 = aabbbbbb ccdddddd
        let e3 = e1.interleave(e2) & 0b0011_1111
        # e3 = 00aaaaaa 00bbbbbb 00cccccc 00dddddd

        let upper = e3 < 26
        let lower = (e3 > 25) & (e3 < 52)
        let nums = (e3 > 51) & (e3 < 62)
        let plus = e3 == 62
        let slash = e3 == 63

        let f1 = upper.select(e3 + 65, 0)
        let f2 = lower.select(e3 + 71, 0)
        let f3 = nums.select(e3 - 4, 0)
        let f4 = plus.select(e3 - 19, 0)
        let f5 = slash.select(e3 - 16, 0)

        #  0 .. 25 -> 65 .. 90    (+65) A .. Z
        # 26 .. 51 -> 97 .. 122   (+71) a .. z
        # 52 .. 61 -> 48 .. 57    (-4)  0 .. 9
        # 62       -> 43          (-19) +
        # 63       -> 47          (-16) /

        cursor.simd_nt_store(0, f1 + f2 + f3 + f4 + f5)

        cursor = cursor.offset(simd_width)

    if length > offset:
        _encode(data.offset(offset), length - offset, cursor)

    result.store(result_size - 1, 0)
    return String(result, result_size)
