/*
    Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
    SPDX-License-Identifier: MIT
*/

/*
    Define a 16 bytes long section for update purposes
*/
SECTIONS
{
    .update_custom_section 0x2003FFD0 (NOLOAD): 
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN (__update_custom_section_start = .);
        KEEP(*(.update_custom_section))
        PROVIDE_HIDDEN (__update_custom_section_end = .);
    } > RAM 

    . = __update_custom_section_start + 16;
}

/*
    Define a 32 bytes long section for unit test purposes
*/
SECTIONS
{
    .utest_custom_section 0x2003FFE0 (NOLOAD): 
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN (__utest_custom_section_start = .);
        KEEP(*(.utest_custom_section))
        PROVIDE_HIDDEN (__utest_custom_section_end = .);
    } > RAM 

    . = __utest_custom_section_start + 32;
}
