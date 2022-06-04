#pragma once

#include <iostream>
#include <string>
#include <cstring>
#include <vector>
#include <sstream>
#include <map>
#include <stack>
#include <set>
#include <fstream>

using namespace std;



class node{
    private:
    string name, op;

    public:
    node(string name, string op){
        this->name = name;
        this->op = op;
    }
    string getName(){
        return name;
    }
    string getOp(){
        return op;
    }
};

class symbol{

    private:
    string code, name, op, size,index;
    vector<string> names;
    vector<node> nodes;
    bool isContinue;

    public:
    symbol(){
        code = name = op = size = index = "";

    }
    symbol(string n, string c){
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_") -1;
        if(space_index != -1){
            name = n.substr(0,space_index);
        }
        else{
            name = n;
        }
 
        code = c;
        op = "";
        size = "";
        index = "";
    }
    string getCode(){
        return code;
    }
    string getName(){
        return name;
    }
    string getOp(){
        return op;
    }
    string getSize(){
        return size;
    }
    string getIndex(){
        return index;
    }


    void setCode(string c){
        code = c;
    }
    void setName(string n){
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_") -1;
        if(space_index != -1){
            name = n.substr(0,space_index);
        }
        else{
            name = n;
        }
    }
    void setOp(string o){
        op = o;
    }
    void addName(string n){
        int space_index = n.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_") -1;

        if(space_index != -1){
            n = n.substr(0,space_index);
        }
        else{
            n = n;
        }
        names.push_back(n);
    }
    vector<string> getNames(){
        return names;
    }
    void addNames(vector<string> n){
        names.insert(names.end(),n.begin(),n.end());
    }
    void setNames(vector<string> n){
        names = n;
    }
    void setSize(string s){
        size = s;
    }
    void setIndex(string i){
        index = i;
    }
    void addNode(string n, string o){

        nodes.push_back(node(n,o));
    }
    vector<node> getNodes(){
        return nodes;
    }
    void addNodes(vector<node> n){
        nodes.insert(nodes.end(),n.begin(),n.end());
    }
};

class TableManager{

    //type for normal id is 0, array has size > 0, enum is -2. -1 is error
    private:

    const set<string> reserved_words = {"function", "beginparams", "endparams", "beginlocals", "endlocals", "beginbody", "endbody", "integer", "array", "enum", "of", "if", "then", "endif", "else", "for", "while", "do", "beginloop", "endloop", "continue", "read", "write", "and", "or", "not", "true", "false", "return", "_L", "_C"};
    map<string,int> table;
    set<string> functions;
    stack< map<string,int> > table_stack;
    int label_count;
    map<string, vector<string> > params;



    public:
    TableManager(){
        label_count = 0;
    }
    void push(){
        table_stack.push(table);
    }
    void pop(){
        table = table_stack.top();
        table_stack.pop();
    }
    bool check(string name){
        if(table.find(name) != table.end()){
            return true;
        }
        return false;
    }
    bool checkReserve(string name){
        return reserved_words.find(name) != reserved_words.end();
    }

    //return 1 if add was successful, 0 if it is a reserved word, -1 if it already exists
    int add(string name, int size){
        if(!check(name)){
            table[name] = size;
            return 1;
        }
        else if(checkReserve(name)){
            return 0;
        }
        else return -1;
    }

    string getTemp(){
        string temp =  "__temp__" + to_string(table.size());

        add(temp, 0);
        return temp;
    }

    string getLabel(){
        label_count++;
        string label = "label" + to_string(label_count);

        return label;
    }

    string getLastLabel(){
        return "label" + to_string(label_count);
    }

    int checkType(string name){
        if(check(name)){
            return table[name];
        }
        else{
            return -1;
        }
    }
    void addFunction(string name){
        functions.insert(name);
    }
    bool checkFunction(string name){
        if(functions.find(name) != functions.end()){
            return true;
        }
        return false;
    }
    void addFunc(string name){
        vector<string>* temp = new vector<string>();
        params[name] = *temp;
    }

    void addParam(string func_name, string param_name){
        if(!checkFunction(func_name)){
            addFunc(func_name);
        }
        params[func_name].push_back(param_name);
    }
    vector<string> getParams(string func_name){
        return params[func_name];
    }


};


union YYSTYPE {
   char* str_val;
   symbol* sym_val;

};