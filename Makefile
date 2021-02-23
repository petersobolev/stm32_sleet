TARGET = stm32_sleet

DEBUG = 1

BUILD_DIR = build
SRC_DIR = src

# optimization
#OPT = -Og
#OPT = -O1
OPT=

# cpu
CPU = -mcpu=cortex-m3

# mcu
MCU = $(CPU) -mthumb 

# compile gcc flags
#ASFLAGS = $(MCU) $(OPT) -Wall -fdata-sections -ffunction-sections
ASFLAGS = $(MCU) $(OPT)

ifeq ($(DEBUG), 1)
#ASFLAGS += -g -gdwarf-2
#ASFLAGS += -g3 -gdwarf-2
ASFLAGS += -g -gdwarf-2
#-ggdb
endif


# Generate dependency information
# CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


all:
#	arm-none-eabi-gcc -nostdlib -x assembler $(ASFLAGS) $(SRC_DIR)/$(TARGET).s -o $(BUILD_DIR)/$(TARGET).o
	arm-none-eabi-as $(ASFLAGS) -o $(BUILD_DIR)/$(TARGET).o $(SRC_DIR)/$(TARGET).s
	arm-none-eabi-ld -T stm32.ld -o $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).o
#  .ld file replaces "-Ttext 0x8000000"
	arm-none-eabi-objcopy -S -O binary $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin
#	arm-none-eabi-objcopy -O hex $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex
	arm-none-eabi-objdump --syms --disassemble $(BUILD_DIR)/$(TARGET).o

#	rm -rf '$(TARGET).o' '$(TARGET).elf'

clean:
#	-rm -fR $(BUILD_DIR)
#	rm -f *.o $(TARGET).elf $(TARGET).bin


#flash:
#	$(SF) write $(TARGET).bin 0x8000000
		