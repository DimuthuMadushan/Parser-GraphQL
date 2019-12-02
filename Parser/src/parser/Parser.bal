import ballerina/io;

type Parser object {
    private
    record {} look;
    map<VariableDefinition> variableDefMap;
    map<FragmentDefinition> fragmentsDefMap;
    function __init() {
        self.look = scan();
        self.variableDefMap = {};
        self.fragmentsDefMap = {};
    }

    function document() {
        self.definition();
    }

    function definition() {
        Node root = self.executableDefinition();
    }

    function executableDefinition() returns @tainted OperationDefinition {
        match self.look.get("token") {
            "fragment" => {
                return self.fragment();
            }
            "query" => {
                return self.query();
            }
            "mutation" => {
                return self.mutation();
            }
            "subscription" => {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
            "{" => {
                string nodeType = "OperationDefintion";
                string operationType = "query";
                string? name = "";
                VariableDefinition variableDefinition = new VariableDefinition("", "", new NullValue());
                Directives? directives = ();
                SelectionSet[] selectionSet=[];
                selectionSet.push(self.selectionSet());
                self.matchToken("}");
                io:println("Parsing successful. No Syntax Errors");
                return new OperationDefinition(operationType, selectionSet, name, variableDefinition, directives);
                
            }
            _ => {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }
    }

    function fragment() returns @tainted OperationDefinition{
        string nodeType = "FragmentDefinition";
        string fragmentName;
        string typeCondition;
        Directives? directives = ();
        SelectionSet[] selectionSet=[];
        self.move();
        fragmentName = <string>self.look.get("token");
        self.matchTokenType("Name");
        self.matchToken("on");
        typeCondition = <string>self.look.get("token");
        self.matchTokenType("Name");
        if (<string>self.look.get("token") == "@") {
            directives = self.directives();
            selectionSet.push(self.selectionSet());
            self.matchToken("}");
            FragmentDefinition fd = new FragmentDefinition(fragmentName, typeCondition, directives, selectionSet);
            self.fragmentsDefMap[fragmentName] = fd;
            return self.executableDefinition();
        }else{
            selectionSet.push(self.selectionSet());
            self.matchToken("}");
            FragmentDefinition fd = new FragmentDefinition(fragmentName, typeCondition, directives, selectionSet);
            self.fragmentsDefMap[fragmentName] = fd;
            return self.executableDefinition();
        }
        
    }

    function query() returns @tainted OperationDefinition {
        string nodeType = "OperationDefintion";
        string operationType = "query";
        string? name = "";
        VariableDefinition variableDefinition = new VariableDefinition("", "", new NullValue());
        Directives? directives = ();
        SelectionSet[] selectionSet=[];
        self.move();
        string variable;
        string typeName;
        Value defaultValue;
        while (true) {
            if (self.look.get("tokenType") == "Name") {
                name = <string>self.look.get("token");
                self.move();
            }
            else if (self.isLookahead("(")) {
                self.move();
                while (self.isLookahead("$")) {
                    self.matchToken("$");
                    variable = <string>self.look.get("token");
                    self.move();
                    self.matchToken(":");
                    typeName = self.getTypeOfVar(<string>self.look.get("token"));
                    defaultValue = new NullValue();
                    if (self.isLookahead("=")) {
                        defaultValue = self.getValue(variable);
                    }
                    variableDefinition = new VariableDefinition(variable, typeName, defaultValue);
                    self.variableDefMap[variable] = variableDefinition;
                }
                self.matchToken(")");
            } else if (<string>self.look.get("token") == "@") {
                directives = self.directives();
            } else {
                break;
            }
        }
        if (self.isLookahead("{")) {
            selectionSet.push(self.selectionSet());
            self.matchToken("}");
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
        io:println("Parsing successful. No Syntax Errors");
        return new OperationDefinition(operationType, selectionSet, name, variableDefinition, directives);
        
    }

    function mutation() returns @tainted OperationDefinition{
        string nodeType = "OperationDefintion";
        string operationType = "mutation";
        string? name = "";
        VariableDefinition variableDefinition = new VariableDefinition("", "", new NullValue());
        Directives? directives = ();
        SelectionSet[] selectionSet=[];
        self.move();
        string variable;
        string typeName;
        Value defaultValue;
        while (true) {
            if (self.look.get("tokenType") == "Name") {
                name = <string>self.look.get("token");
                self.move();
            }
            else if (self.isLookahead("(")) {
                self.move();
                while (self.isLookahead("$")) {
                    self.matchToken("$");
                    variable = <string>self.look.get("token");
                    self.move();
                    self.matchToken(":");
                    typeName = self.getTypeOfVar(<string>self.look.get("token"));
                    defaultValue = new NullValue();
                    if (self.isLookahead("=")) {
                        defaultValue = self.getValue(variable);
                    }
                    variableDefinition = new VariableDefinition(variable, typeName, defaultValue);
                    self.variableDefMap[variable] = variableDefinition;
                }
                self.matchToken(")");
            } else if (self.isLookahead("@")) {
                directives = self.directives();
            } else {
                break;
            }
        }
        if (self.isLookahead("{")) {
            selectionSet.push(self.selectionSet());
            self.matchToken("}");
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
        io:println("Parsing successful. No Syntax Errors");
        return new OperationDefinition(operationType, selectionSet, name, variableDefinition, directives);  
    }

    function directives() returns Directives {
        Directives directive;
        string name;
        Arguments arguments;
        self.move();
        if (self.look.get("tokenType") == "Name") {
            name = <string>self.look.get("token");
            self.move();
            self.matchToken("(");
            string variable = <string>self.look.get("token");
            self.matchTokenType("Name");
            self.matchToken(":");
            if (self.isLookahead("$")) {
                self.move();
                if (self.variableDefMap.hasKey(<string>self.look.get("token"))) {
                    Value value = self.getValue(<string>self.look.get("token"));
                    self.move();
                    self.matchToken(")");
                    arguments = new Arguments(variable, value);
                } else {
                    string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
                    panic error("Undefined Variable", massage = msg);
                }
            } else {
                Value value = self.getValue(variable);
                self.move();
                self.matchToken(")");
                arguments = new Arguments(variable, value);
            }
            directive = new Directives(name, arguments);
            return directive;
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function selectionSet() returns @tainted (Field | FragmentSpread | InlineFragment) {
        self.move();
        if (self.look.get("tokenType") == "Name") {
            return self.field();
        } else if (self.isLookahead("...")) {
            return self.fragmentInlineAndSpread();
        } else {
            io:println(self.look.get("token"));
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function field() returns Field{
        string? alias = "";
        string name;
        string[] fields=[];
        map<Arguments> arguments={};
        Directives? directives=();
        SelectionSet[] selSet=[];
        name = <string>self.look.get("token");
        self.move();
        while (true) {
            if (self.isLookahead(":")) {
                alias = name;
                self.move();
                name = <string>self.look.get("token");
                self.move();
                fields.push(name);
            } else if (self.isLookahead("{")) {
                selSet.push(self.selectionSet());
                self.matchToken("}");
            } else if (<string>self.look.get("tokenType") == "Name") {
                fields.push(name);
                self.move();
            } else if (self.isLookahead("(")) {
                self.move();
                string variable = <string>self.look.get("token");
                while (self.look.get("tokenType") == "Name") {
                    self.matchTokenType("Name");
                    self.matchToken(":");
                    if(self.isLookahead("[")){
                        self.move();
                        while(<string>self.look.get("tokenType") == "Name" || self.isLookahead("$")){
                            if (self.isLookahead("$")) {
                                self.move();
                                variable = <string>self.look.get("token");
                                if (self.variableDefMap.hasKey(<string>self.look.get("token"))) {
                                    Value value = self.getValue(<string>self.look.get("token"));
                                    self.move();
                                    arguments[variable] = new Arguments(variable, value);
                                } else {
                                    string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
                                    panic error("Undefined Variable", massage = msg);
                                }
                            }else if(<string>self.look.get("tokenType") == "Name" ) {
                                variable = <string>self.look.get("token");
                                Value value = new StringValue(variable,variable);
                                self.move();
                                arguments[variable] = new Arguments(variable, value);
                            } else{
                                break;
                            } 
                        } 
                        self.matchToken("]");
                    }else if (self.isLookahead("$")) {
                        self.move();
                        if (self.variableDefMap.hasKey(<string>self.look.get("token"))) {
                            Value value = self.getValue(<string>self.look.get("token"));
                            self.move();
                            arguments[variable] = new Arguments(variable, value);
                        } else {
                            string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
                            panic error("Undefined Variable", massage = msg);
                        }
                    } else {
                        Value value = self.getValue(variable);
                        self.move();
                        arguments[variable] = new Arguments(variable, value);
                    }
                }
                self.matchToken(")");
            } else if (self.isLookahead("@")) {
                directives = self.directives();
            } else if (self.isLookahead("{")) {
                selSet.push(self.selectionSet());
                self.matchToken("}");
            } else if (self.isLookahead("...")) {
                selSet.push(self.fragmentInlineAndSpread());
            }else {
                fields.push(name);
                break;
            }

        }
        return new Field(name, alias, arguments, selSet, fields, directives);
    }
    function fragmentInlineAndSpread() returns (InlineFragment|FragmentSpread){
        string? typeCondition="";
        Directives? directives=();
        string fragmentName;
        SelectionSet[] selSet=[];
        self.move();
        if(<string>self.look.get("tokenType")=="Identifier") {
            while(true){
                if(self.isLookahead("on")){
                    self.move();
                    typeCondition = <string>self.look.get("token");
                    self.matchTokenType("Name");
                }else if(self.isLookahead("@")){
                    directives = self.directives();
                }else{
                    break;
                }
            }
            if(<string>self.look.get("token")=="{"){
                selSet.push(self.selectionSet());
                self.matchToken("}"); 
            }else{
                string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
            return new InlineFragment(typeCondition,directives,selSet);
        }else if(<string>self.look.get("tokenType")=="Punctuation"){
            while(true){
                if(self.isLookahead("on")){
                    self.move();
                    typeCondition = <string>self.look.get("token");
                    self.matchTokenType("Name");
                }else if(self.isLookahead("@")){
                    directives = self.directives();
                }else{
                    break;
                }
            }
            self.matchToken("{");
            selSet.push(self.selectionSet());
            self.matchToken("}"); 
            return new InlineFragment(typeCondition,directives,selSet);
        }else if(<string>self.look.get("tokenType")=="Name"){
            fragmentName = <string>self.look.get("token");
            self.move();
            if (self.fragmentsDefMap.hasKey(fragmentName)) {
                if (<string>self.look.get("token") == "@") {
                    directives = self.directives();
                }
                return new FragmentSpread(fragmentName, directives);
            } else {
                string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }else{
            string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function move() {
        self.look = scan();
    }

    function matchToken(string tok) {
        if (self.look.hasKey("token")) {
            if (self.look.get("token") == tok) {
                self.move();
            } else {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        } else {
            string msg = io:sprintf("missing punctuation");
            panic error("Syntax Error", massage = msg);
        }
    }

    function matchTokenType(string tokType) {
        if (<string>self.look.get("tokenType") == tokType) {
            self.move();
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function isLookahead(string tok) returns boolean {
        if (self.look.hasKey("token")) {
            if (<string>self.look.get("token") == tok) {
                return true;
            } else {
                return false;
            }
        } else {
            string msg = io:sprintf("missing punctuation");
            panic error("Syntax Error", massage = msg);
        }
    }

    function getTypeOfVar(string tok) returns string {
        if (self.isLookahead("[")) {
            self.move();
            self.matchTokenType("Name");
            self.matchToken("]");
            if (self.isLookahead("!")) {
                return "NonNullListType";
            } else {
                return "ListType";
            }
        } else if (self.look.get("tokenType") == "Name") {
            self.move();
            if (self.isLookahead("!")) {
                self.move();
                return "NonNullNamedType";
            } else {
                return "NamedType";
            }
        } else if (self.look.get("tokenType") == "Identifier") {
            self.move();
            if (self.isLookahead("!")) {
                self.move();
                return "NonNullNamedType";
            } else {
                return "NamedType";
            }
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function getValue(string name) returns Value {
        match self.look.get("tokenType") {
            "Int" => {
                return new IntValue(name, <string>self.look.get("token"));
            }
            "String" => {
                return new StringValue(name, <string>self.look.get("token"));
            }
            "float" => {
                return new FloatValue(name, <string>self.look.get("token"));
            }
            "boolean" => {
                return new BooleanValue(name, <string>self.look.get("token"));
            }
            "Name" => {
                string Type = self.variableDefMap.get(<string>self.look.get("token")).typeName;
                return new UserInputValue(name, Type);
            }
            _ => {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.look.get("lineNum"), self.look.get("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }

    }
    
};




