# Fast Base64 written in Mojo

This project is an adoptation of https://github.com/lemire/fastbase64 project.

Currently we adopted only the chromium base64 alogirth, which is already about 5x faster than the Mojo standard library b64encode function.

In the future we aim at adopting the SIMD based algorithm and hope for further speedups.