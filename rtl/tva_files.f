# rtl/tva_files.f -- 소스 리스트 단일 출처
#
# iverilog:  iverilog -g2005 -f rtl/tva_files.f verification/tb/tb_tva_top.v
# Vivado:    read_verilog [glob rtl/*.v]  또는 이 파일을 파싱해서 사용
#
# 경로는 저장소 루트 기준이다.

+incdir+rtl/include

# leaf
rtl/tva_bram.v
rtl/tva_mac_array.v
rtl/tva_vregfile.v
rtl/tva_accfile.v

# 실행 / 제어
rtl/tva_decode.v
rtl/tva_vdot.v
rtl/tva_ctrl.v

# 결선
rtl/tva_imem.v
rtl/tva_dmem.v
rtl/tva_core.v
rtl/tva_top.v
