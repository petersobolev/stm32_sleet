MEMORY
{
  FLASH (RX) : ORIGIN = 0x08000000, LENGTH = 256K
  RAM ( rxw ) : ORIGIN = 0x20000000, LENGTH = 16K
}
SECTIONS { 
       .text : { *(.text); } > FLASH

        . = 0x20000000; 
        .ram : { *(.ram) }  > RAM


}
