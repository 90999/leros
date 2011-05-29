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

package leros;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.StreamTokenizer;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import leros.Instruction.Type;

public class LerosAsm {

	static final int ADDRBITS = 8;
	static final int DATABITS = 16;
	static final int ROM_LEN = 1<<ADDRBITS;

	String fname;
	String dstDir = "./";
	String srcDir = "./";
	private Map<String, Integer> symMap = new HashMap<String, Integer>();
	boolean error;
	private int memcnt = 0;
	private List<String> varList = new LinkedList<String>();


	public LerosAsm(String[] args) {
		srcDir = System.getProperty("user.dir");
		dstDir = System.getProperty("user.dir");
		processOptions(args);
		if (!srcDir.endsWith(File.separator))
			srcDir += File.separator;
		if (!dstDir.endsWith(File.separator))
			dstDir += File.separator;
	}
	
	static public class Line {
		String label;
		Instruction instr;
		int special;
		int intVal;
		String symVal;
	}

	private Line getLine(StreamTokenizer in) {

		Line l = new Line();

		try {
			for (int cnt = 0; in.nextToken() != StreamTokenizer.TT_EOL; ++cnt) {

				if (in.ttype == StreamTokenizer.TT_WORD) {

					int pos = in.sval.indexOf(":");
					if (pos != -1) {
						String s = in.sval.substring(0, pos);
						l.label = s;
					} else {
						Instruction i = Instruction.get(in.sval);
						if (i == null) {
							l.symVal = in.sval;
						} else if (l.instr == null) {
							l.instr = i;
						}
					}

				} else if (in.ttype == StreamTokenizer.TT_NUMBER) {

					l.intVal = (int) in.nval;

				} else if (in.ttype == '=') {
					l.special = in.ttype;
				} else if (in.ttype == '?') {
					l.special = in.ttype;
				} else {
					error(in, "'" + (char) in.ttype + "' syntax");
				}
			} // EOL
		} catch (IOException e) {
			System.out.println(e.getMessage());
			System.exit(-1);
		}

		return l;
	}


	private StreamTokenizer getSt() {

		try {
			FileReader fileIn = new FileReader(srcDir + fname);
			StreamTokenizer in = new StreamTokenizer(fileIn);

			in.wordChars('_', '_');
			in.wordChars(':', ':');
			in.eolIsSignificant(true);
			in.slashStarComments(true);
			in.slashSlashComments(true);
			in.lowerCaseMode(true);
			return in;
		} catch (IOException e) {
			System.out.println(e.getMessage());
			System.exit(-1);
			return null;
		}
	}
	
	String bin(int val, int bits) {

		String s = "";
		for (int i=0; i<bits; ++i) {
			s += (val & (1<<(bits-i-1))) != 0 ? "1" : "0";
		}
		return s;
	}

	void error(StreamTokenizer in, String s) {
		System.out.println((in.lineno() - 1) + " error: " + s);
		error = true;
	}

	/**
	 * Parse the assembler file and build symbol table (first pass). During this
	 * pass, the assembler code, the symbol table and variable (register) table
	 * are build.
	 */
	public void pass1() {
		StreamTokenizer in = getSt();
		int pc = 0;

		try {
			while (in.nextToken() != StreamTokenizer.TT_EOF) {
				in.pushBack();
				Line l = getLine(in);
				System.out.println("L"+in.lineno()+" "+l.label+" "+l.instr+" '"+(char)
				l.special+"' "+l.intVal+" "+l.symVal);

				if (l.label != null) {
					if (symMap.containsKey(l.label)) {
						error(in, "symbol " + l.label + " already defined");
					} else {
						symMap.put(l.label, new Integer(pc));
					}
				}

				if (l.special == '=') {
					if (l.symVal == null) {
						error(in, "missing symbol for '='");
					} else {
						if (symMap.containsKey(l.symVal)) {
							error(in, "symbol " + l.symVal
									+ " allready defined");
						} else {
							symMap.put(l.symVal, new Integer(l.intVal));
						}
					}
				} else if (l.special == '?') {
					if (symMap.containsKey(l.symVal)) {
						error(in, "symbol " + l.symVal + " allready defined");
					} else {
						symMap.put(l.symVal, new Integer(memcnt++));
						varList.add(l.symVal);
					}
				}

				if (l.instr != null) {
					++pc;
					// instructions.add(l);
					// what is that list good for?
				}
			}
		} catch (IOException e) {
			System.out.println(e.getMessage());
			System.exit(-1);
		}
		System.out.println(symMap);
	}

	String getRomHeader() {
		
		String line = "--\n";
		line += "--\tleros_rom.vhd\n";
		line += "--\n";
		line += "--\tgeneric VHDL version of ROM\n";
		line += "--\n";
		line += "--\t\tDONT edit this file!\n";
		line += "--\t\tgenerated by "+this.getClass().getName()+"\n";
		line += "--\n";
		line += "\n";
		line += "library ieee;\n";
		line += "use ieee.std_logic_1164.all;\n";
		line += "\n";
		line += "entity leros_rom is\n";
//		line += "generic (width : integer; addr_width : integer);\t-- for compatibility\n";
		line += "port (\n";
		line += "    address : in std_logic_vector("+(ADDRBITS-1)+" downto 0);\n";
		line += "    q : out std_logic_vector("+(DATABITS-1)+" downto 0)\n";
		line += ");\n";
		line += "end leros_rom;\n";
		line += "\n";
		line += "architecture rtl of leros_rom is\n";
		line += "\n";
		line += "begin\n";
		line += "\n";
		line += "process(address) begin\n";
		line += "\n";
		line += "case address is\n";
		
		return line;
	}
	
	String getRomFeet() {
		
		String line = "\n";
		line += "    when others => q <= \""+bin(0, DATABITS)+"\";\n";
		line += "end case;\n";
		line += "end process;\n";
		line += "\n";
		line += "end rtl;\n";
		
		return line;
	}
	public void pass2() {

		StreamTokenizer in = getSt();
		int pc = 0;


		try {
			BufferedReader inraw = new BufferedReader(new FileReader(srcDir + fname));
			
			FileWriter romvhd = new FileWriter(dstDir + "leros_rom.vhd");
			romvhd.write(getRomHeader());


			while (in.nextToken() != StreamTokenizer.TT_EOF) {
				in.pushBack();

				Line l = getLine(in);

				if (l.instr==null) {
					romvhd.write("                                               ");
				} else {
					int opcode = l.instr.opcode;

					if (l.instr.opdSize!=0) {
						int opVal = 0;
						if (l.symVal!=null) {
							Integer i = symMap.get(l.symVal);
							if (i==null) {
								error(in, "Symbol "+l.symVal+" not defined");
							} else {
								opVal = i.intValue();
							}
						} else {
							opVal = l.intVal;
							opcode = l.instr.setImmediate();
						}

						
						int mask = (1<<l.instr.opdSize)-1;

						// for branches and jumps opVal points to the target address
						if (l.instr.type==Type.BRANCH) {
							System.out.println("branch "+opVal+" "+pc);
							// relative address
							opVal = opVal-pc;
							// check maximum relative offset
							if (opVal>(mask>>1) || opVal<(-((mask>>1)+1))) {
								error(in, "branch address too far: "+opVal);								
							}
							opVal &= mask;
						}

						// general check
						if (opVal>mask || opVal<0) {
							error(in, "operand wrong: "+opVal);
						}
						opcode |= opVal & mask;		// use operand
					}

//					romData[romLen] = opcode;
//					++romLen;
					romvhd.write("    when \""+bin(pc, ADDRBITS) +
							"\" => q <= \""+bin(opcode, DATABITS)+"\";");
					++pc;
				}
				romvhd.write(" -- "+inraw.readLine()+"\n");

			}

			romvhd.write(getRomFeet());
			romvhd.close();

//			PrintStream rom_mem = new PrintStream(new FileOutputStream(dstDir + "mem_rom.dat"));
//			for (int i=0; i<ROM_LEN; ++i) {
//				rom_mem.println(romData[i]+" ");
//			}
//			rom_mem.close();

		} catch (IOException e) {
			System.out.println(e.getMessage());
			System.exit(-1);
		}
	}

	private boolean processOptions(String clist[]) {
		boolean success = true;

		for (int i = 0; i < clist.length; i++) {
			if (clist[i].equals("-s")) {
				srcDir = clist[++i];
			} else if (clist[i].equals("-d")) {
				dstDir = clist[++i];
			} else {
				fname = clist[i];
			}
		}

		return success;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		if (args.length < 1) {
			System.out
					.println("usage: java Jopa [-s srcDir] [-d dstDir] filename");
			System.exit(-1);
		}
		LerosAsm la = new LerosAsm(args);
		la.pass1();
		la.pass2();

	}

}
