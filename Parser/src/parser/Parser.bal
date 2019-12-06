import ballerina/io;

type Parser object {
    private
    record {} look;
    record {} previousToken;
    map<VariableDefinition> variableDefMap;
    map<FragmentDefinition> fragmentsDefMap;
    function __init() {
        self.look = scan();
        self.variableDefMap = {};
        self.fragmentsDefMap = {};
        self.previousToken = self.look;
    }

    function getLineNumber() returns [int, int] {
        [int, int] location = [<int>self.getToken("lineNum"), <int>self.getToken("columnNum")];
        int lineNumber;
        int columnNumber;
        [lineNumber, columnNumber] = location;
        return [lineNumber, columnNumber];
    }

    function document() {
        self.definition();
    }

    function definition() {
        Node root = self.executableDefinition();
    }

    function executableDefinition() returns @tainted OperationDefinition {
        match self.getToken("token") {
            "fragment" => {
                return self.fragment();
            }
            "query" => {
                return self.getOperation("query");
            }
            "mutation" => {
                return self.getOperation("mutation");
            }
            "subscription" => {
                return self.getOperation("subscription");
            }
            "{" => {
                string nodeType = "OperationDefintion";
                string operationType = "query";
                string? name = "";
                VariableDefinition variableDefinition = new VariableDefinition("", "", new NullValue());
                Directives? directives = ();
                SelectionSet[] selectionSet = [];
                selectionSet = self.selectionSet();
                if (!self.look.hasKey("token")) {
                    io:println("Parsing successful. No Syntax Errors");
                    return new OperationDefinition(operationType, selectionSet, name, variableDefinition, directives);
                } else {
                    string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                    panic error("Syntax Error", massage = msg);
                }
            }
            _ => {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }
    }

    function fragment() returns @tainted OperationDefinition {
        string nodeType = "FragmentDefinition";
        string fragmentName;
        string typeCondition;
        Directives? directives = ();
        SelectionSet[] selectionSet = [];
        self.move();
        fragmentName = <string>self.getToken("token");
        self.matchTokenType("Name");
        self.matchToken("on");
        typeCondition = <string>self.getToken("token");
        self.matchTokenType("Name");
        if (<string>self.getToken("token") == "@") {
            directives = self.directives();
            selectionSet = self.selectionSet();
            FragmentDefinition fd = new FragmentDefinition(fragmentName, typeCondition, directives, selectionSet);
            self.fragmentsDefMap[fragmentName] = fd;
            return self.executableDefinition();
        } else {
            selectionSet = self.selectionSet();
            FragmentDefinition fd = new FragmentDefinition(fragmentName, typeCondition, directives, selectionSet);
            self.fragmentsDefMap[fragmentName] = fd;
            return self.executableDefinition();
        }

    }

    function getOperation(string opType) returns @tainted OperationDefinition {
        string nodeType = "OperationDefintion";
        string operationType = opType;
        string? name = "";
        VariableDefinition variableDefinition = new VariableDefinition("", "", new NullValue());
        Directives? directives = ();
        SelectionSet[] selectionSet = [];
        self.move();
        string variable;
        string typeName;
        Value defaultValue;
        if (self.getToken("tokenType") == "Name") {
            name = <string>self.getToken("token");
            self.move();
        }
        if (self.isLookahead("(")) {
            self.move();
            while (self.isLookahead("$")) {
                self.matchToken("$");
                variable = <string>self.getToken("token");
                self.move();
                self.matchToken(":");
                typeName = self.getTypeOfVar(<string>self.getToken("token"));
                defaultValue = new NullValue();
                if (self.isLookahead("=")) {
                    defaultValue = self.getValue(variable);
                }
                variableDefinition = new VariableDefinition(variable, typeName, defaultValue);
                self.variableDefMap[variable] = variableDefinition;
            }
            self.matchToken(")");
        }
        if (<string>self.getToken("token") == "@") {
            directives = self.directives();
        }
        if (self.isLookahead("{")) {
            selectionSet = self.selectionSet();
        }
        else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
        if (!self.look.hasKey("token")) {
            io:println("Parsing successful. No Syntax Errors");
            return new OperationDefinition(operationType, selectionSet, name, variableDefinition, directives);
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function directives() returns Directives {
        Directives directive;
        string name;
        Arguments arguments;
        self.move();
        if (self.getToken("tokenType") == "Name") {
            name = <string>self.getToken("token");
            self.move();
            self.matchToken("(");
            string variable = <string>self.getToken("token");
            self.matchTokenType("Name");
            self.matchToken(":");
            if (self.isLookahead("$")) {
                self.move();
                if (self.variableDefMap.hasKey(<string>self.getToken("token"))) {
                    Value value = self.getValue(<string>self.getToken("token"));
                    self.move();
                    self.matchToken(")");
                    arguments = new Arguments(variable, value);
                } else {
                    string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
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
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function selectionSet() returns @tainted SelectionSet[] {
        SelectionSet[] selSet = [];
        int i = 0;
        self.move();
        while (true) {
            i += 1;
            if (self.getToken("tokenType") == "Name") {
                selSet.push(self.field());
            } else if (self.isLookahead("...")) {
                selSet.push(self.fragmentInlineAndSpread());
            } else if (self.isLookahead("}") && (i != 1)) {
                self.move();
                break;
            } else {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }
        return selSet;
    }

    function field() returns @tainted Field {
        string? alias = "";
        string name;
        string[] fields = [];
        map<Arguments> arguments = {};
        Directives? directives = ();
        SelectionSet[] selSet = [];
        name = <string>self.getToken("token");
        Value defaultValue;
        if (self.getToken("tokenType") == "Name") {
            name = <string>self.getToken("token");
            self.move();
            if (self.isLookahead(":")) {
                alias = name;
                self.move();
                name = <string>self.getToken("token");
                self.move();
            }
            fields.push(name);
        }
        if (self.isLookahead("(")) {
            self.move();
            if (self.getToken("tokenType") == "Name") {
                string variable = <string>self.getToken("token");
                while (self.getToken("tokenType") == "Name") {
                    self.matchTokenType("Name");
                    self.matchToken(":");
                    if (self.isLookahead("[")) {
                        self.move();
                        while (<string>self.getToken("tokenType") == "Name" || self.isLookahead("$")) {
                            if (self.isLookahead("$")) {
                                self.move();
                                variable = <string>self.getToken("token");
                                if (self.variableDefMap.hasKey(<string>self.getToken("token"))) {
                                    Value value = self.getValue(<string>self.getToken("token"));
                                    self.move();
                                    arguments[variable] = new Arguments(variable, value);
                                } else {
                                    string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
                                    panic error("Undefined Variable", massage = msg);
                                }
                            } else if (<string>self.getToken("tokenType") == "Name") {
                                variable = <string>self.getToken("token");
                                Value value = new StringValue(variable, variable);
                                self.move();
                                arguments[variable] = new Arguments(variable, value);
                            } else {
                                break;
                            }
                        }
                        self.matchToken("]");
                    } else if (self.isLookahead("$")) {
                        self.move();
                        if (self.variableDefMap.hasKey(<string>self.getToken("token"))) {
                            Value value = self.getValue(<string>self.getToken("token"));
                            self.move();
                            arguments[variable] = new Arguments(variable, value);
                        } else {
                            string msg = io:sprintf("%s near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
                            panic error("Undefined Variable", massage = msg);
                        }
                    } else {
                        Value value = self.getValue(variable);
                        self.move();
                        arguments[variable] = new Arguments(variable, value);
                    }
                }
                self.matchToken(")");
            }
        }
        if (self.isLookahead("@")) {
            directives = self.directives();
        }
        if (self.isLookahead("{")) {
            selSet = self.selectionSet();
        }
        return new Field(name, alias, arguments, selSet, fields, directives);
    }

    function fragmentInlineAndSpread() returns @tainted (InlineFragment | FragmentSpread) {
        string? typeCondition = "";
        Directives? directives = ();
        string fragmentName;
        SelectionSet[] selSet = [];
        self.move();
        if (<string>self.getToken("tokenType") == "Identifier") {
            while (true) {
                if (self.isLookahead("on")) {
                    self.move();
                    typeCondition = <string>self.getToken("token");
                    self.matchTokenType("Name");
                } else if (self.isLookahead("@")) {
                    directives = self.directives();
                } else {
                    break;
                }
            }
            if (<string>self.getToken("token") == "{") {
                selSet = self.selectionSet();
            } else {
                string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
            return new InlineFragment(typeCondition, directives, selSet);
        } else if (<string>self.getToken("tokenType") == "Punctuation") {
            while (true) {
                if (self.isLookahead("on")) {
                    self.move();
                    typeCondition = <string>self.getToken("token");
                    self.matchTokenType("Name");
                } else if (self.isLookahead("@")) {
                    directives = self.directives();
                } else {
                    break;
                }
            }
            self.matchToken("{");
            selSet = self.selectionSet();
            return new InlineFragment(typeCondition, directives, selSet);
        } else if (<string>self.getToken("tokenType") == "Name") {
            fragmentName = <string>self.getToken("token");
            self.move();
            if (self.fragmentsDefMap.hasKey(fragmentName)) {
                if (<string>self.getToken("token") == "@") {
                    directives = self.directives();
                }
                return new FragmentSpread(fragmentName, directives);
            } else {
                string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        } else {
            string msg = io:sprintf("%s found near line %d,%d", "Undefined Variable", self.getToken("lineNum"), self.getToken("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function move() {
        self.previousToken = self.look;
        self.look = scan();
    }

    function getToken(string field) returns anydata {
        if (self.look.hasKey(field)) {
            return self.look.get(field);
        } else {
            string msg = io:sprintf("%s near line %d %d", "syntax error", self.previousToken.get("lineNum"), self.previousToken.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    // function getToken("tokenType") returns string {
    //     if (self.look.hasKey("token")) {
    //         return <string>self.getToken("tokenType");
    //     } else {
    //         string msg = io:sprintf("%s near line %d %d", "syntax error", self.previousToken.get("lineNum"), self.previousToken.get("columnNum"));
    //         panic error("Syntax Error", massage = msg);
    //     }
    // }

    function matchToken(string tok) {
        if (self.look.hasKey("token")) {
            if (self.getToken("token") == tok) {
                self.move();
            } else {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        } else {
            string msg = io:sprintf("%s near line %d %d", "syntax error", self.previousToken.get("lineNum"), self.previousToken.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function matchTokenType(string tokType) {
        if (self.look.hasKey("tokenType")) {
            if (<string>self.getToken("tokenType") == tokType) {
                self.move();
            } else {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        } else {
            string msg = io:sprintf("%s near line %d %d", "syntax error", self.previousToken.get("lineNum"), self.previousToken.get("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function isLookahead(string tok) returns boolean {
        if (self.look.hasKey("token")) {
            if (<string>self.getToken("token") == tok) {
                return true;
            } else {
                return false;
            }
        } else {
            string msg = io:sprintf("%s near line %d %d", "syntax error", self.previousToken.get("lineNum"), self.previousToken.get("columnNum"));
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
        } else if (self.getToken("tokenType") == "Name") {
            self.move();
            if (self.isLookahead("!")) {
                self.move();
                return "NonNullNamedType";
            } else {
                return "NamedType";
            }
        } else if (self.getToken("tokenType") == "Identifier") {
            self.move();
            if (self.isLookahead("!")) {
                self.move();
                return "NonNullNamedType";
            } else {
                return "NamedType";
            }
        } else {
            string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
            panic error("Syntax Error", massage = msg);
        }
    }

    function getValue(string name) returns Value {
        match self.getToken("tokenType") {
            "Int" => {
                return new IntValue(name, <string>self.getToken("token"));
            }
            "String" => {
                return new StringValue(name, <string>self.getToken("token"));
            }
            "float" => {
                return new FloatValue(name, <string>self.getToken("token"));
            }
            "boolean" => {
                return new BooleanValue(name, <string>self.getToken("token"));
            }
            "Name" => {
                string Type = self.variableDefMap.get(<string>self.getToken("token")).typeName;
                return new EnumValue(name, Type);
            }
            _ => {
                string msg = io:sprintf("%s near line %d,%d", "syntax error", self.getToken("lineNum"), self.getToken("columnNum"));
                panic error("Syntax Error", massage = msg);
            }
        }
    }
};
