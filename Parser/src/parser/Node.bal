type Node abstract object {
};

type Document object {
    // Node definition;
    // function __init(Node def) {
    //     self.definition = def;
    // }
};
type FragmentDefinition object {
    string nodeType = "FragmentDefinition";
    string fragmentName;
    string typeCondition;
    Directives? directives;
    SelectionSet[] selectionSet;
    function __init(string name, string typeCon, Directives? dir, SelectionSet[] selSet) {
        self.fragmentName = name;
        self.typeCondition = typeCon;
        self.directives = dir;
        self.selectionSet = selSet;
    }

    function getNodeType() returns string {
        return self.nodeType;
    }
};

type OperationDefinition object {
    string nodeType = "OperationDefintion";
    string? operationType;
    string? name;
    VariableDefinition? variableDefinition;
    Directives? directives = ();
    SelectionSet[] selectionSet;
    //anydata lexline;
    function __init(string opType, SelectionSet[] selSet, string? name, VariableDefinition? varDef,Directives? dir) {
        self.operationType = opType;
        self.name = name;
        self.variableDefinition = varDef;
        self.directives = dir;
        self.selectionSet = selSet;
    }
    function getNodeType() returns string {
        return self.nodeType;
    }
};

type SelectionSet object {
    string nodeType = "Selection";
};

type Field object {
    string nodeType = "Selection";
    string? alias = "";
    string name;
    string[]? fields;
    map<Arguments>? argument;
    Directives? directives;
    SelectionSet[]? selectionSet;
    function __init(string name, string? als, map<Arguments>? args, SelectionSet[]? selSet, string[]? fields,Directives? dir) {
        self.alias = als;
        self.name = name;
        self.argument = args;
        self.directives = dir;
        self.selectionSet = selSet;
        self.fields = fields;
    }
};

type FragmentSpread object {
    string nodeType = "Selection";
    string fragmentName;
    Directives? directives;
    function __init(string name, Directives? dir) {
        self.fragmentName = name;
        self.directives = dir;
    }
};

type InlineFragment object {
    string nodeType = "Selection";
    string? typeCondition;
    Directives? directives;
    SelectionSet[] selectionSet;
    function __init(string? typeCon, Directives? dir, SelectionSet[] selSet) {
        self.typeCondition = typeCon;
        self.directives = dir;
        self.selectionSet = selSet;
    }
};
type Directives object {
    string name;
    Arguments arguments;
    function __init(string name, Arguments args) {
        self.name = name;
        self.arguments = args;
    }
};

type VariableDefinition object {
    string variable;
    string typeName;
    Value? defaultValue;
    function __init(string variable, string tp, Value val) {
        self.variable = variable;
        self.typeName = tp;
        self.defaultValue = val;
    }
};

type Arguments object {
    string name;
    Value value;
    function __init(string name, Value val) {
        self.name = name;
        self.value = val;
    }
};

type Value object {
    any value;
    string name;
    function __init(string name, any val) {
        self.name = name;
        self.value = val;
    }
};

type Variable object {
    string name;
    function __init(string name) {
        self.name = name;
    }
};

type IntValue object {
    string value;
    string name;
    function __init(string name, string val) {
        self.name = name;
        self.value = val;
    }
};
type FloatValue object {
    string value;
    string name;
    function __init(string name, string val) {
        self.name = name;
        self.value = val;
    }
};
type StringValue object {
    string value;
    string name;
    function __init(string name, string val) {
        self.name = name;
        self.value = val;
    }
};
type BooleanValue object {
    string value;
    string name;
    function __init(string name, string val) {
        self.name = name;
        self.value = val;
    }
};
type EnumValue object {
    string name;
    any value;
    function __init(string name, any val) {
        self.name = name;
        self.value = val;
    }
};
type NullValue object {
    any value;
    string name;
    function __init() {
        self.name = "";
        self.value = "";
    }
};
type UserInputValue object{
    string Type;
    string name;
    any value="";
     function __init(string name,string tp) {
        self.name = name;
        self.Type = tp;
    }
};
type ListValue object {

};
type ObjectValue object {

};



