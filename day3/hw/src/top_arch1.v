// Day 3: Architecture 1 - ROM-Based Counter Increment
// Key optimization: Replace carry-chain counter with ROM-based increment
// Critical path: ROM_data → Accumulator (no counter on feedback)
// Counter increment happens via LUT-based lookup (not on critical path)

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    // Simple counter
    reg [8:0] rom_counter = 0;

    // ROM address increment lookup - replaces arithmetic carry chain
    wire [8:0] rom_counter_next;
    addr_increment_lut counter_inc (
        .addr(rom_counter),
        .next(rom_counter_next)
    );

    // Main ROM
    wire [31:0] rom_data;
    rom_hardcoded rom (
        .addr(rom_counter[7:0]),
        .data(rom_data)
    );

    // Single pipeline stage for ROM data
    reg [31:0] rom_data_delayed = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_data_delayed <= 0;
            score <= 0;
        end else if (rom_counter < 201) begin
            // Critical path: rom_data → accumulator (no counter increment here!)
            rom_data_delayed <= rom_data;
            score <= score + rom_data_delayed;

            // Counter increment: separate, non-critical path (uses LUT)
            rom_counter <= rom_counter_next;
        end
    end

endmodule


// Address increment using LUT (0->1, 1->2, ..., 199->200, 200->200)
// This replaces 8-bit binary adder carry chain
// Fits in 256 LUTs, computed combinationally (no timing impact on ROM_data path)
module addr_increment_lut (
    input [8:0] addr,
    output reg [8:0] next
);
    always @(*) begin
        case (addr)
            9'd0:   next = 9'd1;
            9'd1:   next = 9'd2;
            9'd2:   next = 9'd3;
            9'd3:   next = 9'd4;
            9'd4:   next = 9'd5;
            9'd5:   next = 9'd6;
            9'd6:   next = 9'd7;
            9'd7:   next = 9'd8;
            9'd8:   next = 9'd9;
            9'd9:   next = 9'd10;
            9'd10:  next = 9'd11;
            9'd11:  next = 9'd12;
            9'd12:  next = 9'd13;
            9'd13:  next = 9'd14;
            9'd14:  next = 9'd15;
            9'd15:  next = 9'd16;
            9'd16:  next = 9'd17;
            9'd17:  next = 9'd18;
            9'd18:  next = 9'd19;
            9'd19:  next = 9'd20;
            9'd20:  next = 9'd21;
            9'd21:  next = 9'd22;
            9'd22:  next = 9'd23;
            9'd23:  next = 9'd24;
            9'd24:  next = 9'd25;
            9'd25:  next = 9'd26;
            9'd26:  next = 9'd27;
            9'd27:  next = 9'd28;
            9'd28:  next = 9'd29;
            9'd29:  next = 9'd30;
            9'd30:  next = 9'd31;
            9'd31:  next = 9'd32;
            9'd32:  next = 9'd33;
            9'd33:  next = 9'd34;
            9'd34:  next = 9'd35;
            9'd35:  next = 9'd36;
            9'd36:  next = 9'd37;
            9'd37:  next = 9'd38;
            9'd38:  next = 9'd39;
            9'd39:  next = 9'd40;
            9'd40:  next = 9'd41;
            9'd41:  next = 9'd42;
            9'd42:  next = 9'd43;
            9'd43:  next = 9'd44;
            9'd44:  next = 9'd45;
            9'd45:  next = 9'd46;
            9'd46:  next = 9'd47;
            9'd47:  next = 9'd48;
            9'd48:  next = 9'd49;
            9'd49:  next = 9'd50;
            9'd50:  next = 9'd51;
            9'd51:  next = 9'd52;
            9'd52:  next = 9'd53;
            9'd53:  next = 9'd54;
            9'd54:  next = 9'd55;
            9'd55:  next = 9'd56;
            9'd56:  next = 9'd57;
            9'd57:  next = 9'd58;
            9'd58:  next = 9'd59;
            9'd59:  next = 9'd60;
            9'd60:  next = 9'd61;
            9'd61:  next = 9'd62;
            9'd62:  next = 9'd63;
            9'd63:  next = 9'd64;
            9'd64:  next = 9'd65;
            9'd65:  next = 9'd66;
            9'd66:  next = 9'd67;
            9'd67:  next = 9'd68;
            9'd68:  next = 9'd69;
            9'd69:  next = 9'd70;
            9'd70:  next = 9'd71;
            9'd71:  next = 9'd72;
            9'd72:  next = 9'd73;
            9'd73:  next = 9'd74;
            9'd74:  next = 9'd75;
            9'd75:  next = 9'd76;
            9'd76:  next = 9'd77;
            9'd77:  next = 9'd78;
            9'd78:  next = 9'd79;
            9'd79:  next = 9'd80;
            9'd80:  next = 9'd81;
            9'd81:  next = 9'd82;
            9'd82:  next = 9'd83;
            9'd83:  next = 9'd84;
            9'd84:  next = 9'd85;
            9'd85:  next = 9'd86;
            9'd86:  next = 9'd87;
            9'd87:  next = 9'd88;
            9'd88:  next = 9'd89;
            9'd89:  next = 9'd90;
            9'd90:  next = 9'd91;
            9'd91:  next = 9'd92;
            9'd92:  next = 9'd93;
            9'd93:  next = 9'd94;
            9'd94:  next = 9'd95;
            9'd95:  next = 9'd96;
            9'd96:  next = 9'd97;
            9'd97:  next = 9'd98;
            9'd98:  next = 9'd99;
            9'd99:  next = 9'd100;
            9'd100: next = 9'd101;
            9'd101: next = 9'd102;
            9'd102: next = 9'd103;
            9'd103: next = 9'd104;
            9'd104: next = 9'd105;
            9'd105: next = 9'd106;
            9'd106: next = 9'd107;
            9'd107: next = 9'd108;
            9'd108: next = 9'd109;
            9'd109: next = 9'd110;
            9'd110: next = 9'd111;
            9'd111: next = 9'd112;
            9'd112: next = 9'd113;
            9'd113: next = 9'd114;
            9'd114: next = 9'd115;
            9'd115: next = 9'd116;
            9'd116: next = 9'd117;
            9'd117: next = 9'd118;
            9'd118: next = 9'd119;
            9'd119: next = 9'd120;
            9'd120: next = 9'd121;
            9'd121: next = 9'd122;
            9'd122: next = 9'd123;
            9'd123: next = 9'd124;
            9'd124: next = 9'd125;
            9'd125: next = 9'd126;
            9'd126: next = 9'd127;
            9'd127: next = 9'd128;
            9'd128: next = 9'd129;
            9'd129: next = 9'd130;
            9'd130: next = 9'd131;
            9'd131: next = 9'd132;
            9'd132: next = 9'd133;
            9'd133: next = 9'd134;
            9'd134: next = 9'd135;
            9'd135: next = 9'd136;
            9'd136: next = 9'd137;
            9'd137: next = 9'd138;
            9'd138: next = 9'd139;
            9'd139: next = 9'd140;
            9'd140: next = 9'd141;
            9'd141: next = 9'd142;
            9'd142: next = 9'd143;
            9'd143: next = 9'd144;
            9'd144: next = 9'd145;
            9'd145: next = 9'd146;
            9'd146: next = 9'd147;
            9'd147: next = 9'd148;
            9'd148: next = 9'd149;
            9'd149: next = 9'd150;
            9'd150: next = 9'd151;
            9'd151: next = 9'd152;
            9'd152: next = 9'd153;
            9'd153: next = 9'd154;
            9'd154: next = 9'd155;
            9'd155: next = 9'd156;
            9'd156: next = 9'd157;
            9'd157: next = 9'd158;
            9'd158: next = 9'd159;
            9'd159: next = 9'd160;
            9'd160: next = 9'd161;
            9'd161: next = 9'd162;
            9'd162: next = 9'd163;
            9'd163: next = 9'd164;
            9'd164: next = 9'd165;
            9'd165: next = 9'd166;
            9'd166: next = 9'd167;
            9'd167: next = 9'd168;
            9'd168: next = 9'd169;
            9'd169: next = 9'd170;
            9'd170: next = 9'd171;
            9'd171: next = 9'd172;
            9'd172: next = 9'd173;
            9'd173: next = 9'd174;
            9'd174: next = 9'd175;
            9'd175: next = 9'd176;
            9'd176: next = 9'd177;
            9'd177: next = 9'd178;
            9'd178: next = 9'd179;
            9'd179: next = 9'd180;
            9'd180: next = 9'd181;
            9'd181: next = 9'd182;
            9'd182: next = 9'd183;
            9'd183: next = 9'd184;
            9'd184: next = 9'd185;
            9'd185: next = 9'd186;
            9'd186: next = 9'd187;
            9'd187: next = 9'd188;
            9'd188: next = 9'd189;
            9'd189: next = 9'd190;
            9'd190: next = 9'd191;
            9'd191: next = 9'd192;
            9'd192: next = 9'd193;
            9'd193: next = 9'd194;
            9'd194: next = 9'd195;
            9'd195: next = 9'd196;
            9'd196: next = 9'd197;
            9'd197: next = 9'd198;
            9'd198: next = 9'd199;
            9'd199: next = 9'd200;
            9'd200: next = 9'd200;  // Hold at 200
            default: next = 9'd200;
        endcase
    end
endmodule
