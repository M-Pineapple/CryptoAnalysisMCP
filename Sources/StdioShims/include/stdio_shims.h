#ifndef STDIO_SHIMS_H
#define STDIO_SHIMS_H

/// Turn off libc buffering for stdin and stdout.
///
/// MCP speaks newline-delimited JSON on stdio. Swift 6 rejects direct use of
/// the `stdin` and `stdout` globals from concurrent code, so the unbuffered
/// setup lives in C where those globals are ordinary file pointers.
void crypto_mcp_unbuffer_stdio(void);

#endif
