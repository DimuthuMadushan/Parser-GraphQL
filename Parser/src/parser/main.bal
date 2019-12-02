//import ballerina/io;

public function main() {
//     table<Token> | string t = getTokens("fragment friendFields on User {
//   id
//   name
//   profilePic(size: 50)
// }query withFragments {
//   user(id: 4) {
//     friends(first: 10) {
//       ...friendFields
//     }
//     mutualFriends(first: 10) {
//       ...friendFields
//     }
//   }
// }
//                                         "
//     );

     table<Token> | string t = getTokens("query inlineFragmentTyping {
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
                                            }"
    );

    Parser parser = new Parser();
    parser.document();
    // record {} tk = scan();
    // io:println(tk.get("token"));
    // io:println(scan());
    // io:println(scan());
}
