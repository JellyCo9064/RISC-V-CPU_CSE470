if __name__ == "__main__":
    signals = ["TOP.core.decode_inst[96:0]"
              ,"TOP.core.exec_inst[96:0]"
              ,"TOP.core.mem_inst[96:0]"
              ,"TOP.core.wb_inst[96:0]"]
    comps = [("is_pb", (0, 0))
            ,("addr", (1, 32))
            ,("opcode", (33, 39))
            ,("funct3", (40, 42))
            ,("rd", (43, 47))
            ,("rs1", (48, 52))
            ,("rs2", (53, 57))
            ,("funct7", (58, 64))
            ,("imm", (65, 96))]  # ("name", (range_start, range_end))

    file = open("wave_save.txt", "w")

    for s in signals:
        for i in range(len(comps)):
            if i == 1:
                file.write("@800028\n")
            else:
                file.write("@800022\n")

            if i == 0:
                file.write(f'{s}\n')
            
            file.write(f'#{{{comps[i][0]}}}')
            
            for b in range(comps[i][1][0], comps[i][1][1] + 1, 1):
                file.write(f' ({b}){s}')
            file.write("\n")

            file.write("@1001200\n")

            file.write("-group_end\n")

        file.write("-group_end\n")
        file.write("@200\n-\n")
        

    file.close()