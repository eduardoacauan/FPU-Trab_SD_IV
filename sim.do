if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

vlog -work work package.sv
vlog -work work main.sv
vlog -work work tb_fpu.sv

vsim -voptargs=+acc work.FPU_tb

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do
run 250us