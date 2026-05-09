# create_nrfreq_table.py - Create memory init file for GameBoy NRx frequency table from MIDI note numbers

SB_RAM40_4K_inst_name = "SB_RAM40_4K_freq_table_inst"

A4_freq = 440.
A4_note_num = 69

note_numbers = [n / 2. for n in range(0, 256)]  # quarter tone steps for 24-TET table
NR_freqs = [round(2048. - (131072. / A4_freq) * (2. ** ((A4_note_num - n) / 12.))) for n in note_numbers]

for i in range(16):
    print("defparam {}.INIT_{:X} = 256'h".format(SB_RAM40_4K_inst_name, i), end="")
    for j in range(16):
        print("{:04X}".format(NR_freqs[(i*16)+(15-j)] & 0xFFFF), end="")
    print(";")
