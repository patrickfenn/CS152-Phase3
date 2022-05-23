    /* cs152-miniL phase2 */

%{

#include "lib.h"

extern int currLine;
extern int currCol;
extern int yylex(void);
void yyerror(const char *msg);
map<string, _symbol*> table;
%}

%define api.value.type {union YYSTYPE}
%error-verbose
%start Program
%token<str_val> IDENT;
%token<int_val> NUMBER;
%type<_IDS> Identifiers %type<_DECL> Declaration %type<_VAR> Var %type<_TERM> Term %type<_TERMS> Terms %type<_MULT_EXPR> Multiplicative-Expr %type<_REL_EXPR> Relation-Expr %type<_EXPR> Expression %type<_EXPRS> Expressions %type<_MULT_EXPRS> Multiplicative-Exprs %type<_COMP> Comp %type<_REL_EXPRS> Relation-Exprs %type<_BOOL_EXPR> Bool-Expr %type<_REL_AND_EXPR> Relation-And-Expr %type<_REL_AND_EXPRS> Relation-And-Exprs %type<_VARS> Vars %type<_STATEMENT> Statement %type<_SSS> Statements_Semi %type<_SS> Statement_Semi %type<_DS> Declaration_Semi %type<_DSS> Declarations_Semi %type<_FUNC> Function %type<_FUNCS> Functions %type<_PROGRAM> Program;
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN;
%% 

Program:
   Functions {
       _functions* fs = dynamic_cast<_functions*>($1);
       $$ = new _program(fs);
   }   
    | {$$ = new _program();}   
    ;

//Functions will need their own symbol table pushed onto the stack.
Functions:
    Function Functions {
        _function* f = dynamic_cast<_function*>($1);
        _functions* fs = dynamic_cast<_functions*>($2);
        $$ = new _functions(f,fs);
    }    
    |  {$$ = new _functions();}    
    ;

Declaration_Semi:
    Declaration SEMICOLON {
        _declaration* d = dynamic_cast<_declaration*>($1);
        $$ = new _declaration_semi(d);
    }    
    ;

Declarations_Semi:
    Declaration_Semi Declarations_Semi {
        _declaration_semi* ds = dynamic_cast<_declaration_semi*>($1);
        _declarations_semi* dss = dynamic_cast<_declarations_semi*>($2);
        $$ = new _declarations_semi(ds,dss);
    }    
    | {$$ = new _declarations_semi();}    
    ;

Statement_Semi:
    Statement SEMICOLON {
        _statement* s = dynamic_cast<_statement*>($1);
        $$ = new _statement_semi(s);
    }    
    ;

Statements_Semi:
    Statement_Semi Statements_Semi {
        _statement_semi* s = dynamic_cast<_statement_semi*>($1);
        _statements_semi* ss = dynamic_cast<_statements_semi*>($2);
        $$ = new _statements_semi(s,ss);
    }    
    |  {$$ = new _statements_semi();}    
    ;

Function:
    FUNCTION IDENT SEMICOLON BEGIN_PARAMS Declarations_Semi END_PARAMS
    BEGIN_LOCALS Declarations_Semi END_LOCALS BEGIN_BODY Statements_Semi END_BODY {
        _ident* i = new _ident($2);
        _declarations_semi* d1 = dynamic_cast<_declarations_semi*>($5);
        _declarations_semi* d2 = dynamic_cast<_declarations_semi*>($8);
        _statements_semi* s = dynamic_cast<_statements_semi*>($11);
        $$ = new _function(i,d1,d2,s);

    }
    ;

Identifiers:
    IDENT COMMA Identifiers {
        _ident* id = new _ident($1);
        _identifiers* ids = dynamic_cast<_identifiers*>($3);
        $$ = new _identifiers(id,ids);
    }    
    | IDENT {$$ = new _identifiers(new _ident($1));}   
    |  {$$ = new _identifiers();}    
    ;

Declaration:
    Identifiers COLON ENUM L_PAREN Identifiers R_PAREN {


    }    
    | Identifiers COLON INTEGER {
        _ident* i = new _ident($1);
        map<string,_symbol*>::Iterator p = table.insert($1,i);
        i->setPlace(p);
    }    
    | Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
        _ident

    }   
    ;

Vars:
    Var Vars {
        _var* v = dynamic_cast<_var*>($1);
        _vars* vs = dynamic_cast<_vars*>($2);
        $$ = new _vars(v,vs);

    }    
    | COMMA Var Vars {
        _var* v = dynamic_cast<_var*>($2);
        _vars* vs = dynamic_cast<_vars*>($3);
        $$ = new _vars(v,vs);
        $$->setCommaFlag();
    }    
    |  {$$ = new _vars();}    
    ;

Statement:
    Var ASSIGN Expression {
        _var* v = dynamic_cast<_var*>($1);
        _expression* e = dynamic_cast<_expression*>($3);
        $$ = new _statement(v,e);
    }    
    | IF Bool-Expr THEN Statements_Semi ENDIF {
        _bool_expr* b = dynamic_cast<_bool_expr*>($2);
        _statements_semi* s = dynamic_cast<_statements_semi*>($4);
        $$ = new _statement(b,s,1);
    }    
    | IF Bool-Expr THEN Statements_Semi ELSE Statements_Semi ENDIF {
        _bool_expr* be = dynamic_cast<_bool_expr*>($2);
        _statements_semi* ss1 = dynamic_cast<_statements_semi*>($4);
        _statements_semi* ss2 = dynamic_cast<_statements_semi*>($6);
        $$ = new _statement(be,ss1,ss2);
    }    
    | WHILE Bool-Expr BEGINLOOP Statements_Semi ENDLOOP {
        _bool_expr* be = dynamic_cast<_bool_expr*>($2);
        _statements_semi* ss = dynamic_cast<_statements_semi*>($4);
        $$ = new _statement(be,ss,3);
    }    
    | DO BEGINLOOP Statements_Semi ENDLOOP WHILE Bool-Expr {
        _statements_semi* ss = dynamic_cast<_statements_semi*>($3);
        _bool_expr* be = dynamic_cast<_bool_expr*>($6);
        $$ = new _statement(ss,be);
    }    
    | READ Vars  {
        _vars* v = dynamic_cast<_vars*>($2);
        $$ = new _statement("READ", v);
    }    
    | WRITE Vars {
        _vars* v = dynamic_cast<_vars*>($2);
        $$ = new _statement("WRITE", v);
    }    
    | CONTINUE {
        $$ = new _statement("c");
    }    
    | RETURN Expression {
        _expression* e = dynamic_cast<_expression*>($2);
        $$ = new _statement(e);
    }    
    ; 

Relation-And-Exprs: 
    OR Relation-And-Expr Relation-And-Exprs {
        _relation_and_expr* re = dynamic_cast<_relation_and_expr*>($2);
        _relation_and_exprs* res = dynamic_cast<_relation_and_exprs*>($3);
        $$ = new _relation_and_exprs(re,res);
    }    
    | {$$ = new _relation_and_exprs();}    
    ;

Bool-Expr:
    Relation-And-Expr Relation-And-Exprs {
        _relation_and_expr* re = dynamic_cast<_relation_and_expr*>($1);
        _relation_and_exprs* res = dynamic_cast<_relation_and_exprs*>($2);
        $$ = new _bool_expr(re,res);
    }    
    ;

Relation-Exprs:
    AND Relation-Expr Relation-Exprs {
        _relation_expr* re = dynamic_cast<_relation_expr*>($2);
        _relation_exprs* res = dynamic_cast<_relation_exprs*>($3);
        $$ = new _relation_exprs(re,res);
    }    
    | {$$ = new _relation_exprs();}    
    ;

Relation-And-Expr:
    Relation-Expr Relation-Exprs {
        _relation_expr* re = dynamic_cast<_relation_expr*>($1);
        _relation_exprs* res = dynamic_cast<_relation_exprs*>($2);
        $$ = new _relation_and_expr(re,res);

    }    
    ;

Relation-Expr:
    NOT Expression Comp Expression {
        _expression* exp1 = dynamic_cast<_expression*>($2);
        _expression* exp2 = dynamic_cast<_expression*>($4);
        _comp* c = dynamic_cast<_comp*>($3);
        _relation_expr* re = new _relation_expr(exp1,exp2,c);
        re->setNotFlag();
        $$ = re;

    }    
    | NOT TRUE {$$ = new _relation_expr(0);}
    | NOT FALSE {$$ = new _relation_expr(1);}    
    | NOT L_PAREN Bool-Expr R_PAREN {
        _bool_expr* be = dynamic_cast<_bool_expr*>($3);
        $$ = new _relation_expr();

     }    
    | Expression Comp Expression {}    
    | TRUE {$$ = new _relation_expr(1);}    
    | FALSE {$$ = new _relation_expr(0);}    
    | L_PAREN Bool-Expr R_PAREN {}    
    ;

Comp:
    EQ {$$ = new _comp("EQ");}    
    | NEQ {$$ = new _comp("NEQ");}    
    | LT {$$ = new _comp("LT");}    
    | GT {$$ = new _comp("GT");}    
    | LTE {$$ = new _comp("LTE");}    
    | GTE {$$ = new _comp("GTE");}    
    ;

Multiplicative-Exprs:
    ADD Multiplicative-Expr Multiplicative-Exprs {
        _multiplicative_expr* me = dynamic_cast<_multiplicative_expr*>($2);
        _multiplicative_exprs* mes = dynamic_cast<_multiplicative_exprs*>($3);
        $$ = new _multiplicative_exprs(me,mes,"ADD");

    }    
    | SUB Multiplicative-Expr Multiplicative-Exprs {
        _multiplicative_expr* me = dynamic_cast<_multiplicative_expr*>($2);
        _multiplicative_exprs* mes = dynamic_cast<_multiplicative_exprs*>($3);
        $$ = new _multiplicative_exprs(me,mes,"SUB");
    }    
    |  {
        $$ = new _multiplicative_exprs();
    }    
    ; 

Expression:
    Multiplicative-Expr Multiplicative-Exprs {
        _multiplicative_expr* me = dynamic_cast<_multiplicative_expr*>($1);
        _multiplicative_exprs* mes = dynamic_cast<_multiplicative_exprs*>($2);
        $$ = new _expression(me, mes);
    }    
    ;

Terms:
    MULT Term Terms {
        _term* t = dynamic_cast<_term*>($2);
        _terms* ts = dynamic_cast<_terms*>($3);
        $$ = new _terms(t);
        $$->addNode(t,"MULT");
        $$->addNodes(ts);
    }    
        | DIV Term Terms {
            _term* t = dynamic_cast<_term*>($2);
            _terms* ts = dynamic_cast<_terms*>($3);
            $$ = new _terms(t);
            $$->addNode(t,"DIV");
            $$->addNodes(ts);
        }    
        | MOD Term Terms {
                _term* t = dynamic_cast<_term*>($2);
            _terms* ts = dynamic_cast<_terms*>($3);
            $$ = new _terms(t);
            $$->addNode(t,"MOD");
            $$->addNodes(ts);
        }    
        |  {
            $$ = new _terms();
        }    
        ;


Multiplicative-Expr:
    Term Terms {
        _term* t = dynamic_cast<_term*>($1);
        _terms* ts = dynamic_cast<_terms*>($2);
        $$ = new _multiplicative_expr(t,ts);
    }    
    ;

Expressions:
    Expression Expressions {
        _expression* e = dynamic_cast<_expression*>($1);
        _expressions* es = dynamic_cast<_expressions*>($2);
        $$ = new _expressions(e,es);


    }    
    | COMMA Expression Expressions {
        _expression* e = dynamic_cast<_expression*>($2);
        _expressions* es = dynamic_cast<_expressions*>($3);
        $$ = new _expressions(e,es);
        $$->setCommaFlag();
    }    
    |  {
        $$ = new _expressions();
    }    
    ;

Term:
    SUB Var {
       $$ = new _term( dynamic_cast<_var*>($2), 1);
    }    
    | SUB NUMBER {
       $$ = new _term( new _number($2), 1);
    }    
    | SUB L_PAREN Expression R_PAREN {
       $$ = new _term( dynamic_cast<_expression*>($3), 1);
    } 
    | Var {
        $$ = new _term( dynamic_cast<_var*>($1), 0);
    }    
    | NUMBER {
        $$ = new _term( new _number($1), 0);
    }    
    | L_PAREN Expression R_PAREN {
        $$ = new _term( dynamic_cast<_expression*>($2), 0);
    }    
    | IDENT L_PAREN Expressions R_PAREN {
        //function call
        $$ = new _term( new _ident($1), dynamic_cast<_expressions*>($3));
    }    
    ;

Var: 
    //variable is either an identifier or an array element.
    IDENT {
        $$ = new _var(new _ident($1)); 
    }    
    | IDENT L_SQUARE_BRACKET Expression R_SQUARE_BRACKET {
        $$ = new _var(new _ident($1), dynamic_cast<_expression*>($3));
    }   

    ;

%% 


void yyerror(const char *msg) {
	printf("Error: Line: %s, Col: %s \n", currLine, currCol);
}

int main(int argc, char ** argv) {
	yyparse();
	return 1;
}