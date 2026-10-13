#include <stdio.h>
#include "stdio_shims.h"

void crypto_mcp_unbuffer_stdio(void) {
    setbuf(stdin, NULL);
    setbuf(stdout, NULL);
}
