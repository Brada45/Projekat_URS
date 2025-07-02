setenv linux_load_address 0x01000000
setenv linux_dtb_load_address 0x02000000
setenv fpgadata 0x03000000
setenv linux_dtb socfpga_cyclone5_de1_soc.dtb
setenv fpgaintf ffd08028
setenv fpgaintf_handoff 0x00000000
setenv fpga2sdram ffc25080
setenv fpga2sdram_handoff 0x00000000
setenv fpga2sdram_apply 3ff795a4
setenv axibridge ffd0501c
setenv axibridge_handoff 0x00000000
setenv l3remap ff800000
setenv l3remap_handoff 0x00000019

setenv bridge_enable_handoff 'mw $fpgaintf $fpgaintf_handoff; mw $axibridge $axibridge_handoff; mw $l3remap $l3remap_handoff'

setenv fpga_load 'mmc rescan; fatload mmc 0:1 $fpgadata socfpga.rbf; fpga load 0 $fpgadata $filesize'

setenv linux_load 'mmc rescan; fatload mmc 0:1 ${linux_load_address} zImage; fatload mmc 0:1 ${linux_dtb_load_address} ${linux_dtb}'

setenv bootargs 'console=ttyS0,115200 root=/dev/mmcblk0p3 rw rootwait'

setenv bootcmd 'run fpga_load; run bridge_enable_handoff; run linux_load; bootz ${linux_load_address} - ${linux_dtb_load_address}'

setenv bootdelay 1

saveenv
boot
