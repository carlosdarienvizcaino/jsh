%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ast.h"
#include "defines.h"
#include "utils.h"

int linenum = 1;
bool inString = FALSE;

struct AstRoot* astRoot; // Contains parsed command

void yyerror(const char *str) {
  fprintf(stderr,"line: %d error: %s\n", linenum, str);
}

int yywrap() {
  return 1;
}

int yylex();
%}

%union {
  int integer;
  char* string;
  struct AstRoot* astRoot;
  struct AstPipeSequence* astPipeSequence;
  struct AstSingleCommand* astSingleCommand;
}

/* -------------------------------------------------------
   The grammar symbols ------------------------------------------------------- */
%token<string>  WORD
%token<string>  ASSIGNMENT_WORD
%token<string>  NAME
%token<string>  NEWLINE
%token<string>  IO_NUMBER
%token<string>  IO_COMBINE
%token<string>  DRBRKT

%token<integer>  AND_IF    OR_IF
/*              '&&'      '||' */

%type<integer> sequence_separator
%type<string>  filename cmd_name io_in io_out io_err io_out_replace
%type<astSingleCommand> single_command
%type<astPipeSequence> pipe_sequence
%type<astRoot> complete_command
/* -------------------------------------------------------
   The Grammar
   ------------------------------------------------------- */
%start  complete_command
%%
complete_command   : pipe_sequence {$$ = createAstRoot(); addPipeSequence($$, $1); astRoot = $$;}
                   | complete_command sequence_separator pipe_sequence {addPipeSequenceWithSeparator($1, $3, ($2 == AND_IF) ? DAND : DPIPE); $$ = $1; astRoot = $$;}
                   | complete_command '&' {$$->async = TRUE; astRoot = $$;}
                   | complete_command NEWLINE {$$ = $1; astRoot = $$;}
                   | NEWLINE {$$ = createAstRoot(); astRoot = $$;}
                   ;
pipe_sequence      : single_command {$$ = createAstPipeSequence(); addCommand($$, $1);}
                   | pipe_sequence '|' single_command {addCommand($1, $3); $$ = $1; if ($$->io_in != NULL || $$->io_out != NULL || $$->io_err != NULL) {setTermColor(stderr, KRED); fprintf(stderr, "file IO must occur at end of pipe_sequence\n"); setTermColor(stderr, KNRM); return ERROR;}}
                   | pipe_sequence io_in {if ($1->io_in != NULL) {setTermColor(stderr, KRED); fprintf(stderr, "duplicated IO_in\n"); setTermColor(stderr, KNRM); return ERROR;} setIoIn($1, $2); $$ = $1;}
                   | pipe_sequence io_out {if ($1->io_out != NULL) {setTermColor(stderr, KRED); fprintf(stderr, "duplicated  IO_out\n"); setTermColor(stderr, KNRM); return ERROR;} setIoOut($1, $2, FALSE); $$ = $1;}
                   | pipe_sequence io_out_replace {if ($1->io_out != NULL) {setTermColor(stderr, KRED); fprintf(stderr, "duplicated IO_out\n"); setTermColor(stderr, KNRM); return ERROR;} setIoOut($1, $2, TRUE); $$ = $1;}
                   | pipe_sequence io_err {if ($1->io_err != NULL || $1->err2out) {setTermColor(stderr, KRED); fprintf(stderr, "duplicated io_stdout\n"); setTermColor(stderr, KNRM); return ERROR;} setIoErr($1, $2); $$ = $1;}
                   | pipe_sequence io_com {if ($1->io_err != NULL || $1->err2out) {setTermColor(stderr, KRED); fprintf(stderr, "duplicated io_stdout\n"); setTermColor(stderr, KNRM); return ERROR;} setIoErr($1, NULL); $$ = $1;}
                   ;
sequence_separator : AND_IF {$$ = AND_IF;}
                   | OR_IF {$$ = OR_IF;}
                   ;
single_command     : cmd_name {$$ = createAstSingleCommand($1);}
                   | single_command WORD {addArgs($1, $2, inString); $$ = $1; inString = FALSE;}
                   ;
cmd_name           : WORD {$$ = $1;}
                   ;
io_in              : '<'        filename {$$ = $2;}
                   ;
io_out             : '>'        filename {$$ = $2;}
                   ;
io_out_replace     : DRBRKT     filename {$$ = $2;}
                   ;
io_err             : IO_NUMBER  filename {if(strcmp("2>", $1) != 0){setTermColor(stderr, KRED); fprintf(stderr, "IO_NUMBER %s not recognized\n", $1); setTermColor(stderr, KNRM); return ERROR;}; $$ = $2;}
                   ;
io_com             : IO_COMBINE
                   ;
filename           : WORD {$$ = $1;}
                   ;
%%
