// Start with a copy of Patmos

grammar Leros;

@header {
package leros.asm.generated;

import java.util.HashMap;
import java.util.List;

}

@lexer::header {package leros.asm.generated;}


@members {
/** Map symbol to Integer object holding the value or address */
HashMap symbols = new HashMap();
int pc = 0;
int code[];
boolean pass2 = false;

public static String niceHex(int val) {
	String s = Integer.toHexString(val);
	while (s.length() < 8) {
		s = "0"+s;
	}
	s = "0x"+s;
	return s;
}
}

pass1: statement+;

dump: {System.out.println(symbols);};

// Don't know how to return a simple int array :-(
pass2 returns [List mem]
@init{
	System.out.println(pc+" "+symbols);
	code = new int[pc];
	pc = 0;
	pass2 = true;
}
	: statement+ {
	$mem = new ArrayList(pc);
	for (int i=0; i<pc; ++i) {
		$mem.add(new Integer(code[i]));
	}
	}; 

statement: (label)? (directive | bundle)? (COMMENT)? NEWLINE;

label:  ID ':' {symbols.put($ID.text, new Integer(pc));};

// just a dummy example
directive: '.start';

// later extend to inst || instr
bundle: instruction;

instruction: alu_imm | alu | compare | branch;

alu_imm returns [int opc]
	: (pred)? op_imm rs1 ',' imm_val TO rd
	{
		$opc = $op_imm.opc + ($pred.value<<22) +
			($rs1.value<<12) + ($rd.value<<17) +
			$imm_val.value;
		System.out.println(pc+" "+niceHex($opc)+
			" p"+$pred.value+" "+$op_imm.text);
		if (pass2) { code[pc] = $opc; }
		++pc;
	};

alu returns [int opc]
	: (pred)? op_alu rs1 ',' rs2 TO rd
	{
		$opc = (0x05<<26) + ($pred.value<<22) +
			($rs1.value<<12) + ($rs2.value<<7) + ($rd.value<<17) +
			$op_alu.func;
		System.out.println(pc+" "+niceHex($opc)+
			" p"+$pred.value+" "+$op_alu.text);
		if (pass2) { code[pc] = $opc; }
		++pc;
	};

compare returns [int opc]
	: (pred)? 'cmp' rs1 op_cmp rs2 TO pdest
	{
		$opc = (0x07<<26) + ($pred.value<<22) +
			($rs1.value<<12) + ($rs2.value<<7) + ($pdest.value<<17) +
			$op_cmp.func;
		System.out.println(pc+" "+niceHex($opc)+
			" p"+$pred.value+" cmp "+$op_cmp.text+" pd"+$pdest.value);
		if (pass2) { code[pc] = $opc; }
		++pc;
	};

branch returns [int opc]
	: (pred)? 'br' ID
	{
		int off = 0;
		if (pass2) {
			Integer v = (Integer) symbols.get($ID.text);
        		if ( v!=null ) {
				off = v.intValue();
		        } else {
				throw new Error("Undefined label "+$ID.text);
			}
			off = off - pc;
			// TODO test maximum offset
			// at the moment 22 bits offset
			off &= 0x3fffff;
		}
		$opc = (0x06<<26) + ($pred.value<<22) + off;
		System.out.println(pc+" "+niceHex($opc)+
			" p"+$pred.value+" br "+((off<<10)>>10));
		if (pass2) { code[pc] = $opc; }
		++pc;
	};

rs1 returns [int value]: register {$value = $register.value;};
rs2 returns [int value]: register {$value = $register.value;};
rd returns [int value]: register {$value = $register.value;};


register returns [int value]
	: REG {$value = Integer.parseInt($REG.text.substring(1));
		if ($value<0 || $value>31) throw new Error("Wrong register name");};

pred returns [int value]
	: PRD {$value = Integer.parseInt($PRD.text.substring(1));
		if ($value<0 || $value>15) throw new Error("Wrong predicate name");};

pdest returns [int value]
	: PRD {$value = Integer.parseInt($PRD.text.substring(1));
		if ($value<0 || $value>15) throw new Error("Wrong predicate name");};

imm_val returns [int value]
    : INT {$value = Integer.parseInt($INT.text);
		if ($value<-2048 || $value>2047) throw new Error("Wrong immediate");};

op_imm returns [int opc]: 
	'addi' {$opc = 0<<26;} |
	'ori' {$opc =  1<<26;} |
	'andi' {$opc = 2<<26;} |
	'xori' {$opc = 3<<26;}
	;

op_alu returns [int func]: 
	'add' {$func = 0;} |
	'sub' {$func = 1;} |
	'or' {$func = 2;} |
	'and' {$func = 3;} |
	'xor' {$func = 4;}
	;

op_cmp returns [int func]:
	'==' {$func = 0;} |
	'!=' {$func = 1;} |
	'>=' {$func = 2;} |
	'<=' {$func = 3;} |
	'>' {$func = 4;} |
	'<' {$func = 5;}
	;

/* Lexer rules (start with upper case) */

INT :   '0'..'9'+ ;
REG: 'r' INT;
PRD: 'p' INT;
TO: '->';

ID: ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'_' | '0'..'9')*;

COMMENT: '//' ~('\n'|'\r')* ;

NEWLINE: '\r'? '\n' ;
WHITSPACE:   (' '|'\t')+ {skip();} ;

