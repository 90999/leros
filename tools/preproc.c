#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int registers[256];

void read_reg(const char **ppstr)
{
	const char *str = *ppstr;
	char reg[16];
	int i=0;
	for(i=0; i < 16; i++)
		reg[i] = 0;

	i=0;
	while(*str== ',')
		str++;
	while(*str && (*str != ')' && *str != ','))
	{
		reg[i++]=*str;
		str++;
	}
	printf("Found reg: %s\n", reg);
	registers[atoi(reg+1)]=1;

	*ppstr = str;
}

void read_reg_list(const char* str)
{
	//clear the list first
	int i;
	for(i=0;i<256;i++)
		registers[i]=0;

	while(*str && *str != '(')
		str++;
	if(!*str)
	{
		printf("Error parsing register list\n");
		return;
	}
	//Skip past paren
	str++;
	if(!*str)
	{
		printf("Error parsing register list\n");
		return;
	}

	while(*str && *str != ')')
	{
		read_reg(&str);
	}
	
}

void read_target(char* str, char* ret)
{
	while(*str && *str != '(')
		str++;
	if(!*str)
	{
		printf("Error parsing function name\n");
		return;
	}
	//Skip past paren
	str++;
	if(!*str)
	{
		printf("Error parsing function na,e\n");
		return;
	}

	while(*str && *str != ')')
	{
		*ret = *str;
		ret++;str++;
	}

	*ret = 0;
}

int get_nregs()
{
	int ret=0;
	int i;
	for(i=0; i<256; i++)
		if(registers[i])
			ret++;
	return ret;
}

int main()
{
	char str[256];
	char macro[256];
	char fname[256];

	FILE* infile = fopen("in.asm", "r");
	if(!infile)
	{
		printf("Couldn't open input file\n");
		return 0;
	}

	FILE *outfile = fopen("out.asm", "w");
	if(!outfile)
	{
		printf("Couldn't open output file\n");
		return 0;
	}

	while(fgets(str,256,infile))
	{
		if(sscanf(str,"%s",macro)!=1)
			continue;	
		if(strncmp(macro,"FUNCTION_ENTER",strlen("FUNCTION_ENTER"))==0)
		{
			read_reg_list(macro);
			printf("Pushing %d regs\n", get_nregs());

			fprintf(outfile,"//%s\n",macro);
			fprintf(outfile,"nop\n");
			fprintf(outfile,"//Saving link register\n");
			fprintf(outfile,"load r0\n");
			fprintf(outfile,"loadaddr r1\n");
			fprintf(outfile,"store (ar+0)\n");

			int i,nregs;
			nregs=0;
			for(i=0; i < 256; i++)
			{
				if(registers[i])
				{
					fprintf(outfile,"//Saving register %d\n", i);
					fprintf(outfile,"load r%d\n",i);
					fprintf(outfile,"loadaddr r1\n");
					fprintf(outfile,"store (ar+%d)\n",nregs+1);
					nregs++;
				}	
			}

			fprintf(outfile,"//Updating stack pointer\n");
			fprintf(outfile,"load r1\n");
			fprintf(outfile,"nop\n");
			fprintf(outfile,"add %d\n",nregs+1);
			fprintf(outfile,"store r1\n");
			fprintf(outfile,"nop\n");

			fprintf(outfile,"//END %s\n",macro);

		}else if(strncmp(macro,"FUNCTION_END",strlen("FUNCTION_END"))==0)
		{
			read_reg_list(macro);

			fprintf(outfile,"//%s\n",macro);
			fprintf(outfile,"//Restoring stack pointer\n");

			int nregs = get_nregs();

			fprintf(outfile,"load r1\n");
			fprintf(outfile,"nop\n");
			fprintf(outfile,"sub %d\n",nregs+1);
			fprintf(outfile,"store r1\n");
			fprintf(outfile,"nop\n");

			int i;	
			for(i=255; i >= 0; i--)
			{
				if(registers[i])
				{
					fprintf(outfile,"//Restoring register %d\n", i);
					fprintf(outfile,"loadaddr r1\n");
					fprintf(outfile,"load (ar+%d)\n",nregs);
					nregs--;
					fprintf(outfile,"store r%d\n",i);
				}
			}

			fprintf(outfile,"//Restoring link register\n");
			fprintf(outfile,"loadaddr r1\n");
			fprintf(outfile,"load (ar+0)\n");	
			fprintf(outfile,"store r0\n");
			fprintf(outfile,"jal r0\n");
			fprintf(outfile,"nop\n");
			fprintf(outfile,"//END %s\n",macro);
		}else if(strncmp(macro,"FUNCTION_CALL",strlen("FUNCTION_CALL"))==0)
		{
			read_target(macro,fname);

			fprintf(outfile,"//FUNCTION_CALL BEGIN\n");
			fprintf(outfile,"load <%s\n", fname);
			fprintf(outfile,"loadh >%s\n", fname);
			fprintf(outfile,"loadhl >>%s\n", fname);
			fprintf(outfile,"loadhh >>>%s\n", fname);
			fprintf(outfile,"nop\n");
			fprintf(outfile,"jal r0\n");
			fprintf(outfile,"nop\n");
			fprintf(outfile,"//FUNCTION_CALL END\n");
		}else{
			fprintf(outfile,"%s",str);
		}
	} 

	return 0;
}
