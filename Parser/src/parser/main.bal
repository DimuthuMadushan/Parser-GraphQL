public function main() {
    string selectionSet = "{
                            me {
                                    id
                                    firstName
                                    lastName
                                    birthday {
                                    month
                                    day
                                }
                                friends {
                                name
                                }
                            
                            }";

    string inlinefragment = "query inlineFragmentTyping {
                                            profiles(handles: [zuck, cocacola]) {
                                                handle
                                                ... on User {
                                                friends {
                                                    count
                                                }
                                                }
                                                ... on Page {
                                                likers {
                                                    count
                                                }
                                                }
                                            }
                                            }";

    string fragmentSpread = "fragment friendFields on User {
                            id
                            name
                            profilePic(size: 50)
                        }
                        query withFragments {
                            user(id: 4) {
                                friends(first: 10) {
                                ...friendFields
                                }
                                mutualFriends(first: 10) {
                                ...friendFields
                                }
                            }
                        }
                        ";
    table<Token> | string t = getTokens(inlinefragment);

    Parser parser = new Parser();
    parser.document();
}
