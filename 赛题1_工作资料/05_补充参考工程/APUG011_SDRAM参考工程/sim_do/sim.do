set work work
vlib work

cd F:/app/anlogic_app_demo/each_app/memory/sdram_as_ram/sim_do
set INCLUDE_PATH F:/app/anlogic_app_demo/each_app/memory/sdram_as_ram/source_code/include


##anlogic_lib
vmap al   D:/lib/anlogic/al
vmap ef2  D:/lib/anlogic/ef2
vmap ef3  D:/lib/anlogic/ef3
vmap eg   D:/lib/anlogic/eg
vmap elf  D:/lib/anlogic/elf
vmap ph1  D:/lib/anlogic/ph1


#将include文件单独放在一个文件夹，并指定incdir指向该文件夹，rtl文件夹中不能含有参数include文件，编译有包含include文件夹时，必须有参数incdir，如果.V文件中只有参数，则此.V文件只能作为include包含进来，不能直接编译
#vlog -incr +incdir+$INCLUDE_PATH ../include/*.v
##添加VHDL
#vcom ./flash_src/*.vhd

vlog -work work +incdir+$INCLUDE_PATH +define+SIMULATION ../source_code/*.v
vlog -incr +incdir+$INCLUDE_PATH ../source_code/rtl/enc_file/*.v
vlog -incr +incdir+$INCLUDE_PATH ../source_code/model/*.v
vlog -incr +incdir+$INCLUDE_PATH +define+SIMULATION ../source_code/tb/*.v
vlog -incr +incdir+$INCLUDE_PATH +define+SIMULATION ../prj/al_ip/*_sim.v

vsim -t ps -voptargs="+acc" +transport_int_delays+transport_path_delay+notimingchecks -L al -L eg work.tb work.glbl
view wave signals

log -r /*
do wave.do
radix unsigned

run 4000ms
stop
