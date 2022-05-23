#pragma once

#include <iostream>
#include <string>
#include <vector>
#include <stack>
#include <map>
#include <list>

using namespace std;

class _expression;
class _expressions;
class _var;
class _bool_expr;
class _statements_semi;
class _relation_and_exprs;

class _symbol{
    public:
    //virtual string getType()=0;
    //virtual void setName(string)=0;
    virtual map< string,_symbol* >::iterator getPlace()=0;
};

class _ident : public _symbol{
    private:
    string name;
    string type;
    int size;
    map< string,_symbol* >::iterator place;

    public:
    string getName(){ return name; }
    string getType(){ return type; }
    string getCode(){ 
        if(type == "SCALAR"){
            return ". " + name;
        }
        else{
            return ". [] " + name + ", " + to_string(size);
        }
    }
    void setName(string n){name = n;}
    void setType(string t){type = t;}
    _ident(){ name = type = ""; size = 0; }
    _ident(string n){
        name = n;
        type = "NULL";
    }

    void setPlace(map<string,_symbol*>::iterator i){
        place = i;
    }
    map< string,_symbol* >::iterator getPlace(){
        return place;
    }


};

class _number : public _symbol{
    
    private:
    string value;


    public:
    string getType(){ return "_number"; }
    string getValue(){ return value; }
 
    _number(){ value = ""; }
    _number(string n){ value = n; }
  

};

class _array : public _symbol{

    private:
    _ident* id;
    vector<_symbol*> elements;

    public:
    string getType(){ return "_array"; }
    

};

class _term : public _symbol{
    private:
    _ident* id;
    _number* num;
    _expression* expr;
    _expressions* exprs;
    _var* var;
    int subFlag;
    int inner_type;

    public:

    _term(){
        id = NULL;
        num = NULL;
        expr = NULL;
        exprs = NULL;
        var = NULL;
        subFlag = 0;
        inner_type = -1;
    }
    _term(_var* v, int s){ _term(); var = v; subFlag = s; inner_type = 0; }
    _term(_number* n, int s){ _term(); num = n; subFlag = s; inner_type = 1; }
    _term(_expression* e, int s){ _term(); expr = e; subFlag = s; inner_type = 2;}
    _term(_ident* i, _expressions* es){ _term(); id = i; exprs = es; subFlag = 0; inner_type = 3; }
    string getPlace(){
        switch(inner_type){
            case 0:
                return var->getPlace();
                break;
            case 1:
                return num->getPlace();
                break;
            case 2:
                return expr->getPlace();
                break;
            case 3:
                //add array access
                break;
            default:
                break;
        }
    }

   
};

struct node{
    _term* t;
    string op;

    node(_term* _t, string _op){t = _t; op = _op;}
};

class _terms : public _symbol{
    
    private:
    list<node> terms_list;
    int epsilonFlag;

    public:



    _terms(){
        epsilonFlag = 1;
    }
    
    _terms(_term* t){
        terms_list.push_back(node(t,""));
    }

    void addNode(_term* t, string op){
        terms_list.push_back(node(t,op));
    }

    void addNodes(_terms* t){
        
        if(t && !t->checkEmpty()){
            list<node>::iterator it = t->getList().begin();
            terms_list.insert(it,terms_list.back());
        }
    }

    list<node> getList(){ return terms_list; }
    bool checkEmpty(){ return terms_list.empty(); }

    string getType(){ return "_terms"; }
    

};

class _multiplicative_expr : public _symbol{
    private:
    _term* term;
    _terms* terms;

    public:
    string getType(){return "_multiplicative_expr";}
    _multiplicative_expr(){
        term = NULL;
        terms = NULL;
    }

    _multiplicative_expr(_term* t, _terms* ts){
        term = t;
        terms = ts;

    }


};

class _multiplicative_exprs : public _symbol{
    private:
    _multiplicative_expr* mult_expr;
    _multiplicative_exprs* mult_exprs;
    string op;
    int epsilonFlag;

    public:
    string getType(){ return "_multiplicative_exprs"; }
    _multiplicative_exprs(){
        mult_expr = NULL;
        mult_exprs = NULL;
        op = "";
        epsilonFlag = 1;
    }
    _multiplicative_exprs(_multiplicative_expr* me, _multiplicative_exprs* mes, string o){
        _multiplicative_exprs();
        mult_expr = me;
        mult_exprs = mes;
        op = o;
        epsilonFlag = 0;
    }

};  



class _expression : public _symbol{
    private:
    _multiplicative_expr* mult_expr;
    _multiplicative_exprs* mult_exprs;

    public:
    string getType(){ return "_expression"; }
    string getValue(){ return "";}
    _expression(_multiplicative_expr* me, _multiplicative_exprs* mes){
        mult_expr = me;
        mult_exprs = mes;
    }

};

class _expressions : public _symbol{
    private:
    _expression* exp;
    _expressions* exps;
    int commaFlag;
    int epsilonFlag;

    public:
    string getType(){ return "_expressions"; }
    _expressions(){
        exp = NULL;
        exps = NULL;
        commaFlag = 0;
        epsilonFlag = 1;
    }
    _expressions(_expression* e, _expressions* es){exp = e; exps = es;}
    void setCommaFlag(){commaFlag = 1;}
    void setEpsilonFlag(){epsilonFlag = 1;}

};

class _var : public _symbol{
    
    private:
    _ident* id;
    _expression* expr;

    public:
    string getType(){ 
        return "_var";
    }

    string getName(){
        if(id){ return id->getName(); }
      
    }

    _var(){ id = NULL; expr = NULL; }
    _var(_ident* i, _expression* e){ id = i; expr = e; }
    _var(_ident* i){id = i;}


};

class _vars : public _symbol{
    private:
    _var* var;
    _vars* vars;
    int commaFlag;
    int epsilonFlag;

    public:
    string getType(){ return "_vars"; }
    _vars(){
        var = NULL;
        vars = NULL;
        commaFlag = 0;
        epsilonFlag = 1;
    }
    _vars(_var* v, _vars* vs){
        var = v;
        vars = vs;
        commaFlag = 0;
    }
    void setCommaFlag(){commaFlag = 1;}

};

class _comp : public _symbol{
    private:
    string op;

    public:
    string getType(){ return "_comp"; }
    _comp(string o){
        op = o;
    }

    
};

class _relation_expr : public _symbol{
    private:
    int notFlag;
    _expression* expr1, *expr2;
    _comp *comp;
    int evalFlag;
    _bool_expr* bool_expr;
    int value;

    public:
    string getType(){ return "_relation_expr"; }
    _relation_expr(){
        notFlag = 0;
        expr1 = NULL;
        expr2 = NULL;
        comp = NULL;
        evalFlag = 0;
        bool_expr = NULL;
        value = 0;

    }
    _relation_expr(_expression* e1, _expression* e2, _comp* c){
        _relation_expr();
        expr1 = e1;
        expr2 = e2;
        comp = c;
    }

    _relation_expr(int v){
        _relation_expr();
        value = v;
    }

    void setNotFlag(){notFlag = 1;}
    void setEvalFlag(){evalFlag = 1;}


};

class _relation_exprs : public _symbol{
    private:
    _relation_expr* rel_expr;
    _relation_exprs* rel_exprs;
    int epsilonFlag;

    public:
    string getType(){ return "_relation_exprs"; }
    _relation_exprs(){
        rel_expr = NULL;
        rel_exprs = NULL;
        epsilonFlag = 1;
    }
    _relation_exprs(_relation_expr* re, _relation_exprs* res){
        rel_expr = re;
        rel_exprs = res;
    }
};

class _relation_and_expr : public _symbol{
    private:
    _relation_expr* rel_expr;
    _relation_exprs* rel_exprs;


    public:
    string getType(){ return "_relation_and_exprs"; }
    _relation_and_expr(){
        rel_expr = NULL;
        rel_exprs = NULL;
    }
    _relation_and_expr(_relation_expr* re, _relation_exprs* res){
        rel_expr = re;
        rel_exprs = res;
    }
    
};

class _relation_and_exprs : public _symbol{
    private:
    _relation_and_expr* rel_and_expr;
    _relation_and_exprs* rel_and_exprs;
    int epsilonFlag;

    public:
    string getType(){ return "_relation_and_exprs"; }
    _relation_and_exprs(){
        rel_and_expr = NULL;
        rel_and_exprs = NULL;
        epsilonFlag = 1;
    }
    _relation_and_exprs(_relation_and_expr* re, _relation_and_exprs* res){
        rel_and_expr = re;
        rel_and_exprs = res;
    }

};

class _bool_expr : public _symbol{
    private:
    _relation_and_expr* rel_and_expr;
    _relation_and_exprs* rel_and_exprs;
    int value;

    public:
    string getType(){ return "_bool_expr"; }
    _bool_expr(){
        rel_and_expr = NULL;
        rel_and_exprs = NULL;
    }
    _bool_expr(_relation_and_expr* re, _relation_and_exprs* res){
        rel_and_expr = re;
        rel_and_exprs = res;

    }
    int getValue(){return value;}
};

class _statement : public _symbol{
    private:
    _var* var;
    _vars* vars;
    _bool_expr* bool_expr;
    _statements_semi* statement_semi1, *statement_semi2;
    _expression* expr;
    int inner_type;

    public:
    string getType(){ return "_statement"; }
    _statement(){
        var = NULL;
        vars = NULL;
        bool_expr = NULL;
        statement_semi1 = statement_semi2 = NULL;
        inner_type = -1;
    }
    _statement(_var* v, _expression* e){
        _statement();
        var = v;
        expr = e;
        inner_type = 0;
    }
    _statement(_bool_expr* be, _statements_semi* ss, int i){
        _statement();
        bool_expr = be; 
        statement_semi1 = ss;
        inner_type = i;
    }
    _statement(_bool_expr* be, _statements_semi* ss1, _statements_semi* ss2){
        _statement();
        bool_expr = be; 
        statement_semi1 = ss1;
        statement_semi2 = ss2;
        inner_type = 2;
    }
    _statement(_statements_semi* s, _bool_expr* b){
        _statement();
        bool_expr = b; 
        statement_semi1 = s;
        inner_type = 4;
    }
    _statement(string s, _vars* v){
        _statement();
        vars = v;
        if(s == "READ"){
            inner_type = 5;
        }
        else inner_type = 6;
    }
    _statement(string x){
        _statement();
        inner_type = 7;
    }
    _statement(_expression* e){
        _statement();
        expr = e;
        inner_type = 8;
    }


};

class _declaration : public _symbol{
    private:
    _ident* ident1;
    _ident* ident2;
    string userType;
    _number* size;


    public:
    string getType(){ return "_declaration"; }
    _declaration(){}
    _declaration(_ident* id1, _ident* id2){
        ident1 = id1;
        ident2 = id2;
    }
    _declaration(_ident* i){ 
        ident1 = i;
        userType = "integer";
    }
    _declaration(_ident* i, _number* n){
        ident1 = i;
        size = n;
        userType = "array";
    }
    ~_declaration(){
        if(ident1){delete ident1;}
        if(ident2){delete ident2;}
        if(size){delete size;}
    }
};


class _statement_semi : public _symbol{
    private:
    _statement* statement;

    public:
    string getType(){ return "_statement_semi"; }
    _statement_semi(_statement* s){
        statement = s;
    }
};

class _statements_semi : public _symbol{
    private:
    _statement_semi* state_semi;
    _statements_semi* states_semi;
    int epsilonFlag;

    public:
    string getType(){ return "_statements_semi"; }
    _statements_semi(){
        state_semi = NULL;
        states_semi = NULL;
        epsilonFlag = 1;
    }
    _statements_semi(_statement_semi* s, _statements_semi* ss){
        state_semi = s;
        states_semi = ss;
        epsilonFlag = 0;
    }
    
};

class _declaration_semi : public _symbol{
    private:
    _declaration* decl;

    public:
    string getType(){ return "_declaration_semi"; }
    _declaration_semi(_declaration* d){
        decl = d;
    }
};

class _declarations_semi : public _symbol{
    private:
    _declaration_semi* decl_semi;
    _declarations_semi* decls_semi;
    int epsilonFlag;

    public:
    string getType(){ return "_declarations_semi"; } 
    _declarations_semi(){
        decl_semi = NULL;
        decls_semi = NULL;
        epsilonFlag = 1;
    }
    _declarations_semi(_declaration_semi* ds, _declarations_semi* dss){
        decl_semi = ds;
        decls_semi = dss;
        epsilonFlag = 0;
    }
};

class _function : public _symbol{
    private:
    _ident* ident;
    _declarations_semi* decl_semi1, *decl_semi2;
    _statements_semi* state_semi;

    public:
    string getType(){ return "_function"; } 
    _function(_ident* i, _declarations_semi* d1, _declarations_semi* d2, _statements_semi* s){
        ident = i;
        decl_semi1 = d1;
        decl_semi2 = d2;
        state_semi = s;
    }

};

class _functions : public _symbol{
    private:
    _function* function;
    _functions* functions;
    int epsilonFlag;

    public:
    string getType(){ return "_functions"; }
    _functions(){
        function = NULL;
        functions = NULL;
        epsilonFlag = 1;
    }
    _functions(_function* f, _functions* fs){
        function = f;
        functions = fs;
        epsilonFlag = 0;
    }
    
};

class _program : public _symbol{
    private:
    _functions* functions;
    int epsilonFlag;

    public:
    string getType(){ return "_program"; }
    _program(){
        functions = NULL;
        epsilonFlag = 1;
    }
    _program(_functions* fs){
        functions = fs;
        epsilonFlag = 0;
    }
};

class _identifiers : public _symbol {
    private:
    _ident* id;
    _identifiers* ids;
    int commaFlag;
    int epsilonFlag;

    public:
    string getType(){ return "_identifiers"; }
    _identifiers(){
        id = NULL;
        ids = NULL;
        commaFlag = 0;
        epsilonFlag = 1;
    }

    _identifiers(_ident* _id, _identifiers* _ids){
        id = _id;
        ids = _ids;
        commaFlag = 1;
        epsilonFlag = 0;
    }

    _identifiers(_ident* _id){
        id = _id;
        ids = NULL;
        commaFlag = epsilonFlag = 0;
    }
    _ident* getID(){return id;}
    _identifiers* getIDS(){return ids;}

    //recursively set all types.
    void setType(_identifiers* i, string t){
        i->getID()->setType(t);
        ids = i->getIDS();
        if(!ids){
            return;
        }
        else{
            setType(ids,t);
        }
    }

    
};

union YYSTYPE {
  char* str_val;
  int int_val;
  _ident* _ID;
  _number* _NUM;
  _var* _VAR;
  _declaration* _DECL;
  _term* _TERM;
  _terms* _TERMS;
  _multiplicative_expr* _MULT_EXPR;
  _relation_expr* _REL_EXPR;
  _expression* _EXPR;
  _expressions* _EXPRS;
  _multiplicative_exprs* _MULT_EXPRS;
  _comp* _COMP;
  _relation_exprs* _REL_EXPRS;
  _bool_expr* _BOOL_EXPR;
  _relation_and_expr* _REL_AND_EXPR;
  _relation_and_exprs* _REL_AND_EXPRS;
  _vars* _VARS;
  _identifiers* _IDS;
  _statement* _STATEMENT;
  _statements_semi* _SSS;
  _statement_semi* _SS;
  _declaration_semi* _DS;
  _declarations_semi* _DSS;
  _function* _FUNC;
  _functions* _FUNCS;
  _program* _PROGRAM;
};

class table_manager{
    private:
    vector<_symbol*>table;
    
    public:
    table_manager(){

    }
    void addSymbol(_symbol* s){
        string varName = to_string(table.size());
        
        table.push_back(s);

    }

};