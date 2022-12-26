#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <signal.h>
#include <syscall.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/reg.h>
#include <sys/user.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>

#include "elf64.h"

#define ET_NONE 0 // No file type
#define ET_REL 1  // Relocatable file
#define ET_EXEC 2 // Executable file
#define ET_DYN 3  // Shared object file
#define ET_CORE 4 // Core file

#define SHN_UNDEF 0	 // Undefined section
#define SHT_SYMTAB 2 // Symbol table section
#define SHT_STRTAB 3 // String table section

#define STB_LOCAL 0	 // Local symbol
#define STB_GLOBAL 1 // Global symbol
#define STB_WEAK 2	 // Weak symbol

/* symbol_name		- The symbol (maybe function) we need to search for.
 * exe_file_name	- The file where we search the symbol in.
 * error_val		- If  1: A global symbol was found, and defined in the given executable.
 * 			- If -1: Symbol not found.
 *			- If -2: Only a local symbol was found.
 * 			- If -3: File is not an executable.
 * 			- If -4: The symbol was found, it is global, but it is not defined in the executable.
 * return value		- The address which the symbol_name will be loaded to, if the symbol was found and is global.
 */
unsigned long find_symbol(char *symbol_name, char *exe_file_name, int *error_val)
{
	// check the premisitions of the exe_file_name- if it is an executable.
	FILE *exe_file = fopen(exe_file_name, "r");
	if (exe_file == NULL)
	{
		*error_val = -5;
		return 0;
	}
	Elf64_Ehdr exe_header;
	fread(&exe_header, sizeof(Elf64_Ehdr), 1, exe_file);
	if (exe_header.e_type != ET_EXEC) // !!!not executable
	{
		*error_val = -3;
		fclose(exe_file);
		return 0;
	}
	// check if the symbol_name exists in the symbol table.
	// get all headers
	Elf64_Shdr *section_headers = malloc(sizeof(Elf64_Shdr) * exe_header.e_shnum);
	fseek(exe_file, exe_header.e_shoff, SEEK_SET);
	fread(section_headers, sizeof(Elf64_Shdr), exe_header.e_shnum, exe_file);

	// get values of symbol table and string table
	Elf64_Shdr *symbol_table = NULL;
	Elf64_Shdr *string_table = NULL;
        char hdr[9]; //we are searching for ".strtab"(7 chars + '\0' + extra one);
        hdr[8] = '\0'; // if a longer header name is read, we will put NULL terminator to avoid longer string read
	for (int i = 0; i < exe_header.e_shnum; i++)
	{
		if (section_headers[i].sh_type == SHT_SYMTAB)
		{
			symbol_table = &section_headers[i];
		}
		else if (section_headers[i].sh_type == SHT_STRTAB)
		{
    	               fseek(exe_file, section_headers[exe_header.e_shstrndx].sh_offset + section_headers[i].sh_name, SEEK_SET);
    	               fread(hdr, 8, 1, exe_file);
                       if(!strcmp(hdr, ".strtab"))
			 string_table = &section_headers[i];

		}
		if (symbol_table != NULL && string_table != NULL)
			break;
	}

	if (symbol_table == NULL || string_table == NULL)
	{
		*error_val = -6;
		free(section_headers);
		fclose(exe_file);
		return 0;
	}
	char *strings = malloc(string_table->sh_size);

	fseek(exe_file, string_table->sh_offset, SEEK_SET);
	fread(strings, string_table->sh_size, 1, exe_file);
        Elf64_Sym *symbols = malloc(symbol_table->sh_size);
        fseek(exe_file, symbol_table->sh_offset, SEEK_SET);
        fread(symbols, symbol_table->sh_entsize, symbol_table->sh_size / symbol_table->sh_entsize, exe_file);
	
	Elf64_Sym *symbol = NULL;

	for (int i = 0; i < symbol_table->sh_size / symbol_table->sh_entsize; i++)
	{
		if (strcmp(&strings[symbols[i].st_name], symbol_name) == 0)
		{
			symbol = &symbols[i];
			if (ELF64_ST_BIND(symbol->st_info) == STB_GLOBAL)
			{
				break;
			}
		}
	}
	if (symbol == NULL) // !!!symbol not found
	{
		*error_val = -1;
		free(section_headers);
		free(symbols);
		free(strings);
		fclose(exe_file);
		return 0;
	}
	// check if the symbol with this name is global.
	// if no - set error_val to -2 and return 0.

	if (ELF64_ST_BIND(symbol->st_info) != STB_GLOBAL) // !!!symbol is local
	{
		*error_val = -2;
		free(section_headers);
		free(symbols);
		free(strings);
		fclose(exe_file);
		return 0;
	}

	// if yes - check if the symbol is defined in the executable.
	// 				if no - set error_val to -4 and return 0.
	//				if yes - return the address of the symbol and set error_val to 1.

	if (symbol->st_shndx == SHN_UNDEF) // !!!symbol is global but not defined in the executable
	{
		*error_val = -4;
		free(section_headers);
		free(symbols);
		free(strings);
		fclose(exe_file);
		return 0;
	}

	*error_val = 1;
	unsigned long address = symbol->st_value;
	free(section_headers);
	free(symbols);
	free(strings);
	fclose(exe_file);
	return address;
}

int main(int argc, char *const argv[])
{
	int err = 0;
	unsigned long addr = find_symbol(argv[1], argv[2], &err);

	if (addr > 0)
		printf("%s will be loaded to 0x%lx\n", argv[1], addr);
	else if (err == -2)
		printf("%s is not a global symbol! :(\n", argv[1]);
	else if (err == -1)
		printf("%s not found!\n", argv[1]);
	else if (err == -3)
		printf("%s not an executable! :(\n", argv[2]);
	else if (err == -4)
		printf("%s is a global symbol, but will come from a shared library\n", argv[1]);
        return 0;
}