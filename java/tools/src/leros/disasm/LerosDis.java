/*
   Copyright 2011 Martin Schoeberl <masca@imm.dtu.dk>,
                  Technical University of Denmark, DTU Informatics. 
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

      1. Redistributions of source code must retain the above copyright notice,
         this list of conditions and the following disclaimer.

      2. Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in the
         documentation and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
   OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
   NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
   THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   The views and conclusions contained in the software and documentation are
   those of the authors and should not be interpreted as representing official
   policies, either expressed or implied, of the copyright holder.
 */

package leros.disasm;

import java.io.*;
import java.util.*;

/**
 * A crude simulation of Leros. Pipeline effects (branch delay slots) are
 * currently ignored.
 * 
 * @author Martin Schoeberl
 * 
 */
public class LerosDis {

	String srcFname;
	String dstFname;
	String symFname;
	boolean log;
	HashMap <Integer,String>symbols;

	
	public LerosDis(String[] args) {


		srcFname = args[0];
		symFname = args[1];
//		dstFname = args[1];
		symbols = new HashMap<Integer,String>();

		BufferedReader syms = null;
		try {
			syms = new BufferedReader(new FileReader(symFname));
			String l;
			while ((l = syms.readLine()) != null) {
				String[] stuff = l.split("=");
		
//				System.out.println(stuff[0] + ", " + stuff[1]);
				symbols.put(Integer.parseInt(stuff[1]),stuff[0]);

			}
			
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (syms != null) {
				try {
					syms.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}

		}

		BufferedReader instr = null;
		try {
			instr = new BufferedReader(new FileReader(srcFname));
			String l;
			while ((l = instr.readLine()) != null) {
				int istr = (int) Integer.parseInt(l);

				ParseInstr(istr);
			}
			
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (instr != null) {
				try {
					instr.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}

		}
	}

	private int pc=0;

	private void printinst(String op, String end, int instr, int val, boolean immediate, boolean register)
	{
		String sym = symbols.get(pc);
		if(sym!=null)
			System.out.printf("%s:\n",sym);

		System.out.printf("%08x: %04X:\t%s", pc,instr,op);
		if(register)
			System.out.printf("r%d", val); //TODO: registers are unsigned
		if(immediate)
			System.out.printf("%d", val); //TODO: loadh,loadhl,loadhh are unsigned
		

		System.out.printf("%s\n",end);
		pc++;
	}

	private void ParseInstr(int instr)
	{	
			int val,sval;
			boolean imm = false;
			boolean reg = false;
			// immediate value
			if ((instr & 0x0100) != 0) {
				// take o bit from the instruction
				val = instr & 0xff;
				// sign extension to 32 bit
				if ((val & 0x80)!=0) { val |= 0xffffff00; }
				imm = true;
			} else {
				val = instr & 0xff;
				reg=true;
			}

			sval = (instr << 24) >> 24;
			
			switch (instr & 0xfe00) {
			case 0x0000: 
				printinst("nop ", "", instr, 0, false, false);
				break;
			case 0x0800: // add
				printinst("add ", "", instr, val, imm, reg);
				break;
			case 0x0c00: // sub
				printinst("sub ", "", instr, val, imm, reg);
				break;
			case 0x1000: // shr
				printinst("shr ", "", instr, 0, false, false);
				break;
			case 0x2000: // load
				printinst("load ", "", instr, val, imm, reg);
				break;
			case 0x2200: // and
				printinst("and ", "", instr, val, imm, reg);
				break;
			case 0x2400: // or
				printinst("or ", "", instr, val, imm, reg);
				break;
			case 0x2600: // xor
				printinst("xor ", "", instr, val, imm, reg);
				break;
			case 0x2800: // loadh
				printinst("loadh ", "", instr, val, true, false);
				break;
			case 0x2C00: //loadhl
				printinst("loadhl ", "", instr, val, true, false);
				break;
			case 0x2E00: //loadhh
				printinst("loadhh ", "", instr, val, true, false);
				break;	
			case 0x3000: // store
				printinst("store ", "", instr, val, false, true);
				break;
			case 0x3800: // out
				printinst("out ", "", instr, val, imm, reg);
				break;
			case 0x3c00: // in
				printinst("in ", "", instr, val, imm, reg);
				break;
			case 0x4000: // jal
				printinst("jal ", "", instr, val, imm, reg);
				break;
			case 0x5000: // loadaddr
				printinst("loadaddr ", "", instr, val, imm, reg);
				break;
			case 0x6000: // load indirect
				printinst("loadindr (ar+", ")", instr, val, true, false);
				break;
			case 0x7000: // store indirect
				printinst("storeindr (ar+", ")", instr, val, true, false);
				break;
			// case 7: // I/O (ld/st indirect)
			// break;
			// case 8: // brl
			// break;
			// case 9: // br conditional
			// break;
			default:
				// branches use the immediate bit for decode
				// TODO: we could change the encoding so it
				// does not 'consume' the immediate bit - would
				// this be simpler (and lead to less HW?)
				switch (instr & 0xff00) {
				case 0x4800: // branch
					printinst("branch ", "", instr, sval, true, false);
					break;
				case 0x4900: // brz
					printinst("brz ", "", instr, sval, true, false);
					break;
				case 0x4a00: // brnz
					printinst("brnz ", "", instr, sval, true, false);
					break;
				case 0x4b00: // brp
					printinst("brp ", "", instr, sval, true, false);
					break;
				case 0x4c00: // brn
					printinst("brn ", "", instr, sval, true, false);
					break;

				default:
					System.out.println("Instruction " + instr 
							+ " not implemented");
				}
			}
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		if (args.length < 1) {
			System.out.println("usage: java LerosDis infile outfile");
			System.exit(-1);
		}
		LerosDis ls = new LerosDis(args);
	}

}
