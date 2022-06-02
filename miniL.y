    /* cs152-miniL phase2 */

%{

#include "lib.h"

extern int currLine;
extern int currCol;
extern int yylex(void);
void yyerror(const char *msg);


TableManager tm;
bool errorFlag = 0;
string filename = "default.mil";
%}

%define api.value.type {union YYSTYPE}
%error-verbose
%start Program
%token<str_val> IDENT NUMBER;
%type<sym_val> Identifiers %type<sym_val> Declaration %type<sym_val> Var %type<sym_val> Term %type<sym_val> Terms %type<sym_val> Multiplicative-Expr %type<sym_val> Relation-Expr %type<sym_val> Expression %type<sym_val> Expressions %type<sym_val> Multiplicative-Exprs %type<sym_val> Comp %type<sym_val> Relation-Exprs %type<sym_val> Bool-Expr %type<sym_val> Relation-And-Expr %type<sym_val> Relation-And-Exprs %type<sym_val> Vars %type<sym_val> Statement %type<sym_val> Statements  %type<sym_val> Declarations %type<sym_val> Function %type<sym_val> Functions %type<sym_val> Program;
%left FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN;
%% 

Program:
   Functions {
    if(!tm.checkFunction("main")){
        yyerror("main function not found");
    }
    if(errorFlag){exit(1);}
    fstream outfile;
    outfile.open(filename, fstream::out);
    outfile << $1->getCode();
    outfile.close();


   }   
    | {
        yyerror("No program found");
    }   
    ;

//Functions will need their own symbol table pushed onto the stack.
Function:
    FUNCTION IDENT SEMICOLON BEGIN_PARAMS Declarations END_PARAMS
    BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY {

        
        string n = string($2);
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_");

        if(space_index != -1){
            n = n.substr(0,space_index);
        }
        else{
            n = n;
        }
        if(tm.checkFunction(n)){
            yyerror("Function already exists");
        }
        else{
            tm.addFunction(n);
        }
     
        symbol* d1 = ($5);
        string code = "func " + n + '\n';
        symbol* d2 = ($8);
        symbol* s = ($11);
        istringstream iss(d1->getCode());
        string line;
        string new_code = "";
        int count = 0;
        while(getline(iss,line)){
            
            new_code += line + '\n';
            if(line.find("__") == -1){
                new_code += "= " + line.substr(2,line.length()-1) + ", $" + to_string(count) + '\n';
                count++;
            }
        }

        code += new_code + d2->getCode() + s->getCode();
        code += "endfunc\n\n";
        $$ = new symbol(n, code);
  
    }
    ;


Functions:
    Function Functions {
        symbol* f = ($1);
        symbol* fs = ($2);
        string code = f->getCode() + fs->getCode();
        vector<string> names = fs->getNames();
        if(f->getName() != ""){
            names.push_back(f->getName());
        }
        $$ = new symbol("", code);
        $$->setNames(names);
    }    
    |  {
        $$ = new symbol();
    }    
    ;


Statement:
    Var ASSIGN Expression SEMICOLON {
        symbol* v = ($1);
        symbol* e = ($3);
        string code = v->getCode() + e->getCode();

        //if the variable is an array element
        if(v->getIndex() != ""){
            
            code += "[]= " + v->getName() + ", " + v->getIndex() + ", " + e->getName() + '\n';
        }
        else{
            code += "= " + v->getName() + ", " + e->getName() + '\n';
        }
        
        $$ = new symbol("", code);
        $$->setNames(v->getNames());
        $$->addNames(e->getNames());

    }    
    | IF Bool-Expr THEN Statements ENDIF SEMICOLON {
        symbol* b = ($2);
        symbol* s = ($4);
        string temp = tm.getTemp();
        string code = b->getCode();
        string label = tm.getLabel();
        code += ". " + temp + '\n';
        code += "! " + temp + ", " + b->getName() + '\n';
        code += "?:= " + label + ", " + temp + '\n';
        code += s->getCode();
        code += ": " + label + '\n';
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(b->getNames());
        


    }    
    | IF Bool-Expr THEN Statements ELSE Statements ENDIF SEMICOLON {
        symbol* b = ($2);
        symbol* s1 = ($4);
        symbol* s2 = ($6);
        string code = "";
        string label = tm.getLabel();
        string label2 = tm.getLabel();
        string temp = tm.getTemp();
        code += ". " + temp + "\n";
        code += "! " + temp + ", " + b->getName() + "\n";
        code += "?:= " + label + ", " + temp + "\n";
        code += s1->getCode();
        code += ":= " + label2 + "\n";
        code += ": " + label + "\n";
        code += s2->getCode();
        code += ": " + label2 + "\n";
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(s1->getNames());
        $$->addNames(s2->getNames());
    }    
    | WHILE Bool-Expr BEGINLOOP Statements ENDLOOP SEMICOLON {
        symbol* b = ($2);
        symbol* s = ($4);
        string code = b->getCode();
        string label = tm.getLabel();
        string label2 = tm.getLabel();
        string temp = tm.getTemp();
        code += ": " + label + "\n";
        code += b->getCode();
        code += ". " + temp + "\n";
        code += "! " + temp + ", " + b->getName() + "\n";
        code += "?:= " + label2 + ", " + temp + "\n";
        code += s->getCode();
        code += "?:= " + label + ", " + b->getName() + "\n";
        code += ": " + label2 + "\n";
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(b->getNames());
        $$->addNames(s->getNames());


    }    
    | DO BEGINLOOP Statements ENDLOOP WHILE Bool-Expr SEMICOLON {
        symbol* s = ($3);
        symbol* b = ($6);
        string code = b->getCode();
        string label = tm.getLabel();
        code += ": " + label + "\n";
        code += s->getCode();
        code += "?:= " + label + ", " + b->getName() + "\n";
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(s->getNames());
        $$->addNames(b->getNames());

    }    
    | READ Vars SEMICOLON  {
        symbol* v = ($2);
        string code = v->getCode();
        string name = "";
        vector<string> names = v->getNames();
        for(int i = 0; i < names.size(); i++){
            int type = tm.checkType(names[i]);
            if(type == 0){
                code += ".< " + names[i] + '\n';
            }
            else{
                code += ".[]< " + names[i] + ", " + to_string(type) + '\n';
            }
        }
        $$ = new symbol(name, code);
        $$->setNames(names);
        


    }    
    | WRITE Vars SEMICOLON {
        symbol* v = ($2);
        string code = v->getCode();
        string name = "";
        vector<string> names = v->getNames();
        for(int i = 0; i < names.size(); i++){
            int type = tm.checkType(names[i]);
            if(type == 0){
                code += ".> " + names[i] + '\n';
            }
            else{
                code += ".[]> " + names[i] + ", " + to_string(type) + '\n';
            }
        }
        $$ = new symbol(name, code);
        $$->setNames(names);

    }    
    | CONTINUE SEMICOLON {
        string name = "";
        string code = ": " + tm.getLastLabel() + "\n";
        $$ = new symbol(name, code);
    }    
    | RETURN Expression SEMICOLON {
        symbol* e = ($2);
        string code = e->getCode();
        code += "ret " + e->getName() + "\n";
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(e->getNames());
    }    
    ; 



Statements:
    Statement Statements {
        symbol* s = ($1);
        symbol* ss = ($2);
        string code = s->getCode() + ss->getCode();
        vector<string> names = s->getNames();
        if(s->getName() != ""){
            names.push_back(s->getName());
        }
        $$ = new symbol("", code);
        
        $$->addName(s->getName());
        $$->addNames(ss->getNames());
    }    
    |  {
        $$ = new symbol();
    }    
    ;


Bool-Expr:
    Relation-And-Expr Relation-And-Exprs {
        symbol* r = ($1);
        symbol* rs = ($2);

        string code = r->getCode() + rs->getCode();
        string temp = tm.getTemp();
        code += ". " + temp + '\n';
        code += "= " + temp + ", " + r->getName() + '\n';
        vector<node> nodes = rs->getNodes();
        for(int i = 0; i < nodes.size(); i++){
            if(nodes[i].getName() == "" || nodes[i].getOp() == ""){
                continue;
            }
            code += nodes[i].getOp() + temp + ", " + nodes[i].getName() + '\n';
        }

        $$ = new symbol(temp, code);
        $$->setNames(rs->getNames());
        $$->addName(r->getName());

    }    
    ;

Relation-And-Exprs: 
    OR Relation-And-Expr Relation-And-Exprs {
        symbol* r = ($2);
        symbol* rs = ($3);
        string code = r->getCode() + rs->getCode();

        $$ = new symbol("", code);
        $$->addNodes(rs->getNodes());
        $$->addNode(r->getName(), "||");
        $$->setNames(rs->getNames());
        $$->addName(r->getName());
    }    
    | {
        $$ = new symbol();
    }    
    ;

Relation-And-Expr:
    Relation-Expr Relation-Exprs {
        symbol* r = ($1);
        symbol* rs = ($2);

        string code= r->getCode() + rs->getCode();
        string temp = tm.getTemp();
        code += ". " + temp + '\n';
        code += "= " + temp + ", " + r->getName() + '\n';
        vector<node> nodes = rs->getNodes();
        for(int i = 0; i < nodes.size(); i++){
            if(nodes[i].getOp() == "" || nodes[i].getName() == ""){
                continue;
            }
            code += nodes[i].getOp() + " " + temp + ", " + temp + ", " + nodes[i].getName() + '\n';
        }

        $$ = new symbol(temp, code);
        $$->setNames(rs->getNames());
        $$->addName(r->getName());


    }    
    ;

Relation-Exprs:
    AND Relation-Expr Relation-Exprs {
        symbol* r = ($2);
        symbol* rs = ($3);
        string code = r->getCode() + rs->getCode();
        $$ = new symbol("", code);
        $$->addNodes(rs->getNodes());
        $$->addNode(r->getName(), "&&");
        $$->setNames(rs->getNames());
        $$->addName(r->getName());

    }    
    | {
        $$ = new symbol();
    }    
    ;

Relation-Expr:
    NOT Expression Comp Expression {
        symbol* e = ($2);
        symbol* e2 = ($4);
        symbol* c = ($3);
        string dest_var = tm.getTemp();
        string not_var = tm.getTemp();
        string code = e->getCode() + e2->getCode();
        code += ". " + dest_var + '\n';
        code += ". " + not_var + '\n';
        code += c->getCode() + " " + dest_var + ", " + e->getName() + ", " + e2->getName() + '\n';
        code += "! " + not_var + ", " + dest_var + '\n';
        $$ = new symbol(not_var, code);
        $$->addNames(e->getNames());
        $$->addNames(e2->getNames());


    }    
    | NOT TRUE {
        $$ = new symbol("0", "");
    }
    | NOT FALSE {
        $$ = new symbol("1", "");
    }    
    | NOT L_PAREN Bool-Expr R_PAREN {
        symbol* b = ($3);
        string code = b->getCode();
        string temp = tm.getTemp();
        code += ". " + temp + '\n';
        code += "= " + temp + ", " + b->getName() + '\n';
        code += "! " + temp + ", " + temp + '\n';
        $$ = new symbol(temp, code);
        $$->setNames(b->getNames());
     }    
    | Expression Comp Expression {
        symbol* e = ($1);
        symbol* e2 = ($3);
        symbol* c = ($2);
        string dest_var = tm.getTemp();
        string code = e->getCode() + e2->getCode();
        code += ". " + dest_var + '\n';
        code += c->getCode() + " " + dest_var + ", " + e->getName() + ", " + e2->getName() + '\n';
        $$ = new symbol(dest_var, code);
        $$->addName(e->getName());
        $$->addName(e2->getName());

    }    
    | TRUE {
        $$ = new symbol("1", "");
    }    
    | FALSE {
        $$ = new symbol("0", "");
    }    
    | L_PAREN Bool-Expr R_PAREN {
        symbol* b = ($2);
        $$ = new symbol(b->getName(), b->getCode());
        $$->setNames(b->getNames());
    }    
    ;

Comp:
    EQ { $$ = new symbol("==", "==") ; }
    | NEQ {     $$ = new symbol("!=", "!=") ; } 
    | LT {   $$ = new symbol("<", "<") ; } 
    | GT {  $$ = new symbol(">", ">") ; } 
    | LTE {     $$ = new symbol("<=", "<=") ; } 
    | GTE {    $$ = new symbol(">=", ">=") ; } 
    ;

Multiplicative-Expr:
    Term Terms {
        symbol* t = ($1);
        symbol* ts = ($2);

        string code = t->getCode() + ts->getCode();
        string temp = tm.getTemp();

        code += ". " + temp + '\n';
        code += "= " + temp + ", " + t->getName() + '\n';
        vector<node> nodes = ts->getNodes();
        for(int i = 0; i < nodes.size(); i++){
            if(nodes[i].getOp() == "" || nodes[i].getName() == ""){
                continue;
            }
            code += nodes[i].getOp() + " " + temp + ", " + temp + ", " + nodes[i].getName() + '\n';
        }


        $$ = new symbol(temp, code);
        $$->setNames(ts->getNames());
        $$->addName(t->getName());

 
    }
    ;

Multiplicative-Exprs:
    ADD Multiplicative-Expr Multiplicative-Exprs {
        symbol* m = ($2);
        symbol* ms = ($3);
        string code = m->getCode() + ms->getCode();


        $$ = new symbol("", code);
        $$->addNodes(ms->getNodes());
        $$->addNode(m->getName(), "+");
        $$->setNames(ms->getNames());
        $$->addName(m->getName());
        


    }    
    | SUB Multiplicative-Expr Multiplicative-Exprs {
       
        symbol* m = ($2);
        symbol* ms = ($3);
        string code = m->getCode() + ms->getCode();
        $$ = new symbol("", code);
        $$->addNodes(ms->getNodes());
        $$->addNode(m->getName(), "-");
        $$->setNames(ms->getNames());
        $$->addName(m->getName());
        


    }    
    |  {
        $$ = new symbol();
    }    
    ; 

Expression:
    Multiplicative-Expr Multiplicative-Exprs {
        symbol* m = ($1);
        symbol* ms = ($2);

        string code = m->getCode() + ms->getCode();
        string temp = tm.getTemp();
        code += ". " + temp + '\n';
        code += "= " + temp + ", " + m->getName() + '\n';

        vector<node> nodes = ms->getNodes();
        for(int i = 0; i < nodes.size(); i++){
            if(nodes[i].getName() == "" || nodes[i].getOp() == ""){
                continue;
            }
            code += nodes[i].getOp() + " " + temp + ", " + temp + ", " + nodes[i].getName() + "\n";
        }

        $$ = new symbol(temp, code);
        $$->setNames(ms->getNames());
        $$->addName(m->getName());
        
    }    
    ;

Expressions:
    Expression Expressions {
        symbol* e = ($1);
        symbol* es = ($2);
        string code = e->getCode() + es->getCode();
        vector<string> names = es->getNames();
        
        $$ = new symbol("", code);
        $$->setNames(names);
        $$->addName(e->getName());
        
    }    
    | COMMA Expression Expressions {
        symbol* e = ($2);
        symbol* es = ($3);
        string code = e->getCode() + es->getCode();
        vector<string> names = es->getNames();
        string name = "";
        $$ = new symbol(name, code);
        $$->setNames(names);
        $$->addName(e->getName());
        
        
    }    
    |  {
        $$ = new symbol();
    }    
    ;

Term:

    SUB Var {
        symbol* s = ($2);
        string code = s->getCode();
        string name = tm.getTemp();
        //if it isn't a array element
        if(s->getIndex() == ""){
            code += ". " + name + '\n';
            
        }
        else{
            code += ".[] " + name + ", " + s->getIndex() + '\n';
        }

        code += "* " + name + ", -1, " + s->getName() + "\n";
        
        $$ = new symbol(name, code);
        $$->addName(s->getName());

    }    
    | SUB NUMBER {
        string num = string($2);
        num = '-' + num;
        string code = "";
        $$ = new symbol(num, code);
        
    }    
    | SUB L_PAREN Expression R_PAREN {
        
        symbol* s = ($3);
        string code = "";
        string name = tm.getTemp();
        code += ". " + name + '\n';
        code += "* " + name + ", -1, " + s->getName() + "\n";
        $$ = new symbol(name, code);
        $$->setNames(s->getNames());

    } 
    | Var {
        $$ = $1;
        
    }    
    | NUMBER {
       $$ = new symbol($1, "");
    }    
    | L_PAREN Expression R_PAREN {
       
        $$ = $2;
    }    
    | IDENT L_PAREN Expressions R_PAREN {
        
        string func_name = string($1);
        int space_index = func_name.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_");
        if(space_index != -1){
            func_name = func_name.substr(0,space_index);
        }

        symbol* s = ($3);
        vector<string> params = s->getNames();
        string temp = tm.getTemp();
        string code = s->getCode();
        code += ". " + temp + '\n';
        for(int i = 0; i < params.size(); i++) {
            code += "param " + params[i] + '\n';
        }
        code += "call " + func_name + ", " + temp + '\n';
        $$ = new symbol(temp, code);
        $$->setNames(s->getNames());
        
        
    }   
    ;

Terms:
    MULT Term Terms {
        symbol* t = ($2);
        symbol* ts = ($3);
        string code = t->getCode() + ts->getCode();
        $$ = new symbol("", code);
        $$->addNodes(ts->getNodes());
        $$->addNode(t->getName(), "*");
        $$->setNames(ts->getNames());
        $$->addName(t->getName());
    }    
    | DIV Term Terms {
        symbol* t = ($2);
        symbol* ts = ($3);     
        string code = t->getCode() + ts->getCode();
        $$ = new symbol("", code);
        $$->addNodes(ts->getNodes());
        $$->addNode(t->getName(), "/");
        $$->setNames(ts->getNames());
        $$->addName(t->getName());
        
    }    
    | MOD Term Terms {
        
        symbol* t = ($2);
        symbol* ts = ($3);
        string code = t->getCode() + ts->getCode();
        $$ = new symbol("", code);
        $$->addNodes(ts->getNodes());
        $$->addNode(t->getName(),"%");
        $$->setNames(ts->getNames());
        $$->addName(t->getName());

    }    
    |  {
        $$ = new symbol();
    }    
    ;

Var: 
    //variable is either an identifier or an array element.
    IDENT { 
        
        string n = string($1);
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_");

        if(space_index != -1){
            n = n.substr(0,space_index);
        }
        else{
            n = n;
        }
        if(tm.checkType(n) == -1){
            yyerror(("Undefined variable: " + n).c_str());
        }
        string code = "";

        
        $$ = new symbol(n, code);
        $$->addName(n);
        
        
    }    
    | IDENT L_SQUARE_BRACKET Expression R_SQUARE_BRACKET {
        
        string n = string($1);
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_");

        if(space_index != -1){
            n = n.substr(0,space_index);
        }
        else{
            n = n;
        }
        if(tm.checkType($1) == -1){
            yyerror(("Undefined variable: " + n).c_str());
        }
        else if(tm.checkType($1) == 0){
            yyerror(("Variable " + n + " is not an array.").c_str());
        }
        symbol* s = ($3);
        string code = s->getCode();
        
        n += '.' + s->getName() + '\n';
        
        $$ = new symbol(n, code);
        $$->setIndex(s->getName());
        $$->setNames(s->getNames());
        

        
        
    }   

    ;

Vars:
    Var Vars {
        symbol* v = ($1);
        symbol* vs = ($2);
        string name = v->getName();
        vector<string> names = vs->getNames();
        string code = v->getCode() + vs->getCode();
        $$ = new symbol(name, code);
        $$->setNames(names);
        $$->addName(name);


    }    
    | COMMA Var Vars {
        symbol* v = ($2);
        symbol* vs = ($3);
        string name = v->getName();
        vector<string> names = vs->getNames();
        string code = v->getCode() + vs->getCode();
        $$ = new symbol(name, code);
        $$->setNames(names);
        $$->addName(name);
    }    
    |  {
        $$ = new symbol();
     }    
    ;


Declaration:
    Identifiers COLON ENUM L_PAREN Identifiers R_PAREN SEMICOLON{
        symbol* i1 = $1;
        symbol* i2 = $5;
        vector<string> params = i2->getNames();
        vector<string> names = i1->getNames();
        string code = i1->getCode() + i2->getCode();

        for(int i = 0; i < names.size(); i++){
            tm.add(names[i], -2);
            code += ". " + names[i] + '\n';
            for(int j = 0; j < params.size(); j++){
                code += ". " + params[j] + '\n';
                code += "= " + params[j] + ", " + to_string(j) + '\n';
            }
        }
        $$ = new symbol("", code);
        $$->addNames(i2->getNames());
        $$->addNames(i1->getNames());

    }    
    | Identifiers COLON INTEGER SEMICOLON {
        
        symbol* s = ($1);
        string code = s->getCode();
        vector<string> names = s->getNames();

        for(int i = 0; i < names.size(); i++) {
            tm.add(names[i], 0);
            code += ". " + names[i] + "\n";
        }

        $$ = new symbol("", code);
        $$->setNames(names);




    }    
    | Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER SEMICOLON {
        symbol* s = ($1);
       
        string num = string($5);
        string code = s->getCode();
        vector<string> names = s->getNames();

        for(int i = 0; i < names.size(); i++) {
            tm.add(names[i], stoi(num));
            code += ".[] " + names[i] + ", " + num + "\n";
        }

        $$ = new symbol("", code);
        $$->setNames(names);
        $$->setSize(num);
    }   
    ;
  
    ;

Declarations:
    Declaration Declarations {
        symbol* s1 = ($1);
        symbol* s2 = ($2);
        string code = s1->getCode() + s2->getCode();
        $$ = new symbol("", code);
        $$->addNames(s2->getNames());
        $$->addName(s1->getName());
    }    
    | {
        $$ = new symbol();
    }    
    ;

//Identifiers is a list of identifiers. Separated by new lines.
Identifiers:
    IDENT COMMA Identifiers {
        
        $$ = new symbol();
        $$->addNames($3->getNames());
        $$->addName($1);
    }    
    | IDENT {
        $$ = new symbol();
        $$->addName($1);
    }   
    |  {
        $$ = new symbol();
    }    
    ;


%% 


void yyerror(const char *msg) {
    cout << "Error: " << msg << ", Line: " << currLine <<  ",  Col: " << currCol <<  "\n";
    errorFlag = true;
}

int main(int argc, char ** argv) {

	yyparse();
	return 1;
}