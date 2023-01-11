#include <stdio.h>

static int global_bss_and_local_bss_var;
static int global_bss_and_local_data_var = 10;
static int global_data_and_local_bss_var = 0;
static int global_data_and_local_data_var = 10;

void global_func();
static void global_and_local_func() { puts("Called local version"); }

void global_func()
{
    puts("Called global func");
    global_and_local_func();
}
