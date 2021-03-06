module weight_memory1 #(
    parameter NWBITS=16, 
    parameter NPIXEL=784,
    parameter COUNT_BIT1=10,
    parameter NUM=0) (
    input clk,                             // external clk
    input reset_b,                         // asynchronous reset
    input update_weight,                   // update weight of state [6] 
    input start_state1,                    // start_state1 signal
    input signed [NWBITS-1:0] delta_weight,  // delta_weight
    output signed [NWBITS-1:0] first_layer_weight,
    output end_state6,                     // end state6
    output start_multiply                   // start signal of bias module
);

/* state constant */
localparam [1:0] WAIT    = 2'b00,    // waiting for start_state1
                 UPDATE  = 2'b01,    // update weight state
                 OUTPUT  = 2'b10;    // printed out weight for weighted sum

/* output register declaration */
reg signed [NWBITS-1:0] first_layer_weight_reg;
reg start_multiply_reg;
reg end_state6_reg;

/* internal register data declaration */
reg signed [NWBITS-1:0] weight_memory[NPIXEL-1:0];  // memory
reg [1:0] state;                      
reg [COUNT_BIT1-1:0] counter;        // memory counter(0 ~ 783)

initial
begin: MEM_INIT
    if (NUM == 0) $readmemh("weight_value/weight_memory1_0.txt", weight_memory);
    if (NUM == 1) $readmemh("weight_value/weight_memory1_1.txt", weight_memory);
    if (NUM == 2) $readmemh("weight_value/weight_memory1_2.txt", weight_memory);
    if (NUM == 3) $readmemh("weight_value/weight_memory1_3.txt", weight_memory);
    if (NUM == 4) $readmemh("weight_value/weight_memory1_4.txt", weight_memory);
    if (NUM == 5) $readmemh("weight_value/weight_memory1_5.txt", weight_memory);
    if (NUM == 6) $readmemh("weight_value/weight_memory1_6.txt", weight_memory);
    if (NUM == 7) $readmemh("weight_value/weight_memory1_7.txt", weight_memory);
    if (NUM == 8) $readmemh("weight_value/weight_memory1_8.txt", weight_memory);
    if (NUM == 9) $readmemh("weight_value/weight_memory1_9.txt", weight_memory);
    if (NUM == 10) $readmemh("weight_value/weight_memory1_10.txt", weight_memory);
    if (NUM == 11) $readmemh("weight_value/weight_memory1_11.txt", weight_memory);
    if (NUM == 12) $readmemh("weight_value/weight_memory1_12.txt", weight_memory);
    if (NUM == 13) $readmemh("weight_value/weight_memory1_13.txt", weight_memory);
    if (NUM == 14) $readmemh("weight_value/weight_memory1_14.txt", weight_memory);
    if (NUM == 15) $readmemh("weight_value/weight_memory1_15.txt", weight_memory);
    if (NUM == 16) $readmemh("weight_value/weight_memory1_16.txt", weight_memory);
    if (NUM == 17) $readmemh("weight_value/weight_memory1_17.txt", weight_memory);
    if (NUM == 18) $readmemh("weight_value/weight_memory1_18.txt", weight_memory);
    if (NUM == 19) $readmemh("weight_value/weight_memory1_19.txt", weight_memory);
    if (NUM == 20) $readmemh("weight_value/weight_memory1_20.txt", weight_memory);
    if (NUM == 21) $readmemh("weight_value/weight_memory1_21.txt", weight_memory);
    if (NUM == 22) $readmemh("weight_value/weight_memory1_22.txt", weight_memory);
    if (NUM == 23) $readmemh("weight_value/weight_memory1_23.txt", weight_memory);
    if (NUM == 24) $readmemh("weight_value/weight_memory1_24.txt", weight_memory);
    if (NUM == 25) $readmemh("weight_value/weight_memory1_25.txt", weight_memory);
    if (NUM == 26) $readmemh("weight_value/weight_memory1_26.txt", weight_memory);
    if (NUM == 27) $readmemh("weight_value/weight_memory1_27.txt", weight_memory);
    if (NUM == 28) $readmemh("weight_value/weight_memory1_28.txt", weight_memory);
    if (NUM == 29) $readmemh("weight_value/weight_memory1_29.txt", weight_memory);
    if (NUM == 30) $readmemh("weight_value/weight_memory1_30.txt", weight_memory);
    if (NUM == 31) $readmemh("weight_value/weight_memory1_31.txt", weight_memory);
    if (NUM == 32) $readmemh("weight_value/weight_memory1_32.txt", weight_memory);
    if (NUM == 33) $readmemh("weight_value/weight_memory1_33.txt", weight_memory);
    if (NUM == 34) $readmemh("weight_value/weight_memory1_34.txt", weight_memory);
    if (NUM == 35) $readmemh("weight_value/weight_memory1_35.txt", weight_memory);
    if (NUM == 36) $readmemh("weight_value/weight_memory1_36.txt", weight_memory);
    if (NUM == 37) $readmemh("weight_value/weight_memory1_37.txt", weight_memory);
    if (NUM == 38) $readmemh("weight_value/weight_memory1_38.txt", weight_memory);
    if (NUM == 39) $readmemh("weight_value/weight_memory1_39.txt", weight_memory);
    if (NUM == 40) $readmemh("weight_value/weight_memory1_40.txt", weight_memory);
    if (NUM == 41) $readmemh("weight_value/weight_memory1_41.txt", weight_memory);
    if (NUM == 42) $readmemh("weight_value/weight_memory1_42.txt", weight_memory);
    if (NUM == 43) $readmemh("weight_value/weight_memory1_43.txt", weight_memory);
    if (NUM == 44) $readmemh("weight_value/weight_memory1_44.txt", weight_memory);
    if (NUM == 45) $readmemh("weight_value/weight_memory1_45.txt", weight_memory);
    if (NUM == 46) $readmemh("weight_value/weight_memory1_46.txt", weight_memory);
    if (NUM == 47) $readmemh("weight_value/weight_memory1_47.txt", weight_memory);
    if (NUM == 48) $readmemh("weight_value/weight_memory1_48.txt", weight_memory);
    if (NUM == 49) $readmemh("weight_value/weight_memory1_49.txt", weight_memory);
    if (NUM == 50) $readmemh("weight_value/weight_memory1_50.txt", weight_memory);
    if (NUM == 51) $readmemh("weight_value/weight_memory1_51.txt", weight_memory);
    if (NUM == 52) $readmemh("weight_value/weight_memory1_52.txt", weight_memory);
    if (NUM == 53) $readmemh("weight_value/weight_memory1_53.txt", weight_memory);
    if (NUM == 54) $readmemh("weight_value/weight_memory1_54.txt", weight_memory);
    if (NUM == 55) $readmemh("weight_value/weight_memory1_55.txt", weight_memory);
    if (NUM == 56) $readmemh("weight_value/weight_memory1_56.txt", weight_memory);
    if (NUM == 57) $readmemh("weight_value/weight_memory1_57.txt", weight_memory);
    if (NUM == 58) $readmemh("weight_value/weight_memory1_58.txt", weight_memory);
    if (NUM == 59) $readmemh("weight_value/weight_memory1_59.txt", weight_memory);
    if (NUM == 60) $readmemh("weight_value/weight_memory1_60.txt", weight_memory);
    if (NUM == 61) $readmemh("weight_value/weight_memory1_61.txt", weight_memory);
    if (NUM == 62) $readmemh("weight_value/weight_memory1_62.txt", weight_memory);
    if (NUM == 63) $readmemh("weight_value/weight_memory1_63.txt", weight_memory);
    if (NUM == 64) $readmemh("weight_value/weight_memory1_64.txt", weight_memory);
    if (NUM == 65) $readmemh("weight_value/weight_memory1_65.txt", weight_memory);
    if (NUM == 66) $readmemh("weight_value/weight_memory1_66.txt", weight_memory);
    if (NUM == 67) $readmemh("weight_value/weight_memory1_67.txt", weight_memory);
    if (NUM == 68) $readmemh("weight_value/weight_memory1_68.txt", weight_memory);
    if (NUM == 69) $readmemh("weight_value/weight_memory1_69.txt", weight_memory);
    if (NUM == 70) $readmemh("weight_value/weight_memory1_70.txt", weight_memory);
    if (NUM == 71) $readmemh("weight_value/weight_memory1_71.txt", weight_memory);
    if (NUM == 72) $readmemh("weight_value/weight_memory1_72.txt", weight_memory);
    if (NUM == 73) $readmemh("weight_value/weight_memory1_73.txt", weight_memory);
    if (NUM == 74) $readmemh("weight_value/weight_memory1_74.txt", weight_memory);
    if (NUM == 75) $readmemh("weight_value/weight_memory1_75.txt", weight_memory);
    if (NUM == 76) $readmemh("weight_value/weight_memory1_76.txt", weight_memory);
    if (NUM == 77) $readmemh("weight_value/weight_memory1_77.txt", weight_memory);
    if (NUM == 78) $readmemh("weight_value/weight_memory1_78.txt", weight_memory);
    if (NUM == 79) $readmemh("weight_value/weight_memory1_79.txt", weight_memory);
    if (NUM == 80) $readmemh("weight_value/weight_memory1_80.txt", weight_memory);
    if (NUM == 81) $readmemh("weight_value/weight_memory1_81.txt", weight_memory);
    if (NUM == 82) $readmemh("weight_value/weight_memory1_82.txt", weight_memory);
    if (NUM == 83) $readmemh("weight_value/weight_memory1_83.txt", weight_memory);
    if (NUM == 84) $readmemh("weight_value/weight_memory1_84.txt", weight_memory);
    if (NUM == 85) $readmemh("weight_value/weight_memory1_85.txt", weight_memory);
    if (NUM == 86) $readmemh("weight_value/weight_memory1_86.txt", weight_memory);
    if (NUM == 87) $readmemh("weight_value/weight_memory1_87.txt", weight_memory);
    if (NUM == 88) $readmemh("weight_value/weight_memory1_88.txt", weight_memory);
    if (NUM == 89) $readmemh("weight_value/weight_memory1_89.txt", weight_memory);
    if (NUM == 90) $readmemh("weight_value/weight_memory1_90.txt", weight_memory);
    if (NUM == 91) $readmemh("weight_value/weight_memory1_91.txt", weight_memory);
    if (NUM == 92) $readmemh("weight_value/weight_memory1_92.txt", weight_memory);
    if (NUM == 93) $readmemh("weight_value/weight_memory1_93.txt", weight_memory);
    if (NUM == 94) $readmemh("weight_value/weight_memory1_94.txt", weight_memory);
    if (NUM == 95) $readmemh("weight_value/weight_memory1_95.txt", weight_memory);
    if (NUM == 96) $readmemh("weight_value/weight_memory1_96.txt", weight_memory);
    if (NUM == 97) $readmemh("weight_value/weight_memory1_97.txt", weight_memory);
    if (NUM == 98) $readmemh("weight_value/weight_memory1_98.txt", weight_memory);
    if (NUM == 99) $readmemh("weight_value/weight_memory1_99.txt", weight_memory);
    if (NUM == 100) $readmemh("weight_value/weight_memory1_100.txt", weight_memory);
    if (NUM == 101) $readmemh("weight_value/weight_memory1_101.txt", weight_memory);
    if (NUM == 102) $readmemh("weight_value/weight_memory1_102.txt", weight_memory);
    if (NUM == 103) $readmemh("weight_value/weight_memory1_103.txt", weight_memory);
    if (NUM == 104) $readmemh("weight_value/weight_memory1_104.txt", weight_memory);
    if (NUM == 105) $readmemh("weight_value/weight_memory1_105.txt", weight_memory);
    if (NUM == 106) $readmemh("weight_value/weight_memory1_106.txt", weight_memory);
    if (NUM == 107) $readmemh("weight_value/weight_memory1_107.txt", weight_memory);
    if (NUM == 108) $readmemh("weight_value/weight_memory1_108.txt", weight_memory);
    if (NUM == 109) $readmemh("weight_value/weight_memory1_109.txt", weight_memory);
    if (NUM == 110) $readmemh("weight_value/weight_memory1_110.txt", weight_memory);
    if (NUM == 111) $readmemh("weight_value/weight_memory1_111.txt", weight_memory);
    if (NUM == 112) $readmemh("weight_value/weight_memory1_112.txt", weight_memory);
    if (NUM == 113) $readmemh("weight_value/weight_memory1_113.txt", weight_memory);
    if (NUM == 114) $readmemh("weight_value/weight_memory1_114.txt", weight_memory);
    if (NUM == 115) $readmemh("weight_value/weight_memory1_115.txt", weight_memory);
    if (NUM == 116) $readmemh("weight_value/weight_memory1_116.txt", weight_memory);
    if (NUM == 117) $readmemh("weight_value/weight_memory1_117.txt", weight_memory);
    if (NUM == 118) $readmemh("weight_value/weight_memory1_118.txt", weight_memory);
    if (NUM == 119) $readmemh("weight_value/weight_memory1_119.txt", weight_memory);
    if (NUM == 120) $readmemh("weight_value/weight_memory1_120.txt", weight_memory);
    if (NUM == 121) $readmemh("weight_value/weight_memory1_121.txt", weight_memory);
    if (NUM == 122) $readmemh("weight_value/weight_memory1_122.txt", weight_memory);
    if (NUM == 123) $readmemh("weight_value/weight_memory1_123.txt", weight_memory);
    if (NUM == 124) $readmemh("weight_value/weight_memory1_124.txt", weight_memory);
    if (NUM == 125) $readmemh("weight_value/weight_memory1_125.txt", weight_memory);
    if (NUM == 126) $readmemh("weight_value/weight_memory1_126.txt", weight_memory);
    if (NUM == 127) $readmemh("weight_value/weight_memory1_127.txt", weight_memory);
    if (NUM == 128) $readmemh("weight_value/weight_memory1_128.txt", weight_memory);
    if (NUM == 129) $readmemh("weight_value/weight_memory1_129.txt", weight_memory);
    if (NUM == 130) $readmemh("weight_value/weight_memory1_130.txt", weight_memory);
    if (NUM == 131) $readmemh("weight_value/weight_memory1_131.txt", weight_memory);
    if (NUM == 132) $readmemh("weight_value/weight_memory1_132.txt", weight_memory);
    if (NUM == 133) $readmemh("weight_value/weight_memory1_133.txt", weight_memory);
    if (NUM == 134) $readmemh("weight_value/weight_memory1_134.txt", weight_memory);
    if (NUM == 135) $readmemh("weight_value/weight_memory1_135.txt", weight_memory);
    if (NUM == 136) $readmemh("weight_value/weight_memory1_136.txt", weight_memory);
    if (NUM == 137) $readmemh("weight_value/weight_memory1_137.txt", weight_memory);
    if (NUM == 138) $readmemh("weight_value/weight_memory1_138.txt", weight_memory);
    if (NUM == 139) $readmemh("weight_value/weight_memory1_139.txt", weight_memory);
    if (NUM == 140) $readmemh("weight_value/weight_memory1_140.txt", weight_memory);
    if (NUM == 141) $readmemh("weight_value/weight_memory1_141.txt", weight_memory);
    if (NUM == 142) $readmemh("weight_value/weight_memory1_142.txt", weight_memory);
    if (NUM == 143) $readmemh("weight_value/weight_memory1_143.txt", weight_memory);
    if (NUM == 144) $readmemh("weight_value/weight_memory1_144.txt", weight_memory);
    if (NUM == 145) $readmemh("weight_value/weight_memory1_145.txt", weight_memory);
    if (NUM == 146) $readmemh("weight_value/weight_memory1_146.txt", weight_memory);
    if (NUM == 147) $readmemh("weight_value/weight_memory1_147.txt", weight_memory);
    if (NUM == 148) $readmemh("weight_value/weight_memory1_148.txt", weight_memory);
    if (NUM == 149) $readmemh("weight_value/weight_memory1_149.txt", weight_memory);
    if (NUM == 150) $readmemh("weight_value/weight_memory1_150.txt", weight_memory);
    if (NUM == 151) $readmemh("weight_value/weight_memory1_151.txt", weight_memory);
    if (NUM == 152) $readmemh("weight_value/weight_memory1_152.txt", weight_memory);
    if (NUM == 153) $readmemh("weight_value/weight_memory1_153.txt", weight_memory);
    if (NUM == 154) $readmemh("weight_value/weight_memory1_154.txt", weight_memory);
    if (NUM == 155) $readmemh("weight_value/weight_memory1_155.txt", weight_memory);
    if (NUM == 156) $readmemh("weight_value/weight_memory1_156.txt", weight_memory);
    if (NUM == 157) $readmemh("weight_value/weight_memory1_157.txt", weight_memory);
    if (NUM == 158) $readmemh("weight_value/weight_memory1_158.txt", weight_memory);
    if (NUM == 159) $readmemh("weight_value/weight_memory1_159.txt", weight_memory);
    if (NUM == 160) $readmemh("weight_value/weight_memory1_160.txt", weight_memory);
    if (NUM == 161) $readmemh("weight_value/weight_memory1_161.txt", weight_memory);
    if (NUM == 162) $readmemh("weight_value/weight_memory1_162.txt", weight_memory);
    if (NUM == 163) $readmemh("weight_value/weight_memory1_163.txt", weight_memory);
    if (NUM == 164) $readmemh("weight_value/weight_memory1_164.txt", weight_memory);
    if (NUM == 165) $readmemh("weight_value/weight_memory1_165.txt", weight_memory);
    if (NUM == 166) $readmemh("weight_value/weight_memory1_166.txt", weight_memory);
    if (NUM == 167) $readmemh("weight_value/weight_memory1_167.txt", weight_memory);
    if (NUM == 168) $readmemh("weight_value/weight_memory1_168.txt", weight_memory);
    if (NUM == 169) $readmemh("weight_value/weight_memory1_169.txt", weight_memory);
    if (NUM == 170) $readmemh("weight_value/weight_memory1_170.txt", weight_memory);
    if (NUM == 171) $readmemh("weight_value/weight_memory1_171.txt", weight_memory);
    if (NUM == 172) $readmemh("weight_value/weight_memory1_172.txt", weight_memory);
    if (NUM == 173) $readmemh("weight_value/weight_memory1_173.txt", weight_memory);
    if (NUM == 174) $readmemh("weight_value/weight_memory1_174.txt", weight_memory);
    if (NUM == 175) $readmemh("weight_value/weight_memory1_175.txt", weight_memory);
    if (NUM == 176) $readmemh("weight_value/weight_memory1_176.txt", weight_memory);
    if (NUM == 177) $readmemh("weight_value/weight_memory1_177.txt", weight_memory);
    if (NUM == 178) $readmemh("weight_value/weight_memory1_178.txt", weight_memory);
    if (NUM == 179) $readmemh("weight_value/weight_memory1_179.txt", weight_memory);
    if (NUM == 180) $readmemh("weight_value/weight_memory1_180.txt", weight_memory);
    if (NUM == 181) $readmemh("weight_value/weight_memory1_181.txt", weight_memory);
    if (NUM == 182) $readmemh("weight_value/weight_memory1_182.txt", weight_memory);
    if (NUM == 183) $readmemh("weight_value/weight_memory1_183.txt", weight_memory);
    if (NUM == 184) $readmemh("weight_value/weight_memory1_184.txt", weight_memory);
    if (NUM == 185) $readmemh("weight_value/weight_memory1_185.txt", weight_memory);
    if (NUM == 186) $readmemh("weight_value/weight_memory1_186.txt", weight_memory);
    if (NUM == 187) $readmemh("weight_value/weight_memory1_187.txt", weight_memory);
    if (NUM == 188) $readmemh("weight_value/weight_memory1_188.txt", weight_memory);
    if (NUM == 189) $readmemh("weight_value/weight_memory1_189.txt", weight_memory);
    if (NUM == 190) $readmemh("weight_value/weight_memory1_190.txt", weight_memory);
    if (NUM == 191) $readmemh("weight_value/weight_memory1_191.txt", weight_memory);
    if (NUM == 192) $readmemh("weight_value/weight_memory1_192.txt", weight_memory);
    if (NUM == 193) $readmemh("weight_value/weight_memory1_193.txt", weight_memory);
    if (NUM == 194) $readmemh("weight_value/weight_memory1_194.txt", weight_memory);
    if (NUM == 195) $readmemh("weight_value/weight_memory1_195.txt", weight_memory);
    if (NUM == 196) $readmemh("weight_value/weight_memory1_196.txt", weight_memory);
    if (NUM == 197) $readmemh("weight_value/weight_memory1_197.txt", weight_memory);
    if (NUM == 198) $readmemh("weight_value/weight_memory1_198.txt", weight_memory);
    if (NUM == 199) $readmemh("weight_value/weight_memory1_199.txt", weight_memory);
    if (NUM == 200) $readmemh("weight_value/weight_memory1_200.txt", weight_memory);
    if (NUM == 201) $readmemh("weight_value/weight_memory1_201.txt", weight_memory);
    if (NUM == 202) $readmemh("weight_value/weight_memory1_202.txt", weight_memory);
    if (NUM == 203) $readmemh("weight_value/weight_memory1_203.txt", weight_memory);
    if (NUM == 204) $readmemh("weight_value/weight_memory1_204.txt", weight_memory);
    if (NUM == 205) $readmemh("weight_value/weight_memory1_205.txt", weight_memory);
    if (NUM == 206) $readmemh("weight_value/weight_memory1_206.txt", weight_memory);
    if (NUM == 207) $readmemh("weight_value/weight_memory1_207.txt", weight_memory);
    if (NUM == 208) $readmemh("weight_value/weight_memory1_208.txt", weight_memory);
    if (NUM == 209) $readmemh("weight_value/weight_memory1_209.txt", weight_memory);
    if (NUM == 210) $readmemh("weight_value/weight_memory1_210.txt", weight_memory);
    if (NUM == 211) $readmemh("weight_value/weight_memory1_211.txt", weight_memory);
    if (NUM == 212) $readmemh("weight_value/weight_memory1_212.txt", weight_memory);
    if (NUM == 213) $readmemh("weight_value/weight_memory1_213.txt", weight_memory);
    if (NUM == 214) $readmemh("weight_value/weight_memory1_214.txt", weight_memory);
    if (NUM == 215) $readmemh("weight_value/weight_memory1_215.txt", weight_memory);
    if (NUM == 216) $readmemh("weight_value/weight_memory1_216.txt", weight_memory);
    if (NUM == 217) $readmemh("weight_value/weight_memory1_217.txt", weight_memory);
    if (NUM == 218) $readmemh("weight_value/weight_memory1_218.txt", weight_memory);
    if (NUM == 219) $readmemh("weight_value/weight_memory1_219.txt", weight_memory);
    if (NUM == 220) $readmemh("weight_value/weight_memory1_220.txt", weight_memory);
    if (NUM == 221) $readmemh("weight_value/weight_memory1_221.txt", weight_memory);
    if (NUM == 222) $readmemh("weight_value/weight_memory1_222.txt", weight_memory);
    if (NUM == 223) $readmemh("weight_value/weight_memory1_223.txt", weight_memory);
    if (NUM == 224) $readmemh("weight_value/weight_memory1_224.txt", weight_memory);
    if (NUM == 225) $readmemh("weight_value/weight_memory1_225.txt", weight_memory);
    if (NUM == 226) $readmemh("weight_value/weight_memory1_226.txt", weight_memory);
    if (NUM == 227) $readmemh("weight_value/weight_memory1_227.txt", weight_memory);
    if (NUM == 228) $readmemh("weight_value/weight_memory1_228.txt", weight_memory);
    if (NUM == 229) $readmemh("weight_value/weight_memory1_229.txt", weight_memory);
    if (NUM == 230) $readmemh("weight_value/weight_memory1_230.txt", weight_memory);
    if (NUM == 231) $readmemh("weight_value/weight_memory1_231.txt", weight_memory);
    if (NUM == 232) $readmemh("weight_value/weight_memory1_232.txt", weight_memory);
    if (NUM == 233) $readmemh("weight_value/weight_memory1_233.txt", weight_memory);
    if (NUM == 234) $readmemh("weight_value/weight_memory1_234.txt", weight_memory);
    if (NUM == 235) $readmemh("weight_value/weight_memory1_235.txt", weight_memory);
    if (NUM == 236) $readmemh("weight_value/weight_memory1_236.txt", weight_memory);
    if (NUM == 237) $readmemh("weight_value/weight_memory1_237.txt", weight_memory);
    if (NUM == 238) $readmemh("weight_value/weight_memory1_238.txt", weight_memory);
    if (NUM == 239) $readmemh("weight_value/weight_memory1_239.txt", weight_memory);
    if (NUM == 240) $readmemh("weight_value/weight_memory1_240.txt", weight_memory);
    if (NUM == 241) $readmemh("weight_value/weight_memory1_241.txt", weight_memory);
    if (NUM == 242) $readmemh("weight_value/weight_memory1_242.txt", weight_memory);
    if (NUM == 243) $readmemh("weight_value/weight_memory1_243.txt", weight_memory);
    if (NUM == 244) $readmemh("weight_value/weight_memory1_244.txt", weight_memory);
    if (NUM == 245) $readmemh("weight_value/weight_memory1_245.txt", weight_memory);
    if (NUM == 246) $readmemh("weight_value/weight_memory1_246.txt", weight_memory);
    if (NUM == 247) $readmemh("weight_value/weight_memory1_247.txt", weight_memory);
    if (NUM == 248) $readmemh("weight_value/weight_memory1_248.txt", weight_memory);
    if (NUM == 249) $readmemh("weight_value/weight_memory1_249.txt", weight_memory);
    if (NUM == 250) $readmemh("weight_value/weight_memory1_250.txt", weight_memory);
    if (NUM == 251) $readmemh("weight_value/weight_memory1_251.txt", weight_memory);
    if (NUM == 252) $readmemh("weight_value/weight_memory1_252.txt", weight_memory);
    if (NUM == 253) $readmemh("weight_value/weight_memory1_253.txt", weight_memory);
    if (NUM == 254) $readmemh("weight_value/weight_memory1_254.txt", weight_memory);
    if (NUM == 255) $readmemh("weight_value/weight_memory1_255.txt", weight_memory);
end

/** 
 * 784data is printed out parallel
 */
always @(posedge clk, negedge reset_b) 
begin : WEIGHT_MEMORY
    if (!reset_b) begin
        counter <= 10'd0;               // initial counter number
        state <= WAIT;                  // initial state
    end else if (state == WAIT) begin   
        end_state6_reg <= 1'b0;
        start_multiply_reg <= 1'b0;
        if (update_weight) begin     // backpropagation process state [6]
            state <= UPDATE;
            weight_memory[counter] <= weight_memory[counter] - delta_weight;
            counter <= 10'd1;
        end else if (start_state1) begin
            state <= OUTPUT;
            first_layer_weight_reg <= weight_memory[counter];  // data out instantaneously
            counter <= 10'd1;                 
            start_multiply_reg <= 1'b1;             // start_multiply signal is 1'b1;
        end
    // state is UPDATE weight
    end else if (state == UPDATE) begin   // [6] state
        weight_memory[counter] <= weight_memory[counter] - delta_weight;
        if (counter == NPIXEL-1) begin
            counter <= 10'd0;
            state <= WAIT;
            end_state6_reg <= 1'b1;
        end else begin
            counter <= counter + 10'd1;
        end
    // state is OUTPUT weight    
    end else if (state == OUTPUT) begin  // [1] state
        first_layer_weight_reg <= weight_memory[counter];
        start_multiply_reg <= 1'b0;
        if (counter == NPIXEL-1) begin
            counter <= 10'd0;
            state <= WAIT;
            
        end else begin
            counter <= counter + 10'd1;  
        end
    end
end        

assign first_layer_weight = first_layer_weight_reg;
assign end_state6 = end_state6_reg;
assign start_multiply = start_multiply_reg;


endmodule


module weight_memory2 #(
    parameter NWBITS=16,
    parameter NHIDDEN=256,
    parameter COUNT_BIT1=10,
    parameter COUNT_BIT2=8,
    parameter NUM=0) (
    input clk,                               // external clk
    input reset_b,                           // asynchronous reset
    input update_weight,                     // update weight of state [4]
    input start_state2,                      // start calcluate weighted sum 
    input start_backprop,                    // start backpropagation
    input signed [NWBITS-1:0] delta_weight,  // delta_weight of state [4]
    output signed [NWBITS-1:0] second_layer_weight,
    output end_state4,                       // finish update weight
    output start_multiply                          // start_multiply signal
);  

localparam [1:0] WAIT    = 2'b00,    // waiting for start_state1
                 UPDATE  = 2'b01,    // update weight state
                 OUTPUT  = 2'b10,    // printed out weight for weighted sum
                 BACKPROP  = 2'b11;  // printed out weight for backpropagation

/* output register declaration */
reg signed [NWBITS-1:0] second_layer_weight_reg;
reg start_multiply_reg;
reg end_state4_reg;

/* internal register data declaration */
reg signed [NWBITS-1:0] weight_memory[NHIDDEN-1:0];  // 200 weight data
reg [1:0] state;
reg [COUNT_BIT2-1:0] count;   // 0 ~ NHIDDEN-1

/* our initialized memory data */
initial begin
    if (NUM == 0) $readmemh("weight_value/weight_memory2_0.txt", weight_memory);
    if (NUM == 1) $readmemh("weight_value/weight_memory2_1.txt", weight_memory);
    if (NUM == 2) $readmemh("weight_value/weight_memory2_2.txt", weight_memory);
    if (NUM == 3) $readmemh("weight_value/weight_memory2_3.txt", weight_memory);
    if (NUM == 4) $readmemh("weight_value/weight_memory2_4.txt", weight_memory);
    if (NUM == 5) $readmemh("weight_value/weight_memory2_5.txt", weight_memory);
    if (NUM == 6) $readmemh("weight_value/weight_memory2_6.txt", weight_memory);
    if (NUM == 7) $readmemh("weight_value/weight_memory2_7.txt", weight_memory);
    if (NUM == 8) $readmemh("weight_value/weight_memory2_8.txt", weight_memory);
    if (NUM == 9) $readmemh("weight_value/weight_memory2_9.txt", weight_memory);
end
/**
 *  NHIDDEN data is printed out parallel
 */
always @(posedge clk, negedge reset_b)
begin: WEIGHT_MEMORY2
    if (!reset_b) begin
        count <= 8'd0;
        state <= WAIT;
    end else if (state == WAIT) begin
        end_state4_reg <= 1'b0;
        start_multiply_reg <= 1'b0;
        if (update_weight) begin     // [4] UPDATE new weight
            state <= UPDATE;
            weight_memory[count] <= weight_memory[count] - delta_weight; 
            count <= 8'd1; 
        end else if (start_state2) begin  // [2] Forward propagation
            state <= OUTPUT;
            second_layer_weight_reg <= weight_memory[count];  // data out instantaneously
            count <= 8'd1;
            start_multiply_reg <= 1'b1;                  // start_multiply signal is high
        end else if (start_backprop) begin   // [5] derivative_hidden_neuron
            state <= BACKPROP;
            second_layer_weight_reg <= weight_memory[count];
            count <= 8'd1;
        end
    end else if (state == UPDATE) begin  // [4] UPDATE new weight
        weight_memory[count] <= weight_memory[count] - delta_weight;
        if (count == NHIDDEN-1) begin
            count <= 8'd0;
            state <= WAIT;
            end_state4_reg <= 1'b1;
        end else begin
            count <= count + 8'd1;
        end
    end else if (state == OUTPUT) begin     // [2] Forward propagation
        second_layer_weight_reg <= weight_memory[count];
        start_multiply_reg <= 1'b0;
        if (count == NHIDDEN-1) begin
            count <= 8'd0;
            state <= WAIT;
        end else begin
            count <= count + 8'd1;
        end
    end else if (state == BACKPROP) begin       // [5] derivative_hidden_neuron
        second_layer_weight_reg <= weight_memory[count];
        if (count == NHIDDEN-1) begin
            count <= 8'd0;
            state <= WAIT;
            // start_multiply_reg <= 1'b1;
            // start_state2 signal is not active
        end else begin
            count <= count + 8'd1;
        end
    end
end

assign second_layer_weight = second_layer_weight_reg;
assign end_state4 = end_state4_reg;
assign start_multiply = start_multiply_reg;

endmodule