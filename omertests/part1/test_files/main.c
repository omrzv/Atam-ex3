#include <stdio.h>

int global_bss_var;
int global_data_var = 10;
int global_bss_and_local_bss_var;
int global_bss_and_local_data_var;
int global_data_and_local_bss_var = 10;
int global_data_and_local_data_var = 10;
static int local_bss_var = 0;
static int local_data_var = 10;

void global_func();
void global_and_local_func() { puts("Called global version"); }
static void local_func() { puts("Called local func"); }

int main(int argc, char *argv[])
{
    global_bss_var = argc;
    global_data_var = argc;
    global_bss_and_local_bss_var = argc;
    global_bss_and_local_data_var = argc;
    global_data_and_local_bss_var = argc;
    global_data_and_local_data_var = argc;
    local_bss_var = argc;
    local_data_var = argc;
    global_func();
    global_and_local_func();
    local_func();
    for (int i = 0; i < argc; i++)
    {
        printf("argv[%d]=%s\n", i, argv[i]);
    }
}
